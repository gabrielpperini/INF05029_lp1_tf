open Lp1_tf
open Parser
open Lexer

let string_of_token token = (*função que converte token para string, sem precisar declarar o tipo token*)
  match token with  
  | INT i      -> Printf.sprintf "INT(%d)" i
  | TRUE       -> "TRUE"
  | FALSE      -> "FALSE"
  | ID id      -> Printf.sprintf "ID(\"%s\")" id
  | IF         -> "IF"
  | THEN       -> "THEN"
  | ELSE       -> "ELSE"
  | LET        -> "LET"
  | IN         -> "IN"
  | LBRACE     -> "LBRACE"
  | RBRACE     -> "RBRACE"
  | WHILE      -> "WHILE"
  | DO         -> "DO"
  | INT_TYPE   -> "INT_TYPE"
  | BOOL_TYPE  -> "BOOL_TYPE"
  | UNIT_TYPE  -> "UNIT_TYPE"
  | REF_TYPE   -> "REF_TYPE"
  | PLUS       -> "PLUS"
  | MINUS      -> "MINUS"
  | TIMES      -> "TIMES"
  | DIV        -> "DIV"
  | AND        -> "AND"
  | OR         -> "OR"
  | EQ         -> "EQ"
  | LT         -> "LT"
  | GT         -> "GT"
  | LE         -> "LE"
  | GE         -> "GE"
  | NEQ        -> "NEQ"
  | NOT        -> "NOT"
  | EXCL       -> "EXCL"
  | LPAREN     -> "LPAREN"
  | RPAREN     -> "RPAREN"
  | COLON      -> "COLON"
  | SEMICOLON  -> "SEMICOLON"
  | ASSIGN     -> "ASSIGN"
  | NEW        -> "NEW"
  | EOF        -> "EOF"

let rec print_all_tokens lexbuf =
  try
    let next_token = Lexer.tokenize lexbuf in
    print_endline (string_of_token next_token);
    if next_token <> EOF then print_all_tokens lexbuf
  with
  | Lexer.Lexing_error msg -> 
      Printf.printf "Erro léxico intermediário: %s\n" msg
      
let test_scanner file_path =
  let input_channel = open_in file_path in
  let lexbuf = Lexing.from_channel input_channel in
  print_all_tokens lexbuf;
  close_in input_channel

let () =
  (* Verifica se o usuário forneceu um nome de arquivo *)
  if Array.length Sys.argv <> 2 then 
  begin
    Printf.eprintf "Uso: %s <arquivo-fonte>\n" Sys.argv.(0);
    exit 1
  end;

  let filename = Sys.argv.(1) in
  (* Tenta fazer o parse do arquivo *)  
  test_scanner filename