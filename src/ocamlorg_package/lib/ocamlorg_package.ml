module Import = Import
open Import
module Name = OpamPackage.Name
module Version = OpamPackage.Version
module Info = Info
module Statistics = Packages_stats

type t = { name : Name.t; version : Version.t; info : Info.t }

let name t = t.name
let version t = t.version
let info t = t.info
let create ~name ~version info = { name; version; info }

type state = {
  version : string;
  mutable opam_repository_commit : string option;
  mutable packages : Info.t Version.Map.t Name.Map.t;
  mutable stats : Statistics.t option;
}

let mockup_state (pkgs : t list) =
  let map = Name.Map.empty in
  let add_version (pkg : t) map =
    let new_map =
      match Name.Map.find_opt pkg.name map with
      | None -> Version.Map.(add pkg.version pkg.info empty)
      | Some version_map -> Version.Map.add pkg.version pkg.info version_map
    in
    Name.Map.add pkg.name new_map map
  in
  let packages = List.fold_left (fun map v -> add_version v map) map pkgs in
  {
    version = Info.version;
    packages;
    opam_repository_commit = None;
    stats = None;
  }

let read_versions package_name versions =
  let open Lwt.Syntax in
  Lwt_list.fold_left_s
    (fun acc package_version ->
      match OpamPackage.of_string_opt package_version with
      | Some pkg -> (
          let+ opam_opt =
            Opam_repository.opam_file package_name package_version
          in
          match opam_opt with
          | Some opam -> Version.Map.add pkg.version opam acc
          | None ->
              Logs.err (fun m ->
                  m "Failed to read opam file for %S %s" package_name
                    package_version);
              acc)
      | None ->
          Logs.err (fun m -> m "Invalid pacakge version %S" package_name);
          Lwt.return acc)
    Version.Map.empty versions

let read_packages () =
  let open Lwt.Syntax in
  Lwt_list.fold_left_s
    (fun acc (package_name, versions) ->
      match Name.of_string package_name with
      | exception ex ->
          Logs.err (fun m ->
              m "Invalid package name %S: %s" package_name
                (Printexc.to_string ex));
          Lwt.return acc
      | _name ->
          let+ versions = read_versions package_name versions in
          Name.Map.add (Name.of_string package_name) versions acc)
    Name.Map.empty
    (Opam_repository.list_packages_and_versions ())

let try_load_state () =
  let exception Invalid_version in
  let state_path = Config.package_state_path in
  Logs.info (fun m -> m "State cache file: %s" (Fpath.to_string state_path));
  try
    let channel = open_in (Fpath.to_string state_path) in
    Fun.protect
      (fun () ->
        let v = (Marshal.from_channel channel : state) in
        if Info.version <> v.version then raise Invalid_version;
        Logs.info (fun f ->
            f "Package state loaded (%d packages, opam commit %s)"
              (Name.Map.cardinal v.packages)
              (Option.value ~default:"" v.opam_repository_commit));
        v)
      ~finally:(fun () -> close_in channel)
  with Failure _ | Sys_error _ | Invalid_version | End_of_file ->
    Logs.info (fun f -> f "Package state starting from scratch");
    {
      opam_repository_commit = None;
      version = Info.version;
      packages = Name.Map.empty;
      stats = None;
    }

let save_state t =
  Logs.info (fun f -> f "Package state saved");
  let state_path = Config.package_state_path in
  let channel = open_out_bin (Fpath.to_string state_path) in
  Fun.protect
    (fun () -> Marshal.to_channel channel t [])
    ~finally:(fun () -> close_out channel)

let get_latest' packages name =
  Name.Map.find_opt name packages
  |> Option.map (fun versions ->
         let avoid_version _ (info : Info.t) =
           List.exists (( = ) OpamTypes.Pkgflag_AvoidVersion) info.flags
         in
         let avoided, packages = Version.Map.partition avoid_version versions in
         let version, info =
           match Version.Map.max_binding_opt packages with
           | None -> Version.Map.max_binding avoided
           | Some (version, info) -> (version, info)
         in
         { version; info; name })

