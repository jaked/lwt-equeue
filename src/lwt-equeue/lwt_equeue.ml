let event_system = ref None
let group = ref None
let old_set_r = ref []
let old_set_w = ref []
let old_set_e = ref []
let old_timeout = ref None
let in_start = ref false

let get_event_system () =
  match !event_system with
    | None -> failwith "event system not set"
    | Some es -> es

let get_group () =
  match !group with
    | None -> failwith "event system not set"
    | Some g -> g

(* fd sets from Lwt are sorted in decreasing order *)
let add_remove_resources add es g con old_set set =
  let rec loop old_set set =
    match old_set, set with
      | [], [] -> ()
      | [], _ -> if add then List.iter (fun fd -> es#add_resource g (con fd, -1.)) set
      | _, [] -> List.iter (fun fd -> es#remove_resource g (con fd)) old_set
      | oh :: old_set', h :: set' ->
          if oh = h then loop old_set' set'
          else if oh > h then (es#remove_resource g (con oh); loop old_set' set)
          else (if add then es#add_resource g (con h, -1.); loop old_set set') in
  loop old_set set

let select add set_r set_w set_e timeout =
  let es = get_event_system () in
  let g = get_group () in
  add_remove_resources add es g (fun fd -> Unixqueue.Wait_in fd) !old_set_r set_r;
  add_remove_resources add es g (fun fd -> Unixqueue.Wait_out fd) !old_set_w set_w;
  add_remove_resources add es g (fun fd -> Unixqueue.Wait_oob fd) !old_set_e set_e;
  old_set_r := set_r;
  old_set_w := set_w;
  old_set_e := set_e;
  begin match !old_timeout with
    | None -> ()
    | Some t -> es#remove_resource g t
  end;
  begin match timeout with
    | None -> old_timeout := None
    | Some ts ->
        let r = Unixqueue.Wait (es#new_wait_id ()) in
        if add then es#add_resource g (r, ts);
        old_timeout := Some r
  end;
  (lazy 0., [], [], [])

let update_resources add =
  Lwt.wakeup_paused ();
  ignore (Lwt_main.apply_filters (select add) [] [] [] None)

let iteration () =
  update_resources true;
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
  update_resources !in_start

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
  old_set_r := [];
  old_set_w := [];
  old_set_e := [];
  old_timeout := None

let start t =
  in_start := true;
  Lwt.ignore_result (t ());
  update_resources true
