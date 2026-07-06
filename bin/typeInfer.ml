open Lp1_tf
open Ast
exception TypeError of string

type typenv = (string * typ) list (* list de ident e tipos*)
let rec type_of (g: typenv) (e: expr): typ =
    match e with
    | Int n -> TInt
    | Bool b -> TBool
    | Id x ->
        (try
            List.assoc x g
        with Not_found -> raise (TypeError ("identificador " ^ x ^ " nao foi declarado")))
    | If(e1, e2, e3) ->
        if type_of g e1 = TBool then
        let t2 = type_of g e2 in
        let t3 = type_of g e3 in
        if t2 = t3 then t2
        else raise (TypeError "tipos de expressoes then e else devem ser iguais")
        else raise(TypeError "condição do if deve ser do tipo bool")
    | ValueAt e ->
        (match type_of g e with
        | TRef t -> t
        | _ -> raise(TypeError "expressao dada para função unária '!' deve ser do tipo Ref t"))
    | Alloc e ->
        let t1 = type_of g e in
        TRef t1
    | While(e1, e2) ->
        let t1 = type_of g e1 in
        let t2 = type_of g e2 in
        if t1 = TBool && t2 = TUnit then TUnit
        else (
            if t1 <> TBool then raise (TypeError "condição do while deve ser do tipo bool")
            else raise (TypeError "corpo do while deve ser do tipo unit")
        )
    | Let(iden, typ, e1, e2) ->
        if (type_of g e1) = typ then  (* certifica-se de que o tipo de e1 é o mesmo do tipo dado*)
            (type_of ((iden, typ)::g) e2)
        else raise (TypeError "e1 deve ser do tipo typ na expressão Let(iden, typ, e1, e2)")
    | Atrib(e1, e2) ->
        let x = (match e1 with 
            | Id x -> x
            | _ -> raise (TypeError "e1 deve ser do tipo identificador na expressão Atrib(e1, e2)"))
        in
        let t1 = (try (* t1 é o tipo associado ao identificador x*) 
            List.assoc x g
            with Not_found -> raise (TypeError ("identificador " ^ x ^ " nao foi declarado")))  
        in
        let t2 = type_of g e2 in 
        if t1 = TRef(t2) then
            TUnit
        else
            raise(TypeError "numa expressão Atrib(x, e) o tipo de e deve ser T, e o tipo de x deve ser TRef(T)")
    | Binop(bop, e1, e2) ->
        let t1 = type_of g e1 in
        let t2 = type_of g e2 in
        (match bop with
        | Plus | Minus | Times | Div -> if t1 = TInt && t2 = TInt then TInt
            else raise (TypeError "operações aritmeticas requerem operandos do tipo Int")
        | Eq | Lt | Gt ->
            if t1 = TInt && t2 = TInt then TBool
            else raise (TypeError "operações relacionais requerem operandos do tipo Int")
        | And | Or ->
            if t1 = TBool && t2 = TBool then TBool
            else raise (TypeError "operações booleanas requerem operandos do tipo Bool")
        )
    | Sentence(e1, e2) ->
        if type_of g e1 = TUnit then
            type_of g e2
        else raise(TypeError "na expressão Sentence(e1, e2), o tipo de e1 deve ser Unit")
    | Address _ ->
        raise(TypeError "type_infer recebeu um endereço, mas não pois é um valor gerado pelo interpretador")
    | Empty -> TUnit



