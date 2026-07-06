(* main.ml — ponto de entrada: parse -> inferência de tipos -> avaliação.
   Uso: lp1_tf [--trace] <arquivo-fonte>

   Erros são reportados de forma limpa, com a fase entre colchetes:
   [léxico] / [sintático] / [tipo] / [exec]. *)

open Lp1_tf
open Ast

(* dump da AST (mostra a árvore de sintaxe, para fins didáticos) *)
let rec string_of_ast = function
  | Int n     -> Printf.sprintf "Int %d" n
  | Bool b    -> Printf.sprintf "Bool %b" b
  | Id x      -> Printf.sprintf "Id %s" x
  | Empty     -> "Empty"
  | Address l -> Printf.sprintf "Address %d" l
  | If (e1, e2, e3) ->
      Printf.sprintf "If(%s, %s, %s)"
        (string_of_ast e1) (string_of_ast e2) (string_of_ast e3)
  | Let (x, t, e1, e2) ->
      Printf.sprintf "Let(%s, %s, %s, %s)"
        x (string_of_typ t) (string_of_ast e1) (string_of_ast e2)
  | LetRec (f, t1, t2, y, e1, e2) ->
      Printf.sprintf "LetRec(%s, %s, %s, %s, %s, %s)"
        f (string_of_typ t1) (string_of_typ t2) y
        (string_of_ast e1) (string_of_ast e2)
  | Fn (x, t, e) ->
      Printf.sprintf "Fn(%s, %s, %s)" x (string_of_typ t) (string_of_ast e)
  | App (e1, e2) ->
      Printf.sprintf "App(%s, %s)" (string_of_ast e1) (string_of_ast e2)
  | Binop (op, e1, e2) ->
      Printf.sprintf "Binop(%s, %s, %s)"
        (string_of_bop op) (string_of_ast e1) (string_of_ast e2)
  | Not e -> Printf.sprintf "Not(%s)" (string_of_ast e)
  | Atrib (e1, e2) ->
      Printf.sprintf "Atrib(%s, %s)" (string_of_ast e1) (string_of_ast e2)
  | ValueAt e -> Printf.sprintf "ValueAt(%s)" (string_of_ast e)
  | Alloc e   -> Printf.sprintf "Alloc(%s)" (string_of_ast e)
  | While (e1, e2) ->
      Printf.sprintf "While(%s, %s)" (string_of_ast e1) (string_of_ast e2)
  | Sentence (e1, e2) ->
      Printf.sprintf "Sentence(%s, %s)" (string_of_ast e1) (string_of_ast e2)

let leia_arquivo (filename : string) : string =
  let ic = open_in filename in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic; s

let interpretar ?(trace = false) (codigo : string) : unit =
  let lexbuf = Lexing.from_string codigo in
  match Parser.main Lexer.tokenize lexbuf with
  | exception Lexer.Lexing_error msg ->
      Printf.eprintf "[léxico] %s\n" msg; exit 1
  | exception Parser.Error ->
      let p = lexbuf.Lexing.lex_curr_p in
      Printf.eprintf "[sintático] erro de sintaxe na linha %d, coluna %d\n"
        p.Lexing.pos_lnum (p.Lexing.pos_cnum - p.Lexing.pos_bol);
      exit 1
  | ast ->
      print_endline "Árvore de Sintaxe Abstrata:";
      print_endline (string_of_ast ast);
      match TypeInfer.type_of [] ast with
      | exception TypeInfer.TypeError msg ->
          Printf.eprintf "[tipo] %s\n" msg; exit 1
      | t ->
          print_endline "Tipo inferido:";
          print_endline (string_of_typ t);
          let avaliar () =
            if trace then Eval.eval_trace ast else fst (Eval.eval ast)
          in
          match avaliar () with
          | exception Eval.Stuck e ->
              Printf.eprintf "[exec] expressão travada: %s\n"
                (Pp.string_of_expr e); exit 1
          | valor ->
              print_endline "Resultado da Avaliação:";
              print_endline (Pp.string_of_expr valor)

let () =
  let args = List.tl (Array.to_list Sys.argv) in
  let trace = List.mem "--trace" args in
  match List.filter (fun a -> a <> "--trace") args with
  | [ filename ] -> interpretar ~trace (leia_arquivo filename)
  | _ ->
      Printf.eprintf "Uso: %s [--trace] <arquivo-fonte>\n" Sys.argv.(0);
      exit 1
