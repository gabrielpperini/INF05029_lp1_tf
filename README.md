# Trabalho Final da Cadeira de LP1 (Linguagens de Programação 1 )
## Enunciado
O trabalho consiste em desenvolver um scanner, parser, type_infer e avaliador para a linguagem L2 v2, especificada no pdf em anexo.

### Especificação da linguagem L2 v2
- Expressões (e):
    - Números inteiros (1, 2, 3,...);
    - Booleano (true, false);
    - Operações binárias (e1 op e2);
    - Negação lógica (not e);
    - If-else (if e1 then {e2} else {e3});
    - Identificador (x);
    - Let (let x: T = e1 in {e2});
    - Atribuição (x := e);
    - Captura do valor da memória (!e);
    - Alocação de memória (new e);
    - Valor vazio ( () );
    - While (while e1 do {e2});
    - Sentenças separadas (e1; e2)
    - Endereço de memória (l).
*Obs1*: e (e1, e2...) representam expressões qualquer.
*Obs2*: op pertence ao conjunto {+, -, *, /, &&, ||, =, ==, !=, <, <=, >, >=}. O operador == é sinônimo de =, e not é o operador unário de negação lógica.
*Obs3*: l pertence ao conjunto de Locations, que são localizações/endereços de memória.
*Obs4*: l's não são usados é usado pelo programador.

- Valores (v)
    - Números inteiros (1, 2, 3,...);
    - Booleano (true, false);
    - Valor vazio ( () );
    - Endereço de memória (l).

- Tipos (T)
    - Inteiro (int);
    - Booleano (bool);
    - Referência para um tipo (ref T);
    - Vazio (unit).

A *semântica operacional small-step* está identificada no pdf da especificação do trabalho.


## Escolhas para o trabalho
- Para compilar os arquivos OCaml juntos, foi usado a biblioteca [Dune](https://dune.build/)
- Para o scanner, foi utilizada a biblioteca ocamllex a partir do arquivo de configurações `lexer.mll`.
- Para o parser, foi utilizada a biblioteca menhir a partir do arquivo de configurações `parser.mly` e `ast.ml`.
- Para simular a memória, foi usada uma Hashtbl com um contador da próxima posição livre (bump-pointer): a memória cresce sob demanda, sem limite fixo de posições;
- Comentários no estilo `(* ... *)` são reconhecidos e ignorados pelo lexer (podem aparecer em qualquer posição e abranger várias linhas);
- Para atribuições, o lado esquerdo podem ser expressões de acordo com o parser, mas o typeinfer se certifica que essa expressão é um identificador. 
Leia a estrutura de arquivos para saber o que cada um faz.



## Estrutura de arquivos
```
└── bin                     # arquivos de entrada do projeto
    ├── dune                    # arquivo de configuração dune com o nome do projeto e o arquivo de entrada (main)
    ├── eval.ml                 # código OCaml com o avaliador semantico de L2
    ├── main.ml                 # arquivo principal onde são chamados as etapas do processo
    └── typeInfer.ml            # código OCaml com o inferência de tipos de L2
   
└── lib                     # arquivos da biblioteca do projeto
    ├── ast.ml                  # arquivo onde é definida as expressões, operações e tipos da linguagem
    ├── dune                    # arquivo de configuração das bibliotecas, aqui é dito que é usado OCAMLLEX e MENHIR
    ├── lexer.mll               # nesse arquivo, são definida as regras léxicas da linguagem, como serão gerados os tokens a partir do expressões regulares
    ├── mem.ml                  # arquivo que define funcionamento e declara a memória do avaliador
    └── parser.mly              # nesse arquivo, são definidas as regras sintáticas das linguagem, como serão interpretados os tokens para gerar a AST

└── test                    # aqui estão os arquivos de teste, incluindo todos os .txt com códigos em L2
    └── testScanner.ml          #  arquivo para testar apenas a parte sintática, ver quais tokens são gerados para um arquivo

```

## Como rodar o trabalho
- Rodando todas as etapas
A main roda um teste específico a partir do que for dado como entrada. O arquivo de entrada deve ser um .txt com o código a ser interpretado.
Rodando um teste específico:
```bash
dune exec lp1_tf <caminho_arquivo_txt>
```

- Rodando apenas o scanner 
Para debugging, se você quiser ver quais tokens serão gerados para um teste (arquivo .txt), basta fazer assim:
```bash
dune exec test/testScanner.exe <caminho_arquivo_txt>
```


## Especificação dos testes

A coluna **Resultado** traz a saída obtida ao rodar `dune exec lp1_tf test/<arquivo>`.
Os testes marcados como *(ERRO ...)* são casos negativos, cuja saída esperada é
justamente a mensagem de erro da fase correspondente (sintático ou de tipo).

| Arquivo | Descrição | Resultado |
|---|---|---|
| t1.txt  | let com soma | `Int 13` |
| t2.txt  | soma com let | `Int 20` |
| t3.txt  | soma e multiplicação | `Int 15` |
| t4.txt  | subtração com resultado negativo | `Int -2` |
| t5.txt  | let com alocação, atribuição e deref | `Bool true` |
| t6.txt  | divisão por zero | `Erro de execução: divisão por zero` |
| t7.txt  | atribuição + condicional sobre deref | `Bool false` |
| t8.txt  | (ERRO de tipo) atribuição a identificador não declarado | `Erro de tipo: identificador x nao foi declarado` |
| t9.txt  | (ERRO sintático) atribuição com espaço no operador (`": ="`) | `Erro de Sintaxe: na linha 1, coluna 2` |
| t10.txt | while true com alocação — **diverge** (laço infinito; memória ilimitada) | *não termina* |
| t11.txt | atribuições sucessivas + comparação | `Bool true` |
| t12.txt | (ERRO de tipo) ramos then/else de tipos diferentes | `Erro de tipo: tipos de expressoes then e else devem ser iguais` |
| t13.txt | (ERRO de tipo) corpo do while não é unit | `Erro de tipo: corpo do while deve ser do tipo unit` |
| t14.txt | fatorial de 6 (via while + refs) | `Int 720` |
| t15.txt | (ERRO sintático) `;` sem segundo operando | `Erro de Sintaxe: na linha 7, coluna 13` |
| t16.txt | operadores relacionais novos (`<=`, `>=`, `!=`) | `Bool true` |
| t17.txt | operador unário `not` | `Int 10` |
| t18.txt | `==` (sinônimo de `=`) combinado com `!=` e `not` | `Bool true` |
| t19.txt | comentários `(* ... *)` em várias posições, inclusive multilinha | `Int 30` |

> **t10** roda indefinidamente por definição (a memória cresce sob demanda, sem
> limite), então não deve ser incluído em rodagens automatizadas — é o exemplo de
> divergência (não-terminação) da linguagem.