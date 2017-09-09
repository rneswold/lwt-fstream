exception Source_terminated

(* A stream, ['a t], is a promise to return an ['a node]. There are
   two node types, [Ref] and [Stream]. [Ref] is returned only when the
   stream is created. It contains a reference to the latest node in
   the stream. All streams returned by [next] will be the functional
   form, [Stream]. *)

type 'a source = Ref of 'a t ref
and 'a node = Stream of ('a * 'a t)
and 'a t = 'a node Lwt.t

(* [push] is the function that stream producers use to add items to a
   stream. *)

let push ref_thread ref_waker v =
  let new_node, new_waker = Lwt.wait () in
  begin
    Lwt.wakeup_later !ref_waker @@ Stream (v, new_node);
    ref_waker := new_waker;
    ref_thread := new_node
  end

(* This is the finalizer for the [push] function. If the [push]
   function goes out of scope, no more items can be pushed on the
   stream. Rather than have all stream clients forever block, the
   stream is terminared with a [Source_terminated] exception. *)

let final rw =
  Lwt_gc.finalise Lwt.(fun _ -> wrap2 wakeup_exn !rw Source_terminated)

(* Creates a push-driven stream. *)

let create_push () =
  let node, awakener = Lwt.wait () in
  let rw = ref awakener
  and rt = ref node in
  let p = push rt rw in
  ( final rw p; (Ref rt, p) )

let snapshot (Ref rt) = !rt

(* When cloning a stream, if it's the initial, [Ref] form, return the
   underlying stream. Otherwise return the passed stream. *)

external clone : 'a t -> 'a t = "%identity"

(* A stream is considered empty if calling [next] would block. *)

let is_empty = Lwt.is_sleeping

let next t =
  let%lwt Stream v = t in
  Lwt.return v

let rec flush t =
  match Lwt.state t with
  | Lwt.Return (Stream (_, t)) ->
     flush t
  | Lwt.Sleep | Lwt.Fail _ ->
     t

let peek t =
  match Lwt.state t with
  | Lwt.Return (Stream (v, _)) ->
     Lwt.return @@ Some v
  | Lwt.Sleep ->
     Lwt.return_none
  | Lwt.Fail exn ->
     Lwt.fail exn

let iter f =
  let rec loop t =
    match%lwt next t with
    | (v, t) ->
       f v >> (loop[@tailcall]) t
    | exception _ ->
       Lwt.return_unit in
  loop

let map f =
  let rec tMap tCurr =
    let%lwt v, tNext = next tCurr in
    let%lwt v = f v in
    Lwt.return @@ Stream (v, tMap tNext) in
  tMap

let filter f =
  let rec tFilter tCurr =
    let%lwt v, tNext = next tCurr in
    if%lwt f v then
      Lwt.return @@ Stream (v, tFilter tNext)
    else
      (tFilter[@tailcall]) tNext
  in
  tFilter

let append a b =
  let b = clone b in
  let rec tAppend tA =
    match%lwt next tA with
    | (v, t) ->
       Lwt.return @@ Stream (v, tAppend t)
    | exception _ ->
       b
  in
  tAppend a

let rec combine tA tB =
  let%lwt vA, tNextA = next tA
  and vB, tNextB = next tB in
  Lwt.return @@ Stream ((vA, vB), combine tNextA tNextB)
