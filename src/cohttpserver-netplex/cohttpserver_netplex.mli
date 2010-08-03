(** Netplex support for Cohttpserver *)

open Netplex_types

val factory :
  configure:(config_file -> address -> 'a) ->
  ?hooks:('a -> processor_hooks) ->
  ?supported_ptypes:parallelization_type list ->
  name:string ->
  spec:Cohttpserver.Http_daemon.daemon_spec ->
  unit ->
    processor_factory
