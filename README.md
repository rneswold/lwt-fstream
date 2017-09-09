# LWT Functional Streams

An alternate stream library for LWT which uses a functional API.



## Build

    opam install lwt-fstream

or:

    opam pin add -k git lwt-fstream https://github.com/rneswold/lwt-fstream.git
    opam install lwt-fstream

## Use

The following example stuffs a stream with three integers and then
iterates over the list, printing out each number. Since this isn't a
long-running program, the push function `p` won't get
reclaimed. `Gc.full_major()` is called to garbage collect the function
so that the stream is closed.

```
open Lwt

let get_stream () =
  let s, p = Lwt_fstream.create_push () in
  let s = Lwt_fstream.snapshot s in
  begin
    p 0;
    p 1;
    p 2;
    s
  end

let main () =
  let s = get_stream () in
  begin
    Gc.full_major ();
    Lwt_fstream.iter (Lwt_log.info_f "Pulled %d") s >>=
      Lwt_io.flush_all
  end

let () =
  Lwt_main.run (main () >> Lwt_log.info "Done.")
```

```
ocamlfind ocamlopt -package lwt.unix,lwt.ppx,lwt-fstream -linkpkg -o a.out example.ml
```

```
$ LWT_LOG="*->info" ./a.out
```

## License

permissive free software (BSD-2)
