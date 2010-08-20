val start : (unit -> 'a) -> 'a Lwt.t
val await : 'a Lwt.t -> 'a
