open Ast

(* Memória σ: localização (int) -> valor (uma expr que é value).
   Implementada com uma Hashtbl e um contador da próxima localização livre
   (bump-pointer), então cresce sob demanda — sem limite fixo de posições. *)
type mem = {
  tabela : (int, expr) Hashtbl.t;
  mutable proxima : int;             (* próxima localização livre *)
}

let mem_vazia () : mem = { tabela = Hashtbl.create 16; proxima = 0 }

(* memória global usada pelo avaliador *)
let memory : mem = mem_vazia ()

(* aloca uma localização fresca l ∉ Dom(σ), grava v e devolve (l, memória) *)
let allocate (v: expr) (m: mem) : (int * mem) =
  let l = m.proxima in
  Hashtbl.replace m.tabela l v;
  m.proxima <- l + 1;
  (l, m)

(* lê σ(l) *)
let le (m: mem) (l: int) : expr =
  match Hashtbl.find_opt m.tabela l with
  | Some v -> v
  | None -> failwith ("localização inexistente: l" ^ string_of_int l)

(* escreve σ[l ↦ v] *)
let escreve (m: mem) (l: int) (v: expr) : unit =
  Hashtbl.replace m.tabela l v
