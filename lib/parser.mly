%{
open Ast
%}

%token <int> INT
%token TRUE FALSE
%token <string> ID
%token IF THEN ELSE LET IN
%token LBRACE RBRACE
%token WHILE DO
%token INT_TYPE BOOL_TYPE UNIT_TYPE REF_TYPE
%token PLUS MINUS TIMES DIV AND OR EQ LT GT LE GE NEQ
%token EXCL NOT
%token LPAREN RPAREN ASSIGN COLON SEMICOLON
%token NEW
%token EOF

%left SEMICOLON (* x: 5 + 3; !x significa (x:= (5+3)); (!x)*)
%right ASSIGN  (* x := y := 5 significa x:= (y:=5) *)
%left OR
%left AND
%left EQ LT GT LE GE NEQ
%left PLUS MINUS
%left TIMES DIV
%nonassoc EXCL   (* nonassoc pq é unario, n faz sentido associatividade*)
%nonassoc NEW
%nonassoc NOT

%start <expr> main
%type  <expr> expr
%type  <typ> typ


%%

main:
  expr EOF { $1 }

expr:
  INT                         { Int $1 }
| TRUE                        { Bool true }
| FALSE                       { Bool false }
| ID                          { Id $1 }
| IF expr THEN LBRACE expr RBRACE ELSE LBRACE expr RBRACE { If ($2, $5, $9) }
| LET ID COLON typ EQ expr IN LBRACE expr RBRACE
                              { Let ($2, $4, $6, $9) }
| expr PLUS expr               { Binop (Plus, $1, $3) }
| expr MINUS expr              { Binop (Minus, $1, $3) }
| expr TIMES expr              { Binop (Times, $1, $3) }
| expr DIV expr               { Binop (Div, $1, $3) }
| expr OR expr               { Binop (Or, $1, $3) }
| expr AND expr               { Binop (And, $1, $3) }
| expr EQ expr               { Binop (Eq, $1, $3) }
| expr LT expr               { Binop (Lt, $1, $3) }
| expr GT expr               { Binop (Gt, $1, $3) }
| expr LE expr               { Binop (Leq, $1, $3) }
| expr GE expr               { Binop (Geq, $1, $3) }
| expr NEQ expr              { Binop (Neq, $1, $3) }
| NOT expr                  { Not ($2) }
| LPAREN RPAREN              { Empty }
| LPAREN expr RPAREN          { $2 }
| WHILE expr DO LBRACE expr RBRACE        { While($2, $5) }
| EXCL expr                 { ValueAt($2) }
| NEW expr                  { Alloc($2) }
| expr SEMICOLON expr       { Sentence($1, $3)}
| expr ASSIGN expr       { Atrib($1, $3)}

typ:
  INT_TYPE                   { TInt }
| BOOL_TYPE                  { TBool }
| UNIT_TYPE                  { TUnit }
| REF_TYPE typ               { TRef ($2) }
| LPAREN typ RPAREN          { $2 }
