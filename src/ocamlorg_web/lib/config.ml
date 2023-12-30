let env_with_default k v = Sys.getenv_opt k |> Option.value ~default:v

let to_bool s =
  match String.lowercase_ascii s with "true" | "1" -> true | _ -> false

let http_port = env_with_default "OCAMLORG_HTTP_PORT" "8080" |> int_of_string

let typesense_config =
  let url =
    env_with_default "OCAMLORG_TYPESENSE_HOST" "http://localhost:8108"
  in
  let api_key =
    env_with_default "OCAMLORG_TYPESENSE_API_KEY"
      "{OCAMLORG_TYPESENSE_API_KEY is missing}"
  in
  Typesense.Api.{ url; api_key }
