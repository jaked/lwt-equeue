let event_system = ref None
let group = ref None
let old_resources = ref []
let in_start = ref false

let get_event_system () =
  match !event_system with
    | None -> failwith "event system not set"
    | Some es -> es

let get_group () =
  match !group with
    | None -> failwith "event system not set"
    | Some g -> g

let select set_r set_w set_e timeout =
  begin match set_r, set_w, set_e, timeout with
    | [], [], [], Some 0.0 -> ()
    | _ ->
        let es = get_event_system () in
        let g = get_group () in
        let rs = List.fold_left (fun rs fd -> (Unixqueue.Wait_in fd, -1.)::rs) [] set_r in
        let rs = List.fold_left (fun rs fd -> (Unixqueue.Wait_out fd, -1.)::rs) rs set_w in
        let rs = List.fold_left (fun rs fd -> (Unixqueue.Wait_oob fd, -1.)::rs) rs set_e in
        let rs =
          match timeout with
            | None -> rs
            | Some timeout -> (Unixqueue.Wait (es#new_wait_id ()), timeout)::rs in
        List.iter (fun r -> es#add_resource g r) rs;
        old_resources := rs
  end;
  (lazy 0., [], [], [])

let add_resources () =
  Lwt.wakeup_paused ();
  ignore (Lwt_main.apply_filters select [] [] [] None)

let remove_resources () =
  let es = get_event_system () in
  let g = get_group () in
  List.iter (fun (r, _) -> es#remove_resource g r) !old_resources;
  old_resources := []

let iteration () =
  add_resources ();
  let es = get_event_system () in
  es#run ()

let handler _ _ e =
  let set_r, set_w, set_e =
    match e with
      | Unixqueue.Input_arrived (_, fd) -> [ fd ], [], []
      | Unixqueue.Output_readiness (_, fd) -> [], [ fd ], []
      | Unixqueue.Out_of_band (_, fd) -> [], [], [ fd ]
      | Unixqueue.Timeout _ -> [], [], []
      | _ -> raise Equeue.Reject in
  ignore
    (Lwt_main.apply_filters
       (fun _ _ _ _ -> Lazy.lazy_from_fun Unix.gettimeofday, set_r, set_w, set_e)
       [] [] [] None);
  remove_resources ();
  if !in_start then add_resources ()

let _ = Lwt_main.main_loop_iteration := iteration

let set_event_system es =
  if !event_system <> None then failwith "event system already set";
  let g = es#new_group () in
  event_system := Some es;
  group := Some g;
  es#add_handler g handler

let unset_event_system () =
  let es = get_event_system () in
  let g = get_group () in
  es#clear g;
  event_system := None;
  group := None;
  old_resources := []

let start t =
  in_start := true;
  Lwt.ignore_result (t ());
  add_resources ()
