(* test_l2.ml — Testes ponta-a-ponta: fonte -> scan -> parse -> typeinfer -> eval.
   Usa a sintaxe concreta do projeto (corpos entre chaves {}) e os construtores
   da AST deste projeto (Int, Id, Times, ValueAt, Sentence, TFn, ...). *)

open Lp1_tf

let parse s =
  let lexbuf = Lexing.from_string s in
  Parser.main Lexer.tokenize lexbuf

(* avalia uma string e devolve (tipo, valor) como strings *)
let run s =
  let ast  = parse s in
  let tipo = TypeInfer.type_of [] ast in
  let (v, _) = Eval.eval ast in
  (Ast.string_of_typ tipo, Pp.string_of_expr v)

let total = ref 0
let falhas = ref 0

let check nome (tipo_esp, valor_esp) entrada =
  incr total;
  match run entrada with
  | (t, v) when t = tipo_esp && v = valor_esp -> Printf.printf "OK    %s\n" nome
  | (t, v) ->
      incr falhas;
      Printf.printf "FALHA %s\n  esperado: %s / %s\n  obtido:   %s / %s\n"
        nome tipo_esp valor_esp t v
  | exception ex ->
      incr falhas;
      Printf.printf "FALHA %s (exceção: %s)\n" nome (Printexc.to_string ex)

(* espera erro de tipo *)
let check_type_error nome entrada =
  incr total;
  match TypeInfer.type_of [] (parse entrada) with
  | _ -> incr falhas; Printf.printf "FALHA %s (esperava erro de tipo)\n" nome
  | exception TypeInfer.TypeError _ -> Printf.printf "OK    %s\n" nome

(* compara a AST parseada com a esperada *)
let check_ast nome entrada ast_esp =
  incr total;
  match parse entrada with
  | a when a = ast_esp -> Printf.printf "OK    %s\n" nome
  | _ -> incr falhas; Printf.printf "FALHA %s (AST diferente)\n" nome
  | exception ex ->
      incr falhas;
      Printf.printf "FALHA %s (exceção: %s)\n" nome (Printexc.to_string ex)

