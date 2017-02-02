OPTS= -classic-display -use-ocamlfind
TARGETS= lwt_fstream.cma lwt_fstream.cmxa lwt_fstream.cmxs lwt_fstream.a

build:
	ocamlbuild $(OPTS) $(addprefix src/, $(TARGETS))

clean:
	ocamlbuild -clean

install: build
	ocamlfind install lwt-fstream src/META \
	  $(addprefix _build/src/, $(TARGETS)) _build/src/*.cmi
