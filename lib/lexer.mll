{
open Parser  (* módulo gerado pelo Menhir; o tipo token vem dos %token *)
exception Lexing_error of string
}
let newline = '\r' | '\n' | "\r\n"

rule tokenize = parse
  | [' ' '\t']           { tokenize lexbuf }
  | newline              { Lexing.new_line lexbuf; tokenize lexbuf }
  | "(*"                 { comment lexbuf }              (* comentário: desvia *)

  (* inteiros são sempre não-negativos ('-' é sempre o operador MINUS;
     não há literal negativo nem menos unário — negativos surgem da subtração) *)
  | ['0'-'9']+ as lxm    { INT (int_of_string lxm) }

  (* palavras-chave (antes da regra de identificador) *)
  | "true"               { TRUE }
  | "false"              { FALSE }
  | "if"                 { IF }
  | "then"               { THEN }
  | "else"               { ELSE }
  | "while"              { WHILE }
  | "do"                 { DO }
  | "let"                { LET }
  | "rec"                { REC }
  | "in"                 { IN }
  | "fn"                 { FN }
  | "not"                { NOT }
  | "new"                { NEW }
  | "int"                { INT_TYPE }
  | "bool"               { BOOL_TYPE }
  | "unit"               { UNIT_TYPE }
  | "ref"                { REF_TYPE }

  (* operadores de 2 caracteres antes dos de 1 (maximal munch) *)
  | ":="                 { ASSIGN }
  | "=>"                 { DARROW }
  | "=="                 { EQ }          (* == é sinônimo de = *)
  | "->"                 { ARROW }
  | "<="                 { LE }
  | ">="                 { GE }
  | "!="                 { NEQ }
  | "&&"                 { AND }
  | "||"                 { OR }

  (* operadores/pontuação de 1 caractere *)
  | '+'                  { PLUS }
  | '-'                  { MINUS }
  | '*'                  { TIMES }
  | '/'                  { DIV }
  | '<'                  { LT }
  | '>'                  { GT }
  | '='                  { EQ }
  | '!'                  { EXCL }
  | '('                  { LPAREN }
  | ')'                  { RPAREN }
  | '{'                  { LBRACE }
  | '}'                  { RBRACE }
  | ':'                  { COLON }
  | ';'                  { SEMICOLON }

  | ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID lxm }
  | eof                  { EOF }
  | _ as c               { raise (Lexing_error (Printf.sprintf "Caractere inesperado: %c" c)) }

(* comentário (* ... *) não-aninhado; preserva a contagem de linhas *)
and comment = parse
  | "*)"                 { tokenize lexbuf }
  | newline              { Lexing.new_line lexbuf; comment lexbuf }
  | eof                  { raise (Lexing_error "comentário não fechado") }
  | _                    { comment lexbuf }
