# FECHO! v0.8

Jogo de cartas para um humano contra IA, escrito em Lua e LÖVE 11.x. Associe personagens, troque sua carta ou blefe. A força da associação decide o confronto; os pontos da aposta decidem a partida. Ganha quem alcançar 12 pontos.

## Executar

Instale o LÖVE 11.x (validação realizada com 11.5) e, na pasta do projeto, execute:

```sh
love .
```

No Windows, com o LÖVE instalado, use `love.exe .` no terminal ou arraste a pasta do projeto sobre `love.exe`. O jogo não exige Lua instalado separadamente, imagens, fontes, internet ou bibliotecas extras. O executável do LÖVE não faz parte do repositório.

## Controles

| Tecla | Ação |
|---|---|
| Enter | Iniciar, próxima rodada ou jogar novamente |
| C | Comprar uma carta |
| 1 / 2 | Conservar a primeira / segunda carta após comprar |
| P | Passar |
| F | FECHO ou aumentar a aposta |
| A / R | Aceitar / recuar |
| H | Consultar regras e associações dos personagens; pausa a partida |
| Esc | Fechar ajuda ou voltar ao menu |

Todo o fluxo funciona com o mouse, incluindo ajuda, escolha da associação e retorno ao menu. Passe o cursor sobre as cartas para destacá-las e clique diretamente na associação que deseja manter. Os atalhos acima continuam disponíveis, mas não aparecem permanentemente na interface. Selecione Fácil, Normal ou Difícil no menu. Voltar ao menu e iniciar outra partida descarta a partida anterior. A janela redimensiona a mesa de referência de 1280 × 720 preservando a proporção e usando filtro de vizinho mais próximo.

## Regras implementadas

- Dois personagens distintos, sorteados entre seis completos; os treze incompletos permanecem cadastrados e desabilitados.
- Baralho reconstruído a cada rodada: 20 cartas físicas, com duas cópias das associações de força 10 e 8 e uma das forças 5 e 3 para cada personagem.
- Associações compartilhadas usam o máximo de cópias necessário. Distrações distintas vêm do catálogo e não pontuam para nenhum dos personagens. Portugal e Ex-Portugal têm identificadores independentes.
- Compras ilimitadas, uma ação por turno: comprar zera a sequência de passes; escolher a carta encerra o turno. No próximo turno, é possível comprar novamente. A outra carta é descartada em segredo.
- O monte começa com 18 cartas e é finito. Descartes ficam fora da rodada e nunca retornam ao monte. Quando o monte termina, comprar fica indisponível; passar e desafiar continuam possíveis. Um novo baralho só é construído na próxima rodada.
- A primeira compra concluída é livre. A segunda ativa o **comprometimento**: o jogador não pode recuar diante do FECHO inicial de 3 pontos, mas pode aceitar ou aumentar para REFECHO. Nas apostas de 6 e 9 pontos, pode recuar normalmente. Compras adicionais não aumentam a penalidade. O comprometimento termina junto com a rodada.
- Dois passes consecutivos revelam as cartas por 1 ponto. A iniciativa alterna por rodada.
- FECHO / REFECHO / FECHO FINAL propõem 3 / 6 / 9 pontos. Aceitar revela imediatamente; recuar concede 1 / 3 / 6 ao desafiante. Não há compras depois do primeiro desafio.
- Empate acumula a aposta no pote. Vitória revelada entrega aposta e pote. Recuo preserva o pote e mantém a mão adversária oculta.
- Fim aos 12 pontos ou mais, tela de resultado e reinício sem fechar o aplicativo.

Os nomes das associações são referências internas do jogo, não afirmações factuais sobre pessoas reais.

## Organização

```text
main.lua                         callbacks e coordenação da aplicação
conf.lua                         janela e configuração do LÖVE
README.md
 dados/
   personagens.lua               cadastro e habilitação
   associacoes.lua               identidade lógica e nomes das cartas
   relacoes.lua                  personagem, associação e força
 nucleo/
   regras.lua                    validação do cadastro e cálculo de força
   baralho.lua                   composição, distrações e cópias físicas
   apostas.lua                   níveis e valores
   partida.lua                   máquina de estados, ações e visão privada
 ia/
   inteligencia_artificial.lua   probabilidades, risco e três dificuldades
 interface/
   menu.lua                      início e dificuldade
   mesa.lua                      mesa, ações e ajuda
   carta.lua                     cartas 5:7 e carregamento de PNG
   disposicao.lua                mãos centralizadas, coordenadas e áreas de clique
   botoes.lua                    desenho e interação por mouse
   animacoes.lua                 entrada, descarte, destaque e revelação
   resultados.lua                resultado da rodada e da partida
 utilitarios/
   embaralhamento.lua            Fisher–Yates e gerador com semente
 testes/
   apoio.lua
   executar.lua
   testar_baralho.lua
   testar_regras.lua
   testar_apostas.lua
   testar_compras.lua             compras repetidas e monte finito
   testar_comprometimento.lua     restrições, contra-blefes e histórico
   testar_ia.lua                  blefes, perfil e decisões válidas
   testar_interface.lua           proporção, posições e interpolação
   simular_partidas.lua
   resultados_simulacao.txt
   resultados_perfis.txt
   estrategias.lua               perfis usados nas simulações
   VALIDACAO.md
   validar_interface/
     main.lua                    ensaio gráfico automatizado
     conf.lua
 recursos/
   imagens/
   fontes/
   sons/
```

