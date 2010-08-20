open Lwt

let t1 =
  let rec loop n =
    match n with
      | 0 -> Lwt.return ()
      | _ ->
          prerr_endline "tick";
          lwt () = Lwt_unix.sleep 1. in
          loop (n - 1) in
  loop 15

let t2 =
  Lwt_fiber.start begin fun () ->
    let rec loop n =
      match n with
        | 0 -> ()
        | _ ->
            prerr_endline "tock";
            begin
              try Lwt_fiber.await (lwt () = Lwt_unix.sleep 2. in Lwt.fail (Failure "failed"))
              with Failure "failed" -> ()
            end;
            loop (n - 1) in
    loop 5
  end

let t2 =
  lwt () = t2 in
  prerr_endline "t2 finished";
  Lwt.return ()

let _ = Lwt_main.run (t1 <&> t2)
