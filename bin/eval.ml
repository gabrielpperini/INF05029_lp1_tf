
open Lp1_tf
open Ast
open Mem

exception NoRuleApplies
let is_value e = 
  match e with
  | Int _ | Bool _ | Empty | Address _  -> true
  | _ -> false

let rec subst v x e =
  match e with
  | Int _ | Bool _ | Address _ | Empty -> e
  | Id y when x = y -> v
  | Id y -> Id y
  | Binop(op, e1, e2) -> Binop(op, subst v x e1, subst v x e2)
  | If(e1, e2, e3) -> If(subst v x e1, subst v x e2, subst v x e3)
  | Let(y,t,e1, e2) when x = y ->  (* isso ta certo?*)
    Let(x,t,(subst v x e1),e2) 
  | Let(y,t,e1,e2) -> Let(y,t,subst v x e1, subst v x e2)
  | Atrib(Id y, e1) when x = y -> Atrib (v, subst v x e1)
  | Atrib(e0,e1) -> Atrib (e0, subst v x e1)  (*n precisa fazer substituição de e0 pois será sempre um id*)
  | ValueAt(e1) -> ValueAt (subst v x e1)
  | Alloc(e1) -> Alloc(subst v x e1)
  | Sentence(e1, e2) -> Sentence(subst v x e1, subst v x e2)
  | While(e1, e2) -> While(subst v x e1, subst v x e2)


let compute(op, v1, v2) =  (*função auxiliar para computar o valor de uma operação com OCaml*)
  match op,v1,v2 with
  | Or, Bool b1, Bool b2 -> Bool(b1 || b2)
  | And, Bool b1, Bool b2 -> Bool(b1 && b2)
  | Plus, Int n1, Int n2 -> Int(n1 + n2)
  | Minus, Int n1, Int n2 -> Int(n1 - n2)
  | Times, Int n1, Int n2 -> Int(n1 * n2)
  | Div, Int n1, Int n2 -> Int(n1 / n2)
  | Eq, Int n1, Int n2 -> Bool(n1 = n2)
  | Lt, Int n1, Int n2 -> Bool(n1 < n2)
  | Gt, Int n1, Int n2 -> Bool(n1 > n2)
  | _ -> failwith "erro no typechecking, deixou permitir operandos de tipos errados" (*failwith sinaliza problema na implementação*)

let rec step (e: expr) (m: mem) : expr * mem = 
  match e with
  | Int _ | Id _ | Bool _ | Empty | Address _ -> (* VALORES *)
    raise NoRuleApplies

  | Binop(bop, v1, v2) when (is_value v1) && (is_value v2) ->  (* regras OP*)
    (compute(bop, v1,v2), m)
  | Binop(bop, v1, e2) when (is_value v1)-> 
    let (e2', m') = step e2 m in
    (Binop(bop, v1, e2'), m')
  | Binop(bop, e1, e2) ->
    let (e1', m') = step e1 m in
    (Binop(bop, e1', e2), m')

  | If(Bool(true), e2, e3) ->    (* regras IF*)
    (e2, m)
  | If(Bool(false), e2, e3) ->
    (e3, m)
  | If(e1, e2, e3) ->
    let (e1', m') = step e1 m in
    (If(e1', e2, e3), m')

  | Let(x,t,v1,e2) when is_value v1 -> (* regras E-LET, semantica call by value *)
    (subst v1 x e2, m)
  | Let(x,t,e1, e2) ->
    let (e1', m') = step e1 m in
    (Let(x,t,e1',e2), m')

  | Atrib(e1, v) when is_value v ->  (* regras ATR *)
    (match e1 with
    | Address l ->
      escreve m l v;
      (Empty, m)
    | _ -> raise NoRuleApplies)
    
  | Atrib(e0,e1) ->  (* e0 tem que ser um id, parser obriga isso*)
    let (e1',m') = step e1 m in
    (Atrib(e0,e1'),m')

  | ValueAt(v) when is_value v ->  (* regras DEREF *)
      (match v with
      | Address l -> 
        (le m l, m) (* lê o valor armazenado na localização l *)
      | _ -> raise NoRuleApplies)
  | ValueAt e1 ->
    let (e1', m) = step e1 m in
    (ValueAt e1', m)

  | Alloc v when is_value v ->  (* regras NEW*)
    let (l,m') = allocate v m in
    (Address l, m')
  | Alloc e ->
    let (e', m') = step e m in
    (Alloc e', m')
    
  | Sentence(Empty, e2) -> (* regras SEQ *)
    (e2, m)
  | Sentence(e1, e2) ->
    let (e1', m') = step e1 m in
    (Sentence(e1', e2), m')

  | While(e1,e2) -> (*regra E-WHILE *)
    (If(e1, Sentence(e2, While(e1,e2)), Empty), m)

let rec eval_expr e m =
  try
    let (e', m') = step e m  (* da loop até dar exceção (mapeada) e teste se é valor*)
    in eval_expr e' m'
  with
    NoRuleApplies ->
      if is_value e then e else failwith "erro no typechecker ou no step"

let eval e = eval_expr e memory 