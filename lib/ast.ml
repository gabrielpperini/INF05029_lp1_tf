(* ast.ml — Sintaxe abstrata e tipos da linguagem L2 (versão completa).

   L2 = L1 (funções, aplicação, let, let rec) + construções imperativas
   (referências, sequência, while). Ver a especificação da linguagem. *)

(* Tipos: T ::= int | bool | unit | ref T | T1 -> T2 *)
type typ =
  | TInt
  | TBool
  | TUnit
  | TRef of typ
  | TFn  of typ * typ            (* T1 -> T2 *)

(* Operadores binários (conjunto L1 completo) *)
type bop =
  | Plus | Minus | Times | Div          (* aritméticos: int,int -> int *)
  | And | Or                            (* lógicos:     bool,bool -> bool *)
  | Eq | Lt | Gt | Leq | Geq | Neq      (* relacionais: int,int -> bool *)

(* Expressões de L2 *)
type expr =
  | Int of int
  | Bool of bool
  | Id of string
  | If of expr * expr * expr
  | ValueAt of expr                     (* !e  (desreferência) *)
  | Alloc of expr                       (* new e (alocação) *)
  | While of expr * expr
  | Let of string * typ * expr * expr   (* let x:T = e1 in e2 *)
  | Atrib of expr * expr                (* e1 := e2 *)
  | Binop of bop * expr * expr
  | Sentence of expr * expr             (* e1 ; e2 *)
  | Empty                               (* () *)
  | Address of int                      (* l — só em runtime *)
  | Fn of string * typ * expr           (* fn x:T => e *)
  | App of expr * expr                  (* e1 e2 *)
  | LetRec of string * typ * typ * string * expr * expr
      (* let rec f:T1->T2 = (fn y:T1 => e1) in e2
         campos: f, T1, T2, y, e1, e2 *)
  | Not of expr                         (* not e *)

(* v ::= n | b | () | fn x:T => e | l *)
let is_value (e : expr) : bool =
  match e with
  | Int _ | Bool _ | Empty | Fn _ | Address _ -> true
  | _ -> false

let rec string_of_typ (t : typ) : string =
  match t with
  | TInt  -> "int"
  | TBool -> "bool"
  | TUnit -> "unit"
  | TRef t -> "ref " ^ string_of_typ t
  | TFn (t1, t2) -> "(" ^ string_of_typ t1 ^ " -> " ^ string_of_typ t2 ^ ")"

let string_of_bop (op : bop) : string =
  match op with
  | Plus -> "+" | Minus -> "-" | Times -> "*" | Div -> "/"
  | Lt -> "<" | Leq -> "<=" | Gt -> ">" | Geq -> ">="
  | Eq -> "=" | Neq -> "!=" | And -> "&&" | Or -> "||"
