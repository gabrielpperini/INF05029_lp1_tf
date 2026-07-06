(* pp.ml — Pretty-printer de expressões em sintaxe de superfície (com chaves),
   usado para imprimir o valor final e o rastreamento (--trace). *)

open Ast

let rec string_of_expr (e : expr) : string =
  match e with
  | Int n     -> string_of_int n
  | Bool b    -> string_of_bool b
  | Empty     -> "()"
  | Address l -> "l" ^ string_of_int l
  | Id x      -> x
  | Binop (op, e1, e2) ->
      "(" ^ string_of_expr e1 ^ " " ^ string_of_bop op
          ^ " " ^ string_of_expr e2 ^ ")"
  | Not e -> "not " ^ string_of_expr e
  | If (e1, e2, e3) ->
      "if " ^ string_of_expr e1 ^ " then {" ^ string_of_expr e2
            ^ "} else {" ^ string_of_expr e3 ^ "}"
  | Fn (x, t, e) ->
      "(fn " ^ x ^ ":" ^ string_of_typ t ^ " => {" ^ string_of_expr e ^ "})"
  | App (e1, e2) ->
      "(" ^ string_of_expr e1 ^ " " ^ string_of_expr e2 ^ ")"
  | Let (x, t, e1, e2) ->
      "let " ^ x ^ ":" ^ string_of_typ t ^ " = " ^ string_of_expr e1
            ^ " in {" ^ string_of_expr e2 ^ "}"
  | LetRec (f, t1, t2, y, e1, e2) ->
      "let rec " ^ f ^ ":" ^ string_of_typ t1 ^ "->" ^ string_of_typ t2
            ^ " = (fn " ^ y ^ ":" ^ string_of_typ t1 ^ " => {"
            ^ string_of_expr e1 ^ "}) in {" ^ string_of_expr e2 ^ "}"
  | Alloc e   -> "new " ^ string_of_expr e
  | ValueAt e -> "!" ^ string_of_expr e
  | Atrib (e1, e2) -> string_of_expr e1 ^ " := " ^ string_of_expr e2
  | Sentence (e1, e2) -> string_of_expr e1 ^ "; " ^ string_of_expr e2
  | While (e1, e2) ->
      "while " ^ string_of_expr e1 ^ " do {" ^ string_of_expr e2 ^ "}"
