FILES=\
lwt-stuff.cma lwt-stuff.cmxa lwt-stuff.a \
lwt_cml.cmi lwt_cml.mli \
lwt_cml_unix.cmi lwt_cml_unix.mli \
lwt_cml_queue.cmi lwt_cml_queue.mli \
lwt_queue.cmi lwt_queue.mli \
lwt_pqueue.cmi lwt_pqueue.mli \

BFILES=$(addprefix _build/,$(FILES))

all: myocamlbuild.ml
	ocamlbuild lwt-stuff.cma lwt-stuff.cmxa

doc:
	ocamlbuild -no-links doc.docdir/index.html

install:
	ocamlfind install lwt-stuff META $(BFILES)

uninstall:
	ocamlfind remove lwt-stuff

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
