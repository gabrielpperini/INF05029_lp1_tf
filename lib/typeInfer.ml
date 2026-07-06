(* typeInfer.ml — Inferência/checagem de tipos com ambiente Γ (lookup/update).
   Cada caso corresponde a uma regra do sistema de tipos. A checagem é dirigida
   pela sintaxe (todas as anotações estão presentes), então não há unificação. *)

open Ast

exception TypeError of string

type typenv = (string * typ) list   (* Γ : lista de (identificador, tipo) *)

let lookup (g : typenv) (x : string) : typ =
  match List.assoc_opt x g with
  | Some t -> t
  | None   -> raise (TypeError ("identificador " ^ x ^ " nao foi declarado"))

let update (g : typenv) (x : string) (t : typ) : typenv = (x, t) :: g

let rec type_of (g : typenv) (e : expr) : typ =
  match e with
  (* T-int / T-bool / T-skip *)
  | Int _  -> TInt
  | Bool _ -> TBool
  | Empty  -> TUnit

  (* T-var *)
  | Id x -> lookup g x

  (* T-arit: int,int -> int *)
  | Binop ((Plus | Minus | Times | Div), e1, e2) ->
      expect g e1 TInt; expect g e2 TInt; TInt

  (* T-rel: int,int -> bool *)
  | Binop ((Lt | Leq | Gt | Geq | Eq | Neq), e1, e2) ->
      expect g e1 TInt; expect g e2 TInt; TBool

  (* T-bool: bool,bool -> bool *)
  | Binop ((And | Or), e1, e2) ->
      expect g e1 TBool; expect g e2 TBool; TBool

  (* T-not: bool -> bool *)
  | Not e -> expect g e TBool; TBool

  (* T-if: condição bool; ramos com o mesmo tipo *)
  | If (e1, e2, e3) ->
      expect g e1 TBool;
      let t2 = type_of g e2 in
      let t3 = type_of g e3 in
      if t2 = t3 then t2
      else raise (TypeError "tipos das expressoes then e else devem ser iguais")

  (* T-fn: fn x:T => e  ⊢  T -> T' *)
  | Fn (x, t, e) -> TFn (t, type_of (update g x t) e)

  (* T-app: e1 : T -> T', e2 : T  ⊢  T' *)
  | App (e1, e2) ->
      (match type_of g e1 with
       | TFn (t, t') -> expect g e2 t; t'
       | _ -> raise (TypeError "aplicacao de algo que nao e funcao"))

  (* T-let: e1 : T; corpo tipado com x:T *)
  | Let (x, t, e1, e2) ->
      expect g e1 t;
      type_of (update g x t) e2

  (* T-letrec: corpo da função com f:T1->T2 e y:T1 deve dar T2;
     continuação tipada com f:T1->T2 *)
  | LetRec (f, t1, t2, y, e1, e2) ->
      let tf = TFn (t1, t2) in
      let t1' = type_of (update (update g f tf) y t1) e1 in
      if t1' <> t2 then
        raise (TypeError
          "corpo da funcao recursiva nao tem o tipo de retorno declarado");
      type_of (update g f tf) e2

  (* T-ref *)
  | Alloc e -> TRef (type_of g e)

  (* T-deref *)
  | ValueAt e ->
      (match type_of g e with
       | TRef t -> t
       | _ -> raise (TypeError "expressao dada para '!' deve ser do tipo ref T"))

  (* T-atr: e1 : ref T, e2 : T  ⊢  unit (LHS geral, não só identificador) *)
  | Atrib (e1, e2) ->
      (match type_of g e1 with
       | TRef t -> expect g e2 t; TUnit
       | _ -> raise (TypeError "lado esquerdo de ':=' deve ser do tipo ref T"))

  (* T-seq *)
  | Sentence (e1, e2) ->
      expect g e1 TUnit;
      type_of g e2

  (* T-while *)
  | While (e1, e2) ->
      expect g e1 TBool;
      expect g e2 TUnit;
      TUnit

  (* localizações não aparecem no programa-fonte *)
  | Address _ -> raise (TypeError "localizacao nao pode aparecer no programa fonte")

and expect (g : typenv) (e : expr) (esperado : typ) : unit =
  let obtido = type_of g e in
  if obtido <> esperado then
    raise (TypeError (Printf.sprintf "esperava %s, obtive %s"
      (string_of_typ esperado) (string_of_typ obtido)))
