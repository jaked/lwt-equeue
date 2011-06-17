let active_prompt = ref None

let start f =
  let t, u = Lwt.wait () in
  let p = Delimcc.new_prompt () in
  active_prompt := Some p;

  Delimcc.push_prompt p begin fun () ->
    let r =
      try Lwt.Return (f ())
      with e -> Lwt.Fail e in
    active_prompt := None;
    match r with
      | Lwt.Return v -> Lwt.wakeup u v
      | Lwt.Fail e -> Lwt.wakeup_exn u e
      | Lwt.Sleep -> assert false
  end;
  t

let await t =
  let p =
    match !active_prompt with
      | None -> failwith "await called outside start"
      | Some p -> p in

  match Lwt.poll t with
    | Some v -> v
    | None ->
        active_prompt := None;
        Delimcc.shift0 p begin fun k ->
          let ready _ =
            active_prompt := Some p;
            k ();
            Lwt.return () in
          ignore (Lwt.try_bind (fun () -> t) ready ready)
        end;
        match Lwt.poll t with
          | Some v -> v
          | None -> assert false
