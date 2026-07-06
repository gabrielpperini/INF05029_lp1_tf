(lang dune 3.23)

(name lp1_tf)
(using menhir 2.1)

(generate_opam_files true)

(source
 (github joaoo-vitor/INF05029_lp1_tf))

(authors "Grupo INF05029 - LP1")

(maintainers "Grupo INF05029 - LP1")

(license MIT)

(package
 (name lp1_tf)
 (synopsis "Interpretador da linguagem imperativa L2 (INF05029 - LP1)")
 (description
  "Analisador lexico e sintatico (ocamllex + menhir), inferencia de tipos e avaliador small-step por substituicao para a linguagem L2 (L1 funcional estendida com referencias, sequencia e while).")
 (depends
  ocaml
  menhir))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
