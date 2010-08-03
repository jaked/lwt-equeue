open Cohttp
open Cohttpserver

let start() =
  let (opt_list, cmdline_cfg) = Netplex_main.args() in

  Arg.parse
    opt_list
    (fun s -> raise (Arg.Bad ("Don't know what to do with: " ^ s)))
    "usage: netplex [options]";

  let callback conn_id req out =
    Http_daemon.respond ~body:"hello world!" out in

  let spec = {
    Http_daemon.default_spec with
      Http_daemon.callback = callback
  } in

  let factories =
    [ Cohttpserver_netplex.factory
        ~configure:(fun _ _ -> ())
        ~name:"hello"
        ~spec
        ();
    ]
  in

  Netplex_main.startup
    (Netplex_mp.mp())
    Netplex_log.logger_factories   (* allow all built-in logging styles *)
    Netplex_workload.workload_manager_factories (* ... all ways of workload management *)
    factories
    cmdline_cfg
;;

Sys.set_signal Sys.sigpipe Sys.Signal_ignore;
start()
;;
