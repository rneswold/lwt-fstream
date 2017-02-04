(** This module implements a functional stream library. *)

(** Indicates a stream's source has ended. *)
exception Source_terminated

(** A functional stream. *)
type 'a t

(** {2 Construction} *)

(** [create_push ()] returns an empty stream and a function which
    pushes values onto the stream. When the push function is garbage
    collected, the stream will terminate with [Source_terminated]. *)
val create_push : unit -> 'a t * ('a -> unit)

val create_pull : ('a -> ('b * 'a) Lwt.t) -> 'a -> 'b t

val of_list : 'a list -> 'a t

(** [clone s] returns a stream which will return the same content as
    the original. Each thread should read from its own copy of the
    stream. *)
val clone : 'a t -> 'a t

(** {2 Consuming} *)

(** [is_empty s] return [true] if the stream has no immediate content
    to offer (i.e. the next read will block.) Note that, if the stream
    is closed, this function will return [false] because the next read
    will immediately provide information and won't block. *)
val is_empty : 'a t -> bool

(** [next s] returns data associated with the stream (blocking, if no
    data is available) along with a new stream to collect the next
    data. If the stream is closed, this function will [fail] with the
    exception that closed it. *)
val next : 'a t -> ('a * 'a t) Lwt.t

(** [peek s] returns [Some v] if there's data in the stream, [None] if
    there is no data available (i.e. [next s] would block), and [fail
    exn] if the stream is closed. *)
val peek : 'a t -> 'a option Lwt.t

(** [iter f s] passes each element of the stream [s] to the function
    [f] until it reaches the end of the stream. If [f] raises an
    exception, this function fails with the same. [f] should be a
    short, quick function so the rest of the application doesn't
    stall. Use [iter_s] if the function needs to block. *)
val iter : ('a -> unit) -> 'a t -> unit Lwt.t

(** [iter_s f s] is similar to [iter] except the function is a
    thread. *)
val iter_s : ('a -> unit Lwt.t) -> 'a t -> unit Lwt.t

(** {2 Transforming} *)

val map : ('a -> 'b) -> 'a t -> 'b t

val map_s : ('a -> 'b Lwt.t) -> 'a t -> 'b t

val filter : ('a -> bool) -> 'a t -> 'a t

val filter_s : ('a -> bool Lwt.t) -> 'a t -> 'a t

val append : 'a t -> 'a t -> 'a t

val combine : 'a t -> 'b t -> ('a * 'b) t
