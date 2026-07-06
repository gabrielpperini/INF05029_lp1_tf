%{
open Ast
%}

%token <int> INT
%token <string> ID
%token TRUE FALSE
%token IF THEN ELSE LET IN
%token LBRACE RBRACE
%token WHILE DO
%token INT_TYPE BOOL_TYPE UNIT_TYPE REF_TYPE
%token PLUS MINUS TIMES DIV AND OR EQ LT GT
%token LE GE NEQ
%token EXCL
%token LPAREN RPAREN ASSIGN COLON SEMICOLON
%token NEW FN REC NOT
%token ARROW DARROW
%token EOF

(* Sem %left/%right/%nonassoc: precedência e associatividade são codificadas
   pela cascata de não-terminais abaixo (imune a conflitos com a aplicação por
   justaposição). Ordem (menor -> maior precedência):
     ; | := | || | && | < <= > >= = != | + - | * / | not ! new | aplicação *)

%start <expr> main
%type <expr> expr
%type <typ>  typ

%%

main:
  | e = expr EOF                        { e }

(* sequência ';' — associativa à direita *)
expr:
  | e1 = stmt SEMICOLON e2 = expr       { Sentence (e1, e2) }
  | e = stmt                            { e }

(* construções com palavra-chave (corpos entre chaves) + nível de atribuição *)
stmt:
  | IF c = stmt THEN LBRACE e2 = expr RBRACE ELSE LBRACE e3 = expr RBRACE
                                        { If (c, e2, e3) }
  | WHILE c = stmt DO LBRACE e2 = expr RBRACE
                                        { While (c, e2) }
  | FN x = ID COLON t = typ DARROW LBRACE e = expr RBRACE
                                        { Fn (x, t, e) }
  | LET x = ID COLON t = typ EQ e1 = stmt IN LBRACE e2 = expr RBRACE
                                        { Let (x, t, e1, e2) }
  (* let rec COM parênteses em torno do fn.
     t1 usa typ_atom (não typ) para o '->' separador não ser engolido pela
     regra gulosa 'typ ::= typ_atom ARROW typ'. *)
  | LET REC f = ID COLON t1 = typ_atom ARROW t2 = typ EQ
        LPAREN FN y = ID COLON typ DARROW LBRACE e1 = expr RBRACE RPAREN
        IN LBRACE e2 = expr RBRACE
                                        { LetRec (f, t1, t2, y, e1, e2) }
  (* let rec SEM parênteses *)
  | LET REC f = ID COLON t1 = typ_atom ARROW t2 = typ EQ
        FN y = ID COLON typ DARROW LBRACE e1 = expr RBRACE
        IN LBRACE e2 = expr RBRACE
                                        { LetRec (f, t1, t2, y, e1, e2) }
  | e = assign                          { e }

(* ':=' — associativa à direita. O LHS é 'or_' (expr geral, não só Id);
   o typechecker garante que tem tipo ref T (regra T-atr). *)
assign:
  | e1 = or_ ASSIGN e2 = assign         { Atrib (e1, e2) }
  | e = or_                             { e }

or_:
  | a = or_ OR b = and_                 { Binop (Or, a, b) }
  | a = and_                            { a }

and_:
  | a = and_ AND b = cmp                { Binop (And, a, b) }
  | a = cmp                             { a }

cmp:
  | a = cmp LT  b = add                 { Binop (Lt,  a, b) }
  | a = cmp LE  b = add                 { Binop (Leq, a, b) }
  | a = cmp GT  b = add                 { Binop (Gt,  a, b) }
  | a = cmp GE  b = add                 { Binop (Geq, a, b) }
  | a = cmp EQ  b = add                 { Binop (Eq,  a, b) }
  | a = cmp NEQ b = add                 { Binop (Neq, a, b) }
  | a = add                             { a }

add:
  | a = add PLUS  b = mul               { Binop (Plus,  a, b) }
  | a = add MINUS b = mul               { Binop (Minus, a, b) }
  | a = mul                             { a }

mul:
  | a = mul TIMES b = unary             { Binop (Times, a, b) }
  | a = mul DIV   b = unary             { Binop (Div,   a, b) }
  | a = unary                           { a }

(* prefixos unários: not / ! / new — associativos à direita *)
unary:
  | NOT  u = unary                      { Not u }
  | EXCL u = unary                      { ValueAt u }
  | NEW  u = unary                      { Alloc u }
  | a = app                             { a }

(* aplicação por justaposição — associativa à esquerda: f a b = (f a) b *)
app:
  | f = app a = atom                    { App (f, a) }
  | a = atom                            { a }

atom:
  | n = INT                             { Int n }
  | TRUE                                { Bool true }
  | FALSE                               { Bool false }
  | x = ID                              { Id x }
  | LPAREN RPAREN                       { Empty }
  | LPAREN e = expr RPAREN              { e }

(* tipos: '->' à direita; ref liga mais forte que '->' (pega typ_atom) *)
typ:
  | a = typ_atom ARROW b = typ          { TFn (a, b) }
  | a = typ_atom                        { a }

typ_atom:
  | INT_TYPE                            { TInt }
  | BOOL_TYPE                           { TBool }
  | UNIT_TYPE                           { TUnit }
  | REF_TYPE a = typ_atom               { TRef a }
  | LPAREN a = typ RPAREN               { a }
