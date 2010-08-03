val sleep : float -> unit Lwt_cml.event

val read : Lwt_unix.file_descr -> string -> int -> int -> int Lwt_cml.event
val write : Lwt_unix.file_descr -> string -> int -> int -> int Lwt_cml.event
val accept: Lwt_unix.file_descr -> (Lwt_unix.file_descr * Unix.sockaddr) Lwt_cml.event
