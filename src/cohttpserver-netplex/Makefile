FILES=\
cohttpserver-netplex.cma cohttpserver-netplex.cmxa cohttpserver-netplex.a \
cohttpserver_netplex.cmi cohttpserver_netplex.mli

BFILES=$(addprefix _build/,$(FILES))

all: myocamlbuild.ml
	OCAMLFIND_IGNORE_DUPS_IN=$(LIBDIR)/site-lib \
	OCAMLPATH=`pwd`/../../stage \
	ocamlbuild cohttpserver-netplex.cma cohttpserver-netplex.cmxa

doc:
	ocamlbuild -no-links doc.docdir/index.html

install:
	ocamlfind install cohttpserver-netplex META $(BFILES)

uninstall:
	ocamlfind remove cohttpserver-netplex

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