O núcleo não importa `love`. `partida.agir(partida, jogador, acao)` valida os comandos antes de modificar o estado. `partida.visao(partida, jogador)` produz uma cópia limitada, sem mão adversária, ordem do monte, descartes adversários ou índice conservado. Essa separação permite reaproveitar as regras em um servidor futuro; transporte, autenticação e sincronização de rede não estão implementados.

A IA recebe somente essa visão e o cadastro público. Fácil acrescenta decisões subótimas e blefa ocasionalmente; Normal estima chances e retorno de novas compras; Difícil adapta os blefes às frequências públicas de recuo, aceitação e aumento. As três dificuldades consideram placar, aposta e pote. Há blefes com força 0 ou 3 em FECHO, REFECHO e, raramente, FECHO FINAL.

A compra considera o ganho esperado de força, as cartas restantes, o custo de ceder o turno e o risco de se comprometer na segunda compra, ponderado pelo pote, placar e agressividade pública do adversário. A aposta estima as respostas possíveis: a chance de recuo inicial de um adversário comprometido é exatamente zero. Contra-blefes com uma mão ruim comparam o valor esperado de aumentar com o de aceitar; o recuo só é escolhido quando consta nas ações permitidas. O monte finito impede ciclos indefinidos de compras. São heurísticas aproximadas, sem APIs externas e sem garantias de vantagem em toda amostra. O gerador de decisões é independente do gerador que embaralha as cartas.

## Testar e simular

Na raiz, usando Lua ou LuaJIT:

```sh
lua testes/executar.lua
luajit testes/executar.lua
lua testes/simular_partidas.lua 300 20261010
lua testes/simular_partidas.lua 200 20261010 perfis
```

O primeiro argumento da simulação é a quantidade **por confronto ordenado** entre dificuldades: 300 produz 2.700 partidas. O segundo é a semente. O terceiro argumento opcional `perfis` compara conservadora, agressiva, blefadora e adaptativa em 16 confrontos ordenados; 200 produz 3.200 partidas. Esses perfis são políticas de teste sobre a mesma visão limitada, não opções adicionais do menu. A simulação verifica ações válidas, término e conservação das vinte cartas a cada ação. Também executa 200.000 amostras independentes de dois sorteios sem reposição para comparar com a referência combinatória.

Ensaio gráfico, com LÖVE e uma sessão gráfica disponíveis:

```sh
love testes/validar_interface
```

Ele usa exclusivamente cliques: inicia a partida, compra duas vezes na mesma rodada, verifica o destaque da carta, seleciona diretamente as associações, abre e fecha a ajuda, joga até o fim, reinicia e volta ao menu. Exercita 800 × 450, 960 × 540, 1280 × 720, 1920 × 1080 e 1600 × 1000. Encerra com código zero e salva capturas na pasta de dados `fecho_validacao` do LÖVE. Usa uma semente fixa, um adversário dirigido para exercitar duas compras, FECHO contra comprometido e FECHO FINAL após um contra-aumento. Depois restaura a IA de produção. Também verifica que botões habilitados correspondem às ações do motor e que o atalho de recuo não contorna o comprometimento.

Resultados medidos e limites da validação estão em [testes/VALIDACAO.md](testes/VALIDACAO.md), com saída completa em [testes/resultados_simulacao.txt](testes/resultados_simulacao.txt).

## Estado e transparência da v0.8

O motor preserva sua organização em arrays por participante: `quantidade_compras_rodada[jogador]` e `esta_comprometido[jogador]` representam os novos atributos; `personagens[jogador]` e `maos[jogador][1]` continuam sendo as fontes únicas do personagem e da associação atual. Não há cópias paralelas desses dados. O limite está em `regras.COMPRAS_PARA_COMPROMETIMENTO` e a restrição é aplicada por `partida.pode_recuar` e pela lista de ações aceitas pelo motor.

A contagem só aumenta depois da escolha da carta conservada. O histórico público registra compras, passes, comprometimento, FECHO, REFECHO, FECHO FINAL, aceitação, recuo, empate e vitória revelada, sem conteúdo de cartas ou índice conservado. A quantidade restante no monte, os contadores de compras e o comprometimento são informações públicas fornecidas à IA.

Passe o mouse sobre COMPRAR antes da segunda compra para ver o aviso de risco. O indicador `[!] COMPROMETIDO` aparece para ambos os participantes e informa a restrição. Não há confirmação obrigatória nem penalidade extra depois da segunda compra.

## Editar dados e arte

Cada identificador deve ser único e sem acentos. Uma relação tem `personagem`, `associacao`, `pontos` e pode incluir `justificativa`. Preencha as quatro categorias de um personagem e marque `habilitado = true` para incluí-lo. Cadastros habilitados incompletos, relações inválidas, duplicações e distrações insuficientes produzem erros explícitos.

As cartas são desenhadas com formas e fontes internas. Para experimentar arte própria, adicione `recursos/imagens/<identificador>.png`: o desenho central da carta passa a usar essa imagem, preservando nome e força. Nenhum recurso de terceiros acompanha o projeto.

## Limites desta entrega

A versão é um protótipo jogável completo. Arte final, fonte pixelada dedicada, efeitos sonoros, salvamento de partidas e multiplayer ficam para etapas futuras. Há cartas em leque com proporção 5:7, destaque interpolado ao passar o mouse, compra saindo do monte, reorganização da mão, descarte animado e oculto, partículas nas apostas, transições e virada na revelação. Os resultados mostram forças, pontos conquistados e transferência do pote sem cobrir as cartas. O balanceamento é inicial. Windows é um alvo de compatibilidade, mas a execução gráfica foi validada apenas no Linux.
