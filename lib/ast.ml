(* ast.ml *)

type typ =
  | TInt
  | TBool
  | TUnit 
  | TRef of typ
  
type bop =
  | Plus | Minus | Times | Div
  | And | Or
  | Eq | Lt | Gt | Leq | Geq | Neq 

type expr =
  | Int of int
  | Bool of bool
  | Id of string
  | If of expr * expr * expr
  | ValueAt of expr (* !e *)
  | Alloc of expr (* new e *)
  | While of expr * expr
  | Let of string * typ * expr * expr
  | Atrib of expr * expr
  | Binop of bop * expr * expr
  | Not of expr (* not e *)
  | Sentence of expr * expr (* e1;e2 *)
  | Empty (* () *)
  | Address of int(* l *)

  
