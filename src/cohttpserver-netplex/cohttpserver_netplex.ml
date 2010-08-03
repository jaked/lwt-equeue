open Cohttpserver

let try_close chan =
  Lwt.catch
    (fun () -> Lwt_io.close chan)
    (fun _ -> Lwt.return ())

let factory
    ~configure
    ?(hooks = fun _ -> new Netplex_kit.empty_processor_hooks())
    ?(supported_ptypes = [ `Multi_processing; `Multi_threading ])
    ~name
    ~spec
    () =

  object (self)
    method name = name

    method create_processor ctrl_cfg cf addr =
      let custom_cfg = configure cf addr in

      object (self)
        inherit Netplex_kit.processor_base (hooks custom_cfg) as super

        method post_add_hook sockserv =
          super # post_add_hook sockserv

        method post_rm_hook sockserv =
	  super # post_add_hook sockserv

        method shutdown () =
          (* XXX gracefully shutdown active connections *)
          super # shutdown ()

        method process ~when_done container fd proto =
          let esys = container # event_system in
          Lwt_equeue.set_event_system esys;

          let callback = Http_daemon.daemon_callback spec in
          let clisockaddr = Unix.getpeername fd in
          let srvsockaddr = Unix.getsockname fd in
          let inchan = Lwt_io.of_unix_fd Lwt_io.input fd in
          let outchan = Lwt_io.of_unix_fd Lwt_io.output fd in

          Lwt_equeue.start begin fun () ->
            let c = callback ~clisockaddr ~srvsockaddr inchan outchan in
            let events =
              match spec.Http_daemon.timeout with
                | None -> [c]
                | Some t -> [c; (Lwt_unix.sleep (float_of_int t) >> Lwt.return ()) ] in
            Lwt.pick events >>
              try_close outchan >>
              try_close inchan >>
              Lwt.return (when_done ())
          end

        method supported_ptypes =
          supported_ptypes

      end
  end
