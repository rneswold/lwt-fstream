# LWT Functional Streams

An alternate stream library for LWT which uses a functional API.

## Build

    opam install lwt-fstream

or:

    opam pin add -k git lwt-fstream https://github.com/rneswold/lwt-fstream.git
    opam install lwt-fstream

## Use

```
let get_stream () =
  let s, p = Lwt_fstream.create_push () in
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
    Lwt_fstream.iter_s (Lwt_log.info_f "Pulled %d") s
  end
   
let () =
  Lwt_main.run (main ())
```

```
ocamlfind ocamlopt -package lwt.fstream,lwt.ppx -linkpkg -o a.out example.ml
```

```
$ LWT_LOG="*->info" ./a.out
```

## License

permissive free software (BSD-2)
