{
open Parser  (* módulo gerado pelo Menhir *)
exception Lexing_error of string
}
let newline = '\r' | '\n' | "\r\n"

rule tokenize = parse
  | [' ' '\t']           { tokenize lexbuf }
  | newline              { Lexing.new_line lexbuf; tokenize lexbuf}
  | "(*"                 { comment lexbuf }   (* comentário: desvia até "*)" *)
  | ['0'-'9']+ as lxm { INT (int_of_string lxm) }
  | "true"               { TRUE }
  | "false"              { FALSE }
  | "if"                 { IF }
  | "then"               { THEN }
  | "else"               { ELSE }
  | "{"                  { LBRACE }
  | "}"                  { RBRACE }
  | "while"              { WHILE }
  | "do"                 { DO }
  | "let"                { LET }
  | "in"                 { IN }
  | "not"                { NOT }
  | "int"                { INT_TYPE }   (* para tipo int *)
  | "bool"               { BOOL_TYPE }  (* para tipo bool *)
  | "unit"               { UNIT_TYPE }  (* para tipo unit *)
  | "ref"               { REF_TYPE }  (* para tipo ref *)
  | '+'                  { PLUS }
  | '-'                  { MINUS }
  | '*'                  { TIMES }
  | '/'                  { DIV }
  | "&&"                 { AND }
  | "||"                 { OR }
  | "=="                 { EQ }       (* == é sinônimo de = *)
  | "<="                 { LE }
  | ">="                 { GE }
  | "!="                 { NEQ }
  | "="                  { EQ }
  | "<"                  { LT }
  | ">"                  { GT }
  | "!"                  { EXCL }
  | '('                  { LPAREN }
  | ')'                  { RPAREN }
  | ":="                  { ASSIGN }
  | ':'                  { COLON }
  | ';'                  { SEMICOLON }
  | "new"                { NEW }
  | ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID lxm }
  | eof                  { EOF }
  | _ as c               { raise (Lexing_error (Printf.sprintf "Unexpected character: %c" c)) }

(* comentário (* ... *) não-aninhado; preserva a contagem de linhas *)
and comment = parse
  | "*)"                 { tokenize lexbuf }
  | newline              { Lexing.new_line lexbuf; comment lexbuf }
  | eof                  { raise (Lexing_error "comentário não fechado") }
  | _                    { comment lexbuf }
