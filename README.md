# LWT Functional Streams

An alternate stream library for LWT which uses a functional API.

## Build

    opam install lwt-fstream

or:

    opam pin add -k git lwt-fstream https://github.com/rneswold/lwt-fstream.git
    opam install lwt-fstream

## Use

```ocaml
# #require "lwt";;
# #require "lwt-fstream";;

# open Lwt.Infix;;

# let l = [1;2;3;4];;

# Lwt_pipe.of_list l
  |> Lwt_pipe.Reader.map ~f:(fun x->x+1)
  |> Lwt_pipe.to_list;;
- : int list Lwt.t = [2; 3; 4; 5]

```

## License

permissive free software (BSD-2)
