open Cmdliner

let indexers = [ ("tutorial", Ood_gen.Tutorial.index_search_documents) ]

let cmds =
  Cmd.group (Cmd.info "ood-index")
  @@ List.map
       (fun (term, indexer) ->
         Cmd.v (Cmd.info term) Term.(const indexer $ const ()))
       indexers

let () =
  Printexc.record_backtrace true;
  exit (Cmd.eval cmds)
