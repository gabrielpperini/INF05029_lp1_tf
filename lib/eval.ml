(* eval.ml — Avaliador small-step por substituição (call-by-value) + memória σ.
   Cada caso de step corresponde a uma regra da semântica operacional;
   let rec usa o "unfold" (desdobramento sob demanda). *)

open Ast
open Mem

exception Stuck of expr

(* Substituição {v/x} e — substitui ocorrências livres de x por v.
   v é sempre um valor fechado, então não há captura de variáveis
   (programas bem tipados dispensam renomeação). *)
let rec subst (v : expr) (x : string) (e : expr) : expr =
  match e with
  | Id y -> if y = x then v else e
  | Int _ | Bool _ | Empty | Address _ -> e

  | Binop (op, e1, e2)  -> Binop (op, subst v x e1, subst v x e2)
  | Not e               -> Not (subst v x e)
  | If (e1, e2, e3)     -> If (subst v x e1, subst v x e2, subst v x e3)
  | Alloc e             -> Alloc (subst v x e)
  | ValueAt e           -> ValueAt (subst v x e)
  | Atrib (e1, e2)      -> Atrib (subst v x e1, subst v x e2)
  | Sentence (e1, e2)   -> Sentence (subst v x e1, subst v x e2)
  | While (e1, e2)      -> While (subst v x e1, subst v x e2)
  | App (e1, e2)        -> App (subst v x e1, subst v x e2)

  (* fn liga o parâmetro y: só substitui no corpo se y <> x (shadowing) *)
  | Fn (y, t, corpo) ->
      if y = x then Fn (y, t, corpo)
      else Fn (y, t, subst v x corpo)

  (* let liga x no corpo e2; e1 é sempre substituído *)
  | Let (y, t, e1, e2) ->
      let e1' = subst v x e1 in
      if y = x then Let (y, t, e1', e2)
      else            Let (y, t, e1', subst v x e2)

  (* let rec liga f (em e1 e e2) e y (em e1) *)
  | LetRec (f, t1, t2, y, e1, e2) ->
      let e1' = if x = f || x = y then e1 else subst v x e1 in
      let e2' = if x = f          then e2 else subst v x e2 in
      LetRec (f, t1, t2, y, e1', e2')

(* Um passo de redução: Some e' se ⟨e,σ⟩ −→ ⟨e',σ'⟩; None se e é valor.
   A memória m é atualizada in-place. *)
let rec step (m : mem) (e : expr) : expr option =
  match e with
  | Int _ | Bool _ | Empty | Fn _ | Address _ -> None   (* valores *)

  (* ----- operações binárias ----- *)
  | Binop (op, e1, e2) when not (is_value e1) ->              (* op1 *)
      (match step m e1 with Some e1' -> Some (Binop (op, e1', e2))
                          | None -> raise (Stuck e))
  | Binop (op, v1, e2) when not (is_value e2) ->              (* op2 *)
      (match step m e2 with Some e2' -> Some (Binop (op, v1, e2'))
                          | None -> raise (Stuck e))
  | Binop (Plus,  Int a, Int b) -> Some (Int (a + b))
  | Binop (Minus, Int a, Int b) -> Some (Int (a - b))
  | Binop (Times, Int a, Int b) -> Some (Int (a * b))
  | Binop (Div,   Int _, Int 0) -> raise (Stuck e)           (* divisão por zero *)
  | Binop (Div,   Int a, Int b) -> Some (Int (a / b))
  | Binop (Lt,  Int a, Int b) -> Some (Bool (a < b))
  | Binop (Leq, Int a, Int b) -> Some (Bool (a <= b))
  | Binop (Gt,  Int a, Int b) -> Some (Bool (a > b))
  | Binop (Geq, Int a, Int b) -> Some (Bool (a >= b))
  | Binop (Eq,  Int a, Int b) -> Some (Bool (a = b))
  | Binop (Neq, Int a, Int b) -> Some (Bool (a <> b))
  | Binop (And, Bool a, Bool b) -> Some (Bool (a && b))
  | Binop (Or,  Bool a, Bool b) -> Some (Bool (a || b))
  | Binop _ -> raise (Stuck e)

  (* ----- negação ----- *)
  | Not (Bool b) -> Some (Bool (not b))
  | Not e1 ->
      (match step m e1 with Some e1' -> Some (Not e1')
                          | None -> raise (Stuck e))

  (* ----- if ----- *)
  | If (Bool true,  e2, _)  -> Some e2
  | If (Bool false, _,  e3) -> Some e3
  | If (e1, e2, e3) ->
      (match step m e1 with Some e1' -> Some (If (e1', e2, e3))
                          | None -> raise (Stuck e))

  (* ----- aplicação (call-by-value) ----- *)
  | App (e1, e2) when not (is_value e1) ->                    (* app1 *)
      (match step m e1 with Some e1' -> Some (App (e1', e2))
                          | None -> raise (Stuck e))
  | App (v1, e2) when not (is_value e2) ->                    (* app2 *)
      (match step m e2 with Some e2' -> Some (App (v1, e2'))
                          | None -> raise (Stuck e))
  | App (Fn (x, _t, corpo), v) -> Some (subst v x corpo)      (* beta *)
  | App _ -> raise (Stuck e)

  (* ----- let ----- *)
  | Let (x, t, e1, e2) when not (is_value e1) ->              (* let1 *)
      (match step m e1 with Some e1' -> Some (Let (x, t, e1', e2))
                          | None -> raise (Stuck e))
  | Let (x, _t, v, e2) -> Some (subst v x e2)                 (* let2 *)

  (* ----- let rec: unfold -----
     {α/f} e2  com  α = fn y:T1 => (let rec f = (fn y:T1 => e1) in e1) *)
  | LetRec (f, t1, t2, y, e1, e2) ->
      let alfa = Fn (y, t1, LetRec (f, t1, t2, y, e1, e1)) in
      Some (subst alfa f e2)

  (* ----- atribuição ----- *)
  | Atrib (Address l, v) when is_value v -> escreve m l v; Some Empty  (* atr1 *)
  | Atrib (v1, e2) when is_value v1 ->                        (* atr2 *)
      (match step m e2 with Some e2' -> Some (Atrib (v1, e2'))
                          | None -> raise (Stuck e))
  | Atrib (e1, e2) ->                                         (* atr3 *)
      (match step m e1 with Some e1' -> Some (Atrib (e1', e2))
                          | None -> raise (Stuck e))

  (* ----- desreferência ----- *)
  | ValueAt (Address l) -> Some (le m l)                      (* deref1 *)
  | ValueAt e1 ->                                             (* deref2 *)
      (match step m e1 with Some e1' -> Some (ValueAt e1')
                          | None -> raise (Stuck e))

  (* ----- alocação ----- *)
  | Alloc v when is_value v -> Some (Address (aloca m v))     (* ref1 *)
  | Alloc e1 ->                                               (* ref2 *)
      (match step m e1 with Some e1' -> Some (Alloc e1')
                          | None -> raise (Stuck e))

  (* ----- sequência ----- *)
  | Sentence (Empty, e2) -> Some e2                           (* seq1 *)
  | Sentence (e1, e2) ->                                      (* seq2 *)
      (match step m e1 with Some e1' -> Some (Sentence (e1', e2))
                          | None -> raise (Stuck e))

  (* ----- while: desdobra em if ----- *)
  | While (e1, e2) -> Some (If (e1, Sentence (e2, While (e1, e2)), Empty))

  | Id _ -> raise (Stuck e)   (* variável livre: não ocorre em prog. bem tipado *)

let rec eval_loop (m : mem) (e : expr) : expr =
  if is_value e then e
  else match step m e with
    | Some e' -> eval_loop m e'
    | None    -> raise (Stuck e)

(* avalia um programa fechado; devolve (valor, memória final) *)
let eval (e : expr) : expr * mem =
  let m = mem_vazia () in
  (eval_loop m e, m)

(* idem, imprimindo cada passo (para --trace / apresentação) *)
let eval_trace (e : expr) : expr =
  let m = mem_vazia () in
  let rec go e =
    Printf.printf "==> %s\n" (Pp.string_of_expr e);
    if is_value e then e
    else match step m e with
      | Some e' -> go e'
      | None    -> raise (Stuck e)
  in go e