let () =
  (* aritmética: precedência * antes de + *)
  check "soma"       ("int",  "7")   "1 + 2 * 3";
  check "sub"        ("int",  "1")   "3 - 2";
  check "mul"        ("int",  "20")  "4 * 5";
  check "div"        ("int",  "3")   "7 / 2";

  (* comparações *)
  check "menor"      ("bool", "true")  "1 < 2";
  check "maior"      ("bool", "false") "1 > 2";
  check "leq"        ("bool", "true")  "2 <= 2";
  check "geq"        ("bool", "true")  "3 >= 2";
  check "igual"      ("bool", "true")  "3 = 3";
  check "igual-sin"  ("bool", "true")  "3 == 3";   (* == é sinônimo de = *)
  check "difere"     ("bool", "true")  "3 != 4";
  check "let-com-igualdade" ("bool", "true")
        "let x:bool = 1 = 1 in {x}";   (* '=' do let vs '=' comparação *)

  (* lógicos e not *)
  check "e-logico"   ("bool", "false") "true && false";
  check "ou-logico"  ("bool", "true")  "false || true";
  check "negacao"    ("bool", "false") "not true";
  check "precedencia-bool" ("bool", "true") "1 < 2 && not (3 < 0)";

  (* condicional *)
  check "if"         ("int", "10") "if 3 < 5 then {10} else {20}";

  (* let e variáveis *)
  check "let"        ("int", "11") "let x:int = 10 in {x + 1}";
  check "let-shadow" ("int", "2")  "let x:int = 1 in {let x:int = 2 in {x}}";

  (* funções *)
  check "fn-tipo"    ("(int -> int)", "(fn x:int => {(x + x)})")
        "fn x:int => {x + x}";
  check "aplicacao"  ("int", "42") "(fn x:int => {x + x}) 21";
  check "app-curry"  ("int", "7")
        "(fn x:int => {fn y:int => {x + y}}) 3 4";

  (* recursão: fatorial (com parênteses no fn) *)
  check "fatorial"   ("int", "120")
        "let rec fat:int->int = \
           (fn x:int => {if x < 1 then {1} else {x * fat (x - 1)}}) \
         in {fat 5}";

  (* recursão: mesma coisa SEM parênteses (as duas formas são aceitas) *)
  check "fatorial-sem-parens" ("int", "120")
        "let rec fat:int->int = \
           fn x:int => {if x < 1 then {1} else {x * fat (x - 1)}} \
         in {fat 5}";

  (* referências *)
  check "new-deref"  ("int", "0")  "!(new 0)";
  check "incremento" ("int", "1")
        "let c:ref int = new 0 in {c := !c + 1; !c}";

  (* contador (closure sobre estado) *)
  check "contador"   ("int", "3")
        "let counter:ref int = new 0 in { \
           let next_val:unit->int = \
             (fn z:unit => {counter := !counter + 1; !counter}) in { \
           (next_val ()) + (next_val ()) } }";

  (* fatorial imperativo (while + ref) *)
  check "fat-imperativo" ("int", "120")
        "let rec fat:int->int = (fn x:int => { \
           let z:ref int = new x in { \
           let y:ref int = new 1 in { \
           while !z > 0 do {y := !y * !z; z := !z - 1}; \
           !y } } }) \
         in {fat 5}";

  (* sequência e unit *)
  check "seq"   ("int", "5")   "(); 5";
  check "unit"  ("unit", "()") "()";
  check "atrib" ("unit", "()") "let c:ref int = new 0 in {c := 7}";

  (* while simples: soma 1..3 = 6 *)
  check "while-soma" ("int", "6")
        "let cont:ref int = new 1 in { \
           let total:ref int = new 0 in { \
           while !cont < 4 do {total := !total + !cont; cont := !cont + 1}; \
           !total } }";

  (* erros de tipo esperados *)
  check_type_error "if-ramos"   "if true then {1} else {false}";
  check_type_error "soma-bool"  "1 + true";
  check_type_error "var-livre"  "x + 1";
  check_type_error "deref-int"  "!5";
  check_type_error "app-nao-fn" "5 3";
  check_type_error "app-arg"    "(fn x:int => {x}) true";
  check_type_error "atr-tipo"   "let c:ref int = new 0 in {c := true}";
  check_type_error "seq-e1"     "1; 2";
  check_type_error "not-int"    "not 5";
  check_type_error "and-int"    "true && 1";
  check_type_error "ref-anot"   "let c:ref bool = new 0 in {()}";

  (* parser: associatividade e precedência *)
  check_ast "prec" "1 + 2 * 3"
    (Ast.Binop (Ast.Plus, Ast.Int 1, Ast.Binop (Ast.Times, Ast.Int 2, Ast.Int 3)));
  check_ast "app-esq" "f a b"
    (Ast.App (Ast.App (Ast.Id "f", Ast.Id "a"), Ast.Id "b"));
  check_ast "deref-add" "!c + 1"
    (Ast.Binop (Ast.Plus, Ast.ValueAt (Ast.Id "c"), Ast.Int 1));
  check_ast "seq-dir" "a; b; c"
    (Ast.Sentence (Ast.Id "a", Ast.Sentence (Ast.Id "b", Ast.Id "c")));
  check_ast "arrow-dir" "fn f:int->int->int => {f}"
    (Ast.Fn ("f", Ast.TFn (Ast.TInt, Ast.TFn (Ast.TInt, Ast.TInt)), Ast.Id "f"));
  check_ast "igualdade-ast" "1 = 2"
    (Ast.Binop (Ast.Eq, Ast.Int 1, Ast.Int 2));

  Printf.printf "\n%d testes, %d falhas\n" !total !falhas;
  if !falhas > 0 then exit 1
