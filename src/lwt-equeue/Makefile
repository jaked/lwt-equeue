FILES=\
lwt-equeue.cma lwt-equeue.cmxa lwt-equeue.a \
lwt_equeue.cmi lwt_equeue.mli

BFILES=$(addprefix _build/,$(FILES))

all: myocamlbuild.ml
	ocamlbuild lwt-equeue.cma lwt-equeue.cmxa
	ocamlfind remove -destdir ../../stage lwt-equeue
	ocamlfind install -destdir ../../stage lwt-equeue META $(BFILES)

doc:
	ocamlbuild -no-links doc.docdir/index.html

install:
	ocamlfind install lwt-equeue META $(BFILES)

uninstall:
	ocamlfind remove lwt-equeue

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
