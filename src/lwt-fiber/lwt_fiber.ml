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
  active_prompt := None;

  match Lwt.poll t with
    | Some v -> v
    | None ->
        Delimcc.take_subcont p begin fun sk () ->
          let ready _ =
            active_prompt := Some p;
            Delimcc.push_delim_subcont sk begin fun () ->
              match Lwt.poll t with
                | Some v -> v
                | None -> assert false
            end;
            Lwt.return () in
          ignore (Lwt.try_bind (fun () -> t) ready ready)
        end
