all: myocamlbuild.ml
	ocamlbuild fiber.byte fiber.native

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
