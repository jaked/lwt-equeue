val set_event_system : Unixqueue.event_system -> unit
val unset_event_system : unit -> unit
val start : (unit -> 'a Lwt.t) -> unit
