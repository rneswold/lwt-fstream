(** This module implements a functional stream library. *)

(** Indicates a stream's source has ended. *)
exception Source_terminated

(** A functional stream. *)
type 'a t

type 'a source

(** {2 Construction} *)

(** [create_push ()] returns a stream and a function which pushes
    values onto the stream. When the push function is garbage
    collected, the stream will terminate with [Source_terminated]. *)
val create_push : unit -> 'a source * ('a -> unit)

(** [snapshot src] returns the end of the current stream (so that a
    call to [next] will block.) It is an efficient form of [clone s |>
    flush]. *)
val snapshot : 'a source -> 'a t

(** [clone s] returns a stream which will return the same content as
    the original. Each thread should read from its own copy of the
    stream. *)
val clone : 'a t -> 'a t

(** {2 Consuming}

    This seciton contains functions that process content of a
    stream. *)

(** [is_empty s] return [true] if the stream has no immediate content
    to offer (i.e. the next read will block.) Note that, if the stream
    is closed, this function will return [false] because the next read
    will immediately provide information and won't block. *)
val is_empty : 'a t -> bool

(** [next s] returns data associated with the stream (blocking, if no
    data is available) along with a new stream to collect the next
    data. If the stream is closed, this function will [fail] with the
    exception that terminated it. *)
val next : 'a t -> ('a * 'a t) Lwt.t

(** [peek s] returns [Some v] if there's data in the stream, [None] if
    there is no data available (i.e. [next s] would block), and [fail
    exn] if the stream is closed. *)
val peek : 'a t -> 'a option Lwt.t

(** [flush s] skips any available content in the stream and returns
    the point of the stream that would block on a call to [next]. *)
val flush : 'a t -> 'a t

(** [iter f s] passes each element of the stream [s] to the function
    [f] until it reaches the end of the stream. If [f] raises an
    exception, this function fails with the same. *)
val iter : ('a -> unit Lwt.t) -> 'a t -> unit Lwt.t

(** {2 Transforming}

    This section contains functions that return streams containing the
    content of the source stream, but transformed in a specified
    way. These functions can be combined to create complex
    transformations. *)

(** [map f s] returns a stream whose content is the result of applying
    the function [f] to each element of the source stream. *)
val map : ('a -> 'b Lwt.t) -> 'a t -> 'b t

(** [filter f s] returns a stream containing the elements of the
    source stream when applying the function [f] returns [true]. *)
val filter : ('a -> bool Lwt.t) -> 'a t -> 'a t

(** [append a b] *)
val append : 'a t -> 'a t -> 'a t

(** [combine a b] *)
val combine : 'a t -> 'b t -> ('a * 'b) t
