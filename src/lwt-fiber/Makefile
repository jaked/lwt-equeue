FILES=\
lwt-fiber.cma lwt-fiber.cmxa lwt-fiber.a \
lwt_fiber.cmi lwt_fiber.mli \

BFILES=$(addprefix _build/,$(FILES))

all: myocamlbuild.ml
	ocamlbuild lwt-fiber.cma lwt-fiber.cmxa

doc:
	ocamlbuild -no-links doc.docdir/index.html

install:
	ocamlfind install lwt-fiber META $(BFILES)

uninstall:
	ocamlfind remove lwt-fiber

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
