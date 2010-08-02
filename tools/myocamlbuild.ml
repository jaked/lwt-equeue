open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_compiler
open Ocamlbuild_pack.Ocaml_utils
open Ocamlbuild_pack.Tools

(* ocamlfind integration following http://www.nabble.com/forum/ViewPost.jtp?post=15979274 *)

(* these functions are not really officially exported *)
let run_and_read = Ocamlbuild_pack.My_unix.run_and_read
let blank_sep_strings = Ocamlbuild_pack.Lexers.blank_sep_strings

(* this lists all supported packages *)
let find_packages () =
  blank_sep_strings &
    Lexing.from_string &
      run_and_read "ocamlfind list | cut -d' ' -f1"

(* this is supposed to list available syntaxes, but I don't know how to do it. *)
let find_syntaxes () = ["camlp4o"; "camlp4r"]

(* ocamlfind command *)
let ocamlfind x = S[A"ocamlfind"; x]

;;

dispatch begin function
  | Before_options ->

      (* override default commands by ocamlfind ones *)
       Options.ocamlc   := ocamlfind & A"ocamlc";
       Options.ocamlopt := ocamlfind & A"ocamlopt";
       Options.ocamldep := ocamlfind & A"ocamldep";
       Options.ocamldoc := ocamlfind & A"ocamldoc"

  | After_rules ->

      (* When one link an OCaml library/binary/package, one should use -linkpkg *)
       flag ["ocaml"; "byte"; "link"] & A"-linkpkg";
       flag ["ocaml"; "native"; "link"] & A"-linkpkg";
       flag ["ocaml"; "js"; "link"] & A"-linkpkg";

       (* For each ocamlfind package one inject the -package option when
        * compiling, computing dependencies, generating documentation and
        * linking. *)
       List.iter begin fun pkg ->
         flag ["ocaml"; "compile";  "pkg_"^pkg] & S[A"-package"; A pkg];
         flag ["ocaml"; "ocamldep"; "pkg_"^pkg] & S[A"-package"; A pkg];
         flag ["ocaml"; "doc";      "pkg_"^pkg] & S[A"-package"; A pkg];
         flag ["ocaml"; "link";     "pkg_"^pkg] & S[A"-package"; A pkg];
       end (find_packages ());

       (* Like -package but for extensions syntax. Morover -syntax is useless
        * when linking. *)
       List.iter begin fun syntax ->
         flag ["ocaml"; "compile";  "syntax_"^syntax] & S[A"-syntax"; A syntax];
         flag ["ocaml"; "ocamldep"; "syntax_"^syntax] & S[A"-syntax"; A syntax];
         flag ["ocaml"; "doc";      "syntax_"^syntax] & S[A"-syntax"; A syntax];
       end (find_syntaxes ());

       (* The default "thread" tag is not compatible with ocamlfind.
          Indeed, the default rules add the "threads.cma" or
          "threads.cmxa" options when using this tag. When using the
          "-linkpkg" option with ocamlfind, this module will then be
          added twice on the command line.

          To solve this, one approach is to add the "-thread" option
          when using the "threads" package using the previous
          plugin. *)
       flag ["ocaml"; "pkg_threads"; "compile"] & S[A "-thread"];
       flag ["ocaml"; "pkg_threads"; "link"] & S[A "-thread"];

       flag ["ocaml"; "compile"; "DEBUG"] & S[A"-ppopt"; A"-DDEBUG"];
       flag ["ocaml"; "ocamldep"; "DEBUG"] & S[A"-ppopt"; A"-DDEBUG"];

       flag ["ocaml"; "compile"; "FAKE_SERVER"] & S[A"-ppopt"; A"-DFAKE_SERVER"];
       flag ["ocaml"; "ocamldep"; "FAKE_SERVER"] & S[A"-ppopt"; A"-DFAKE_SERVER"];

       rule ("orpc: %.ml -> %_aux.ml[i]")
         ~prods:[
           "%_aux.ml"; "%_aux.mli";
           "%_clnt.ml"; "%_clnt.mli";
           "%_srv.ml"; "%_srv.mli";
           "%_trace.ml"; "%_trace.mli"
         ]
         ~deps:["%.ml"]
         begin fun env build ->
           let x = env "%.ml" in
           Cmd (S [A"orpc"; P x])
         end;

       rule ("orpc: %.mli -> %_aux.ml[i]")
         ~prods:[
           "%_aux.ml"; "%_aux.mli";
           "%_clnt.ml"; "%_clnt.mli";
           "%_srv.ml"; "%_srv.mli";
           "%_trace.ml"; "%_trace.mli"
         ]
         ~deps:["%.mli"]
         begin fun env build ->
           let x = env "%.mli" in
           Cmd (S [A"orpc"; P x])
         end;

       rule ("orpc: %.ml -> %_js_aux.ml[i]")
         ~prods:[
           "%_js_aux.ml"; "%_js_aux.mli";
           "%_js_clnt.ml"; "%_js_clnt.mli";
           "%_js_srv.ml"; "%_js_srv.mli";
           "%_trace.ml"; "%_trace.mli"
         ]
         ~deps:["%.ml"]
         begin fun env build ->
           let x = env "%.ml" in
           Cmd (S [A"orpc"; A"--js"; P x])
         end;

       rule ("orpc: %.mli -> %_js_aux.ml[i]")
         ~prods:[
           "%_js_aux.ml"; "%_js_aux.mli";
           "%_js_clnt.ml"; "%_js_clnt.mli";
           "%_js_srv.ml"; "%_js_srv.mli";
           "%_trace.ml"; "%_trace.mli"
         ]
         ~deps:["%.mli"]
         begin fun env build ->
           let x = env "%.mli" in
           Cmd (S [A"orpc"; A"--js"; P x])
         end;

  | _ -> ()
end

;;
