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
- "t1.txt": let com soma
- "t2.txt": soma com let
- "t3.txt": soma e multiplicação
- "t4.txt": soma com valores negativos
- "t5.txt": let com alocação, atribuição e deref *
- "t6.txt": divisão por zero
- "t7.txt": teste de atribuição *
- "t8.txt": (ERRO de type infer) atribuição com valor não declarado
- "t9.txt": (ERRO sinatático) atribuição com espaços (": =")
- "t10.txt": while true com alocação — laço infinito (a memória é ilimitada, então o programa roda indefinidamente)
- "t11.txt": teste de atribuição
- "t12.txt": (ERRO de type infer) tipos diferentes do if
- "t13.txt": (ERRO de type infer) while com corpo não-vazio
- "t14.txt": fatorial de 6
- "t15.txt": (ERRO sintático) fatorial com ";" sem segundo op
- "t16.txt": operadores relacionais novos (<=, >=, !=)
- "t17.txt": operador unário not
- "t18.txt": == (sinônimo de =) combinado com != e not
- "t19.txt": comentários (* ... *) em várias posições, inclusive multilinha