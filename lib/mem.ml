(* mem.ml — Memória σ: localização (int) -> valor (uma expr que é value).

   Substitui o antigo array fixo de 10 slots por uma Hashtbl com um contador
   de "próxima localização livre" (bump-pointer). A memória cresce sob demanda,
   então não há mais estouro artificial (MemoryFull). *)

open Ast

type mem = {
  tabela : (int, expr) Hashtbl.t;
  mutable proxima : int;              (* próxima localização livre *)
}

let mem_vazia () : mem = { tabela = Hashtbl.create 16; proxima = 0 }

(* ref1: escolhe uma localização fresca l ∉ Dom(σ), grava v, devolve l *)
let aloca (m : mem) (v : expr) : int =
  let l = m.proxima in
  Hashtbl.replace m.tabela l v;
  m.proxima <- l + 1;
  l

(* σ(l) *)
let le (m : mem) (l : int) : expr =
  match Hashtbl.find_opt m.tabela l with
  | Some v -> v
  | None   -> failwith ("localização inexistente: l" ^ string_of_int l)

(* σ[l ↦ v] *)
let escreve (m : mem) (l : int) (v : expr) : unit =
  Hashtbl.replace m.tabela l v
