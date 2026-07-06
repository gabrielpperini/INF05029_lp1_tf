(* main.ml *)

open Lp1_tf
open Lexer (* nome do módulo no arquivo lexer.ml *)
open Parser (* nome do módulo no arquivo parser.ml *)
open Ast
open TypeInfer
open Eval

(* Função para criar string legível da AST (exemplo básico) *)
let rec string_of_typ = function
  | TInt -> "TInt"
  | TBool -> "TBool"
  | TUnit -> "TUnit"
  | TRef (t1) -> Printf.sprintf "TRef(%s)" (string_of_typ t1)

let string_of_bop = function
  | Plus -> "Plus"
  | Minus -> "Minus"
  | Times -> "Times"
  | Div -> "Div"
  | And -> "And"
  | Or -> "Or"
  | Eq -> "Eq"
  | Lt -> "Lt"
  | Gt -> "Gt"

let rec string_of_expr = function
  | Int n -> Printf.sprintf "Int %s" (string_of_int n)
  | Bool b -> Printf.sprintf "Bool %s" (string_of_bool b)
  | Id x -> Printf.sprintf "Id %s" x
  | If (e1, e2, e3) ->
      Printf.sprintf "If( %s , %s , %s)"
        (string_of_expr e1) (string_of_expr e2) (string_of_expr e3)
  | Let (x, t, e1, e2) ->
      Printf.sprintf "Let(%s , %s , %s , %s)"
        x (string_of_typ t) (string_of_expr e1) (string_of_expr e2)
  | Binop (op, e1, e2) ->
      Printf.sprintf "Binop(%s , %s , %s)"
        (string_of_bop op) (string_of_expr e1) (string_of_expr e2)
  | Atrib (x, e) ->
      Printf.sprintf "Atrib(%s , %s)" (string_of_expr x) (string_of_expr e)
  | ValueAt (e) -> Printf.sprintf "ValueAt(%s)" (string_of_expr e)
  | Alloc (e) -> Printf.sprintf "Alloc(%s)" (string_of_expr e)
  | Empty -> "Empty"
  | While (e1, e2) ->
      Printf.sprintf "While(%s , %s)" (string_of_expr e1) (string_of_expr e2)
  | Sentence (e1, e2) ->
      Printf.sprintf "Sentence(%s , %s)" (string_of_expr e1) (string_of_expr e2)
  | Address l -> Printf.sprintf "Address %s" (string_of_int l)

(* Faz o parsing do conteúdo do arquivo e retorna a AST ou uma msg de erro *)
let parse_file filename =
  (* Abre o arquivo fonte *)
  let input_channel = open_in filename in
  (* Cria um buffer lexical a partir do arquivo fonte *)
  let lexbuf = Lexing.from_channel input_channel in
  try
    (* Lexer.tokenize produz tokens; Parser.main consome-os e constrói a AST *)
    let ast = Parser.main Lexer.tokenize lexbuf in
    close_in input_channel;
    Ok ast
  with
  (* O lexer encontrou um caractere/token inválido *)
  | Lexer.Lexing_error message ->
      close_in input_channel;
      Error ("Erro léxico : " ^ message)
  (* O parser recebeu tokens que não correspondem à gramática *)
  | Parser.Error ->
      close_in input_channel;
      (* Obtém a posição onde o erro ocorreu *)
      let position = lexbuf.Lexing.lex_curr_p in
      let line = position.Lexing.pos_lnum in
      let column = position.Lexing.pos_cnum - position.Lexing.pos_bol in
      Error (Printf.sprintf "Erro de Sintaxe: na linha %d, coluna %d" line column)

(* Função principal executada quando o programa é rodado no terminal *)
let () =
  (* Verifica se o usuário forneceu um nome de arquivo *)
  if Array.length Sys.argv <> 2 then begin
    Printf.eprintf "Uso: %s <arquivo-fonte>\n" Sys.argv.(0);
    exit 1
  end;
  let filename = Sys.argv.(1) in
  (* Tenta fazer o parse do arquivo *)
  let ast =
    match parse_file filename with
    | Ok ast -> ast
    | Error msg ->
        prerr_endline msg;
        exit 1
  in
  print_endline "Árvore de Sintaxe Abstrata:";
  print_endline (string_of_expr ast);
  (* Erros de tipo e de execução são reportados de forma limpa, em vez de
     escaparem como exceção OCaml não tratada (Fatal error). *)
  try
    let t1 = type_of [] ast in
    print_endline "Tipo inferido:";
    print_endline (string_of_typ t1);
    let result = eval ast in
    print_endline "Resultado da Avaliação:";
    print_endline (string_of_expr result)
  with
  | TypeError msg ->
      Printf.eprintf "Erro de tipo: %s\n" msg;
      exit 1
  | Division_by_zero ->
      Printf.eprintf "Erro de execução: divisão por zero\n";
      exit 1
  | Failure msg ->
      Printf.eprintf "Erro de execução: %s\n" msg;
      exit 1