module SearchDocument = struct
  open Ppx_yojson_conv_lib.Yojson_conv

  type package_document = {
    name : string;
    tags : string list;
    authors: string list;
    description : string;
  }
  [@@deriving yojson_of]
end

let index_packages (packages : Info.t Version.Map.t OpamTypes.name_map) :
    unit Lwt.t =
  let env_with_default k v = Sys.getenv_opt k |> Option.value ~default:v in

  let typesense_config =
    let url =
      env_with_default "OCAMLORG_TYPESENSE_URL" "http://localhost:8108"
    in
    let api_key =
      env_with_default "OCAMLORG_TYPESENSE_API_KEY"
        "{OCAMLORG_TYPESENSE_API_KEY is missing}"
    in
    Typesense.Api.{ url; api_key }
  in
  let typesense_schema =
    Typesense.Api.Schema.(
      schema "packages"
        [
          create_field "name" String;
          create_field "tags" StringArray ~facet:true;
          create_field "authors" StringArray ~facet:true;
          create_field "description" String;
          create_field "embedding" FloatArray
            ~embed:
              {
                from = [ "tags"; "description" ];
                model_config =
                  {
                    model_name = "ts/e5-small";
                    api_key = "";
                    project_id = "";
                    indexing_prefix = "";
                    query_prefix = "";
                    access_token = "";
                    refresh_token = "";
                    client_id = "";
                    client_secret = "";
                  };
              };
        ])
  in
  let open Lwt.Syntax in
  let make_cohttp_lwt_request req =
    let* response =
      match req with
      | Typesense.Api.RequestDescriptor.Get { host; path; headers; params } ->
          Typesense_cohttp_lwt_unix.get ~headers ~params ~host path
      | Post { host; path; headers; params; body } ->
          Typesense_cohttp_lwt_unix.post ~headers ~params ~host ~body path
      | Delete { host; path; headers; params } ->
          Typesense_cohttp_lwt_unix.delete ~headers ~params ~host path
      | Patch { host; path; headers; params; body } ->
          Typesense_cohttp_lwt_unix.patch ~headers ~params ~host ~body path
      | Put { host; path; headers; params; body } ->
          Typesense_cohttp_lwt_unix.put ~headers ~params ~host ~body path
    in
    Lwt.return response
    (*|> Result.map (fun (`Success s) -> s |> Yojson.Safe.from_string)*)
  in
  let print_lwt_req ~make_request title r =
    let* () = Lwt_io.printl title in
    let* () = Lwt_io.printl @@ Typesense.Api.RequestDescriptor.show_request r in
    let* () = Lwt_io.printl "" in
    let* response = make_request r in
    match response with
    | Ok (`Success response) -> Lwt.return (print_endline response)
    | Error (`Msg m) -> Lwt.return (print_endline m)
  in
  let print_req = print_lwt_req ~make_request:make_cohttp_lwt_request in
  let transform_package ((name, version_map) : Name.t * Info.t Version.Map.t) =
    let _version, info = Version.Map.max_binding version_map in
    SearchDocument.
      {
        name = OpamPackage.Name.to_string name;
        tags = info.tags;
        authors = info.authors;
        description = info.description;
      }
  in
  let documents =
    packages |> OpamPackage.Name.Map.to_seq |> Seq.map transform_package
    |> List.of_seq
  in
  let open Lwt.Syntax in
  let* () =
    print_req "Deleting search documents collection"
      (Typesense.Api.Collection.delete ~config:typesense_config "packages")
  in
  let* () =
    print_req "Creating search documents collection"
      (Typesense.Api.Collection.create ~config:typesense_config typesense_schema)
  in
  let* () =
    print_req "Indexing search documents"
      (Typesense.Api.Document.import ~config:typesense_config
         ~action:Typesense.Api.Document.DocumentWriteParameters.Upsert
         ~collection_name:"packages"
         (List.map SearchDocument.yojson_of_package_document documents))
  in
  Lwt.return ()

let update ~commit t =
  let open Lwt.Syntax in
  Logs.info (fun m -> m "Opam repository is currently at %s" commit);
  t.opam_repository_commit <- Some commit;
  Logs.info (fun m -> m "Updating opam package list");
  Logs.info (fun f -> f "Calculating packages.. .");
  let* packages = read_packages () in
  Logs.info (fun f -> f "Computing additional informations...");
  let* packages = Info.of_opamfiles packages in
  Logs.info (fun f -> f "Indexing package info into search server...");
  let* () = index_packages packages in
  Logs.info (fun f -> f "Computing packages statistics...");
  let+ stats = Statistics.compute packages in
  t.packages <- packages;
  t.stats <- Some stats;
  Logs.info (fun m -> m "Loaded %d packages" (Name.Map.cardinal packages))

let maybe_update t commit =
  let open Lwt.Syntax in
  match t.opam_repository_commit with
  | Some v when v = commit -> Lwt.return ()
  | _ ->
      Logs.info (fun m -> m "Update server state");
      let+ () = update ~commit t in
      save_state t

let rec poll_for_opam_packages ~polling v =
  let open Lwt.Syntax in
  let* () = Lwt_unix.sleep (float_of_int polling) in
  let* () =
    Lwt.catch
      (fun () ->
        Logs.info (fun m -> m "Opam repo: git pull");
        let* commit = Opam_repository.pull () in
        maybe_update v commit)
      (fun exn ->
        Logs.err (fun m ->
            m "Failed to update the opam package list: %s"
              (Printexc.to_string exn));
        Lwt.return ())
  in
  poll_for_opam_packages ~polling v

let init ?(disable_polling = false) () =
  let open Lwt.Syntax in
  let state = try_load_state () in
  Lwt.async (fun () ->
      let* commit = Opam_repository.(if exists () then pull else clone) () in
      let* () = maybe_update state commit in
      if disable_polling then Lwt.return_unit
      else poll_for_opam_packages ~polling:Config.opam_polling state);
  state

let all_latest t =
  t.packages
  |> Name.Map.map Version.Map.max_binding
  |> Name.Map.bindings
  |> List.map (fun (name, (version, info)) -> { name; version; info })

let stats t = t.stats

let get_by_name t name =
  t.packages |> Name.Map.find_opt name
  |> Option.map Version.Map.bindings
  |> Option.map (List.map (fun (version, info) -> { name; version; info }))

let get_versions t name =
  t.packages |> Name.Map.find_opt name
  |> Option.map (fun p -> p |> Version.Map.bindings |> List.rev_map fst)

let get_latest t name = get_latest' t.packages name

let get t name version =
  t.packages |> Name.Map.find_opt name |> fun x ->
  Option.bind x (Version.Map.find_opt version)
  |> Option.map (fun info -> { version; info; name })

module Documentation = struct
  type toc = { title : string; href : string; children : toc list }

  type breadcrumb_kind =
    | Page
    | LeafPage
    | Module
    | ModuleType
    | Parameter of int
    | Class
    | ClassType
    | File

  let breadcrumb_kind_from_string s =
    match s with
    | "page" -> Page
    | "leaf-page" -> LeafPage
    | "module" -> Module
    | "module-type" -> ModuleType
    | "class" -> Class
    | "class-type" -> ClassType
    | "file" -> File
    | _ ->
        if String.starts_with ~prefix:"argument-" s then
          let i = List.hd (List.tl (String.split_on_char '-' s)) in
          Parameter (int_of_string i)
        else raise (Invalid_argument ("kind not recognized: " ^ s))

  type breadcrumb = { name : string; href : string; kind : breadcrumb_kind }

  type t = {
    uses_katex : bool;
    toc : toc list;
    breadcrumbs : breadcrumb list;
    content : string;
  }

  let rec toc_of_json = function
    | `Assoc
        [
          ("title", `String title);
          ("href", `String href);
          ("children", `List children);
        ] ->
        { title; href; children = List.map toc_of_json children }
    | _ -> raise (Invalid_argument "malformed toc field")

  let breadcrumb_from_json = function
    | `Assoc
        [
          ("name", `String name); ("href", `String href); ("kind", `String kind);
        ] ->
        { name; href; kind = breadcrumb_kind_from_string kind }
    | _ -> raise (Invalid_argument "malformed breadcrumb field")

  let doc_from_string s =
    match Yojson.Safe.from_string s with
    | `Assoc
        [
          ("uses_katex", `Bool uses_katex);
          ("breadcrumbs", `List json_breadcrumbs);
          ("toc", `List json_toc);
          ("preamble", `String preamble);
          ("content", `String content);
        ] ->
        let breadcrumbs =
          match List.map breadcrumb_from_json json_breadcrumbs with
          | _ :: _ :: _ :: _ :: breadcrumbs -> breadcrumbs
          | _ -> failwith "Not enough breadcrumbs"
        in
        {
          uses_katex;
          breadcrumbs;
          toc = List.map toc_of_json json_toc;
          content = preamble ^ content;
        }
    | _ -> raise (Invalid_argument "malformed .html.json file")
end

module Package_info = Package_info

let package_url ~kind name version =
  match kind with
  | `Package -> Config.documentation_url ^ "p/" ^ name ^ "/" ^ version ^ "/"
  | `Universe s ->
      Config.documentation_url ^ "u/" ^ s ^ "/" ^ name ^ "/" ^ version ^ "/"

let http_get url =
  let open Lwt.Syntax in
  Logs.info (fun m -> m "GET %s" url);
  let headers =
    Cohttp.Header.of_list
      [
        ( "Accept",
          "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" );
      ]
  in
  let* response, body =
    Cohttp_lwt_unix.Client.get ~headers (Uri.of_string url)
  in
  match Cohttp.Code.(code_of_status response.status |> is_success) with
  | true ->
      let+ body = Cohttp_lwt.Body.to_string body in
      Ok body
  | false ->
      let+ () = Cohttp_lwt.Body.drain_body body in
      Error (`Msg "Failed to fetch the documentation page")

let module_map ~kind t =
  let package_url =
    package_url ~kind (Name.to_string t.name) (Version.to_string t.version)
  in
  let open Lwt.Syntax in
  let url = package_url ^ "package.json" in
  let+ content = http_get url in
  match content with
  | Ok v ->
      let json = Yojson.Safe.from_string v in
      Package_info.of_yojson json
  | Error _ ->
      Logs.info (fun m -> m "Failed to fetch module map at %s" url);
      { Package_info.libraries = String.Map.empty }

let odoc_page ~url =
  let open Lwt.Syntax in
  let* content = http_get url in
  match content with
  | Ok content ->
      let maybe_doc =
        try Some (Documentation.doc_from_string content)
        with Invalid_argument err ->
          Logs.err (fun m -> m "Invalid documentation page: %s" err);
          None
      in
      Logs.info (fun m -> m "Found documentation page for %s" url);
      Lwt.return maybe_doc
  | Error _ ->
      Logs.info (fun m -> m "Failed to fetch documentation page for %s" url);
      Lwt.return None

let documentation_page ~kind t path =
  let package_url =
    package_url ~kind (Name.to_string t.name) (Version.to_string t.version)
  in
  let url = package_url ^ "doc/" ^ path ^ ".json" in
  odoc_page ~url

let file ~kind t path =
  let package_url =
    package_url ~kind (Name.to_string t.name) (Version.to_string t.version)
  in
  let url = package_url ^ path ^ ".json" in
  odoc_page ~url

let search_index ~kind t =
  let package_url =
    package_url ~kind (Name.to_string t.name) (Version.to_string t.version)
  in
  let url = package_url ^ "index.js" in
  let open Lwt.Syntax in
  let* content = http_get url in
  match content with
  | Ok content -> Lwt.return (Some content)
  | Error _ ->
      Logs.info (fun m -> m "Failed to fetch search index at %s" url);
      Lwt.return None

module Documentation_status = Documentation_status

let documentation_status ~kind t : Documentation_status.t option Lwt.t =
  let open Lwt.Syntax in
  let package_url =
    package_url ~kind (Name.to_string t.name) (Version.to_string t.version)
  in
  let url = package_url ^ "status.json" in
  let* content = http_get url in
  let status =
    match content with
    | Ok s ->
        Some (s |> Yojson.Safe.from_string |> Documentation_status.of_yojson)
    | _ -> None
  in
  Lwt.return status

let doc_exists t name version =
  let package = get t name version in
  let open Lwt.Syntax in
  match package with
  | None -> Lwt.return None
  | Some package -> (
      let* doc_stat = documentation_status ~kind:`Package package in
      match doc_stat with
      | Some { failed = false; _ } -> Lwt.return (Some version)
      | _ -> Lwt.return None)

let latest_documented_version t name =
  let rec aux vlist =
    let open Lwt.Syntax in
    match vlist with
    | [] -> Lwt.return None
    | _ -> (
        let version = List.hd vlist in
        let* doc = doc_exists t name version in
        match doc with
        | Some version -> Lwt.return (Some version)
        | None -> aux (List.tl vlist))
  in
  match get_versions t name with
  | None -> Lwt.return None
  | Some vlist -> aux vlist

let is_latest_version t name version =
  match get_latest t name with
  | None -> false
  | Some pkg -> pkg.version = version

module Search = struct
  open Ppx_yojson_conv_lib.Yojson_conv

  type document = { name : string }
  [@@deriving of_yojson] [@@yojson.allow_extra_fields]

  open Lwt.Syntax

  let search_documents ~config ~p ~q t =
    let make_cohttp_lwt_request req =
      let* response =
        match req with
        | Typesense.Api.RequestDescriptor.Get { host; path; headers; params } ->
            Typesense_cohttp_lwt_unix.get ~headers ~params ~host path
        | Post { host; path; headers; params; body } ->
            Typesense_cohttp_lwt_unix.post ~headers ~params ~host ~body path
        | Delete { host; path; headers; params } ->
            Typesense_cohttp_lwt_unix.delete ~headers ~params ~host path
        | Patch { host; path; headers; params; body } ->
            Typesense_cohttp_lwt_unix.patch ~headers ~params ~host ~body path
        | Put { host; path; headers; params; body } ->
            Typesense_cohttp_lwt_unix.put ~headers ~params ~host ~body path
      in
      Lwt.return response
      (*|> Result.map (fun (`Success s) -> s |> Yojson.Safe.from_string)*)
    in
    let* response =
      make_cohttp_lwt_request
        (Typesense.Api.Search.search ~config
           ~search_params:
             (Typesense.Api.Search.make_search_params
                ~q
                  (*~query_by:"title,section_heading,content,category"
                    ~query_by_weights:"4,3,2,1"*)
                ~query_by:"name,description,tags,authors" ~query_by_weights:"4,1,2,1" ~facet_by:"tags,authors" ~per_page:50 ~page:p
                ())
           ~collection_name:"packages" ())
    in
    match response with
    | Ok (`Success s) ->
        (*Dream.log "%s" s;*)
        let r =
          try
            s |> Yojson.Safe.from_string
            |> Typesense.Api.Search.SearchResponse.t_of_yojson
          with Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (s, _) ->
            failwith (Printexc.to_string s)
        in
        ( List.map
            (fun (hit : Typesense.Api.Search.SearchResponse.search_response_hit) ->
              try hit.document |> document_of_yojson
              with Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (s, _) ->
                failwith (Printexc.to_string s))
            r.hits
          |> List.map (fun d ->
                 get_latest t (Name.of_string d.name) |> Option.get),
          r.found,
          r.page,
          r.facet_counts )
        |> Lwt.return
    | Error (`Msg m) -> failwith m
end

let search ~config ~p ~q t = Search.search_documents ~config ~p ~q t
