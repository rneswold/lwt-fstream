open Lwt.Infix

exception Source_terminated

type 'a node = N of ('a * 'a node Lwt.t)

type 'a t = 'a node Lwt.t

let push ref_waker v =
  let new_node, new_waker = Lwt.wait () in
  begin
    Lwt.wakeup_later !ref_waker @@ N (v, new_node);
    ref_waker := new_waker
  end

let final rw =
  Lwt_gc.finalise Lwt.(fun _ -> wrap2 wakeup_exn !rw Source_terminated)

let create_push () =
  let node, awakener = Lwt.wait () in
  let rw = ref awakener in
  let p = push rw in
  ( final rw p; (node, p) )

let create_pull f i =
  let rec loop v =
    let%lwt (v, n) = f v in
    Lwt.return @@ N (v, loop n)
  in
  loop i

let of_list l =
  let f = function
    | [] ->
       Lwt.fail Source_terminated
    | h :: t ->
       Lwt.return (h, t) in
  create_pull f l

let clone t = t

let is_empty = Lwt.is_sleeping

let next t =
  let%lwt N v = t in
  Lwt.return v

let peek t =
  match Lwt.state t with
  | Lwt.Return (N (v, _)) ->
     Lwt.return @@ Some v
  | Lwt.Sleep ->
     Lwt.return_none
  | Lwt.Fail exn ->
     Lwt.fail exn

let iter_s f t =
  let rec loop t =
    match%lwt next t with
    | (v, t) ->
       f v >> (loop[@tailcall]) t
    | exception _ ->
       Lwt.return_unit in
  loop t

let iter f = iter_s (Lwt.wrap1 f)

let map_s f t =
  let rec tMap tCurr =
    let%lwt v, tNext = next tCurr in
    let%lwt v = f v in
    Lwt.return @@ N (v, tMap tNext) in
  tMap t

let map f = map_s (Lwt.wrap1 f)

let filter_s f t =
  let rec tFilter tCurr =
    let%lwt v, tNext = next tCurr in
    if%lwt f v then
      Lwt.return @@ N (v, tFilter tNext)
    else
      (tFilter[@tailcall]) tNext
  in
  tFilter t

let filter f = filter_s (Lwt.wrap1 f)

let append a b =
  let rec tAppend tA =
    match%lwt next tA with
    | (v, t) ->
       Lwt.return @@ N (v, tAppend t)
    | exception _ ->
       b
  in
  tAppend a

let combine a b =
  let rec tCombine tA tB =
    let%lwt vA, tNextA = next tA
    and vB, tNextB = next tB in
    Lwt.return @@ N ((vA, vB), tCombine tNextA tNextB) in
  tCombine a b
