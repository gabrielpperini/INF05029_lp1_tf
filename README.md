# Trabalho Final da Cadeira de LP1 (Linguagens de Programação 1)

## Enunciado
O trabalho consiste em desenvolver um scanner, parser, type_infer e avaliador
para a linguagem **L2**, implementada em OCaml. Esta versão implementa a **L2
completa**: a linguagem funcional L1 (funções, aplicação, `let`, `let rec`)
estendida com as construções imperativas (referências, sequência e `while`).

### Especificação da linguagem L2

- **Expressões (e):**
    - Números inteiros (`1`, `2`, `3`, ...);
    - Booleanos (`true`, `false`);
    - Operações binárias (`e1 op e2`);
    - Negação lógica (`not e`);
    - If-else (`if e1 then {e2} else {e3}`);
    - Identificador (`x`);
    - Função (`fn x: T => {e}`);
    - Aplicação de função (`e1 e2`);
    - Let (`let x: T = e1 in {e2}`);
    - Let recursivo (`let rec f: T1 -> T2 = (fn y: T1 => {e1}) in {e2}`);
    - Atribuição (`e1 := e2`);
    - Captura do valor da memória (`!e`);
    - Alocação de memória (`new e`);
    - Valor vazio (`()`);
    - While (`while e1 do {e2}`);
    - Sentenças separadas (`e1; e2`);
    - Endereço de memória (`l`, só em runtime).

*Obs1*: `op` pertence ao conjunto `{+, -, *, /, &&, ||, =, !=, <, <=, >, >=}`.
`==` é aceito como sinônimo de `=`.
*Obs2*: `l` (Locations) são endereços de memória; não são escritos pelo programador.
*Obs3*: os corpos de `if`/`else`, `let ... in`, `while ... do` e `fn` ficam
entre chaves `{ }`.

- **Valores (v):** inteiros, booleanos, `()`, funções (`fn x:T => {e}`) e endereços (`l`).

- **Tipos (T):** `int`, `bool`, `unit`, `ref T`, e função `T1 -> T2`.

A *semântica operacional small-step* e o *sistema de tipos* seguem a
especificação da linguagem (avaliação por substituição, call-by-value; `let rec`
por desdobramento).

## Escolhas para o trabalho
- Compilação com [Dune](https://dune.build/).
- Scanner com **ocamllex** (`lib/lexer.mll`).
- Parser com **menhir** (`lib/parser.mly`), escrito como uma cascata de
  não-terminais (sem `%left/%right`), sem conflitos.
- Memória (σ) simulada com uma `Hashtbl` + contador de próxima posição livre
  (`lib/mem.ml`): cresce sob demanda, sem limite fixo.
- Comentários `(* ... *)` são suportados.
- Suporte a rastreamento small-step com a flag `--trace`.

## Estrutura de arquivos
```
└── bin                     # ponto de entrada do executável
    ├── dune
    └── main.ml             # pipeline: parse -> typeinfer -> avaliação; erros por fase

└── lib                     # biblioteca do interpretador
    ├── dune                # usa ocamllex e menhir
    ├── ast.ml              # sintaxe abstrata, tipos, string_of_typ/string_of_bop
    ├── lexer.mll           # regras léxicas (tokens)
    ├── parser.mly          # regras sintáticas (gera a AST)
    ├── mem.ml              # memória σ (Hashtbl + bump-pointer)
    ├── typeInfer.ml        # inferência/checagem de tipos (Γ, lookup/update)
    ├── eval.ml             # avaliador small-step por substituição + eval_trace
    └── pp.ml               # pretty-printer em sintaxe de superfície

└── test
    ├── dune
    ├── test_l2.ml          # suíte automatizada (dune test): 49 casos
    ├── testScanner.ml      # ferramenta manual para inspecionar tokens
    └── t*.txt              # programas de exemplo em L2
```

## Como rodar

Rodar o interpretador em um arquivo:
```bash
dune exec lp1_tf test/t14.txt
```

Com rastreamento small-step (imprime cada passo de redução):
```bash
dune exec lp1_tf -- --trace test/t14.txt
```

Rodar a suíte de testes automatizada:
```bash
dune test
```

Inspecionar apenas os tokens gerados (debug do scanner):
```bash
dune exec test/testScanner.exe -- test/t14.txt
```

## Especificação dos testes (arquivos .txt)
- `t1.txt`: let com soma
- `t2.txt`: soma com let
- `t3.txt`: soma e multiplicação
- `t4.txt`: subtração (resultado negativo)
- `t5.txt`: let com alocação, atribuição e deref
- `t6.txt`: divisão por zero (erro de execução tratado: `[exec] ...`)
- `t7.txt`: atribuição + if
- `t8.txt`: (ERRO de tipo) identificador não declarado
- `t9.txt`: (ERRO sintático) `: =` separado
- `t10.txt`: `while true` com alocação — **diverge** (laço infinito). Com a
  memória agora ilimitada, não é mais erro de "memória cheia"; não faz parte da
  suíte automatizada.
- `t11.txt`: atribuições sucessivas
- `t12.txt`: (ERRO de tipo) ramos do if com tipos diferentes
- `t13.txt`: (ERRO de tipo) while com corpo não-unit
- `t14.txt`: fatorial imperativo de 6 (= 720)
- `t15.txt`: fatorial imperativo (variação)
- `t16.txt`: fatorial recursivo com `let rec` e `fn` (= 120)
- `t17.txt`: função de primeira classe e aplicação (dobro de 21 = 42)
- `t18.txt`: closure sobre estado mutável (contador, = 3)
