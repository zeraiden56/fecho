# Validação — FECHO! v0.8

Ambiente: Arch Linux, Lua 5.5.1, LuaJIT 2.1 e LÖVE 11.5. O projeto existente foi atualizado, preservando suas cartas, dados, turnos, apostas e interface.

## Arquivos alterados ou adicionados

- Motor: `nucleo/partida.lua`, `nucleo/regras.lua`.
- IA: `ia/inteligencia_artificial.lua`.
- Aplicação e interface: `main.lua`, `conf.lua`, `interface/mesa.lua`.
- Testes: `testes/executar.lua`, `testes/testar_compras.lua`, `testes/testar_comprometimento.lua` (novo), `testes/testar_ia.lua`, `testes/testar_regras.lua`, `testes/validar_interface/main.lua`.
- Simulações: `testes/simular_partidas.lua`, `testes/estrategias.lua` (novo), `testes/resultados_simulacao.txt`, `testes/resultados_perfis.txt` (novo).
- Documentação: `README.md`, `testes/VALIDACAO.md`.

## Comandos executados

```sh
lua testes/executar.lua
luajit testes/executar.lua
lua testes/simular_partidas.lua 300 20261010
lua testes/simular_partidas.lua 200 20261010 perfis
love testes/validar_interface
```

**53.513 verificações aprovadas** em cada interpretador. Os testes anteriores de cadastro, composição, sigilo, apostas, pote, geometria e vitória continuam incluídos. Os testes de reciclagem foram substituídos pelos testes de monte finito.

## Comprometimento e baralho

Foram verificados:

- Primeira compra livre; segunda ativa comprometimento somente após escolher a carta; terceira mantém o mesmo estado e não gera outro evento de comprometimento.
- Estado preservado após passar e removido ao encerrar a rodada, inclusive por empate e recuo; próxima rodada começa com contador zero.
- Recuo inicial rejeitado no motor, sem alterar placar ou histórico. Aceitar e aumentar continuam possíveis.
- Recuos permitidos em REFECHO e FECHO FINAL, inclusive quando os dois jogadores estão comprometidos.
- Mesmas restrições para humano e IA. Um atalho não contorna o motor.
- Dezoito compras alternadas, uma por turno, com preservação das mesmas vinte instâncias físicas a cada ação, incluindo a escolha temporária.
- Nenhuma carta descartada retorna à mão ou ao monte. Monte começa em 18 e chega a zero; comprar então é rejeitado, apesar dos 18 descartes existentes.
- Dois passes encerram a rodada; próxima rodada reconstrói o baralho com 18 cartas no monte após distribuir.
- Histórico distingue FECHO, REFECHO e FECHO FINAL e registra comprometimento, empate e vitória revelada sem divulgar cartas.

A matriz de testes cobre os cenários de comprometimento em ambas as posições, além das regras existentes de compras, interrupção de passes, bloqueio de compras após FECHO, entrega/preservação do pote e fim aos 12 pontos.

## Inteligência artificial

Além dos 45.000 casos de decisão com mãos fracas já existentes, foram amostradas respostas de todas as dificuldades quando comprometidas: aceitar e aumentar ocorreram; nenhum recuo inválido ocorreu. Também houve FECHO contra adversário comprometido e alternativas a esse desafio, evitando uma regra automática.

Testes diretos dos cálculos confirmaram:

- Chance de recuo do adversário comprometido igual a **zero** no FECHO inicial.
- Probabilidades de aceitar e aumentar somam 1 nesse caso.
- Nas apostas superiores, o recuo volta a ser um resultado possível.
- Segunda compra tem custo estratégico adicional; sem cartas restantes, retorno da compra é zero.
- Alterar a associação oculta, a ordem do monte e o descarte adversário, preservando informações públicas, não altera as decisões com a mesma semente.

## Simulação entre dificuldades

Semente `20261010`; 300 partidas para cada um dos nove confrontos ordenados: **2.700 partidas**. Saída integral em `resultados_simulacao.txt`.

| Medida | Observado |
|---|---:|
| Rodadas | 22.209 |
| Rodadas médias por partida | 8,226 |
| Compras por rodada, somando os dois jogadores | 1,604 |
| Rodadas com pelo menos um comprometido | 4.702 — 21,17% |
| FECHO contra comprometido | 1.573 — 9,38% dos FECHOS |
| REFECHO como contra-blefe comprometido | 253 — 8,78% dos REFECHOS |
| Rodadas por recuo | 6.897 — 31,05% |
| Empates | 4.645 — 20,91% |
| Pote médio após a rodada | 1,735 |
| Pote máximo | 32 |
| Maior quantidade de ações por partida | 135 |
| Vitória da posição inicial 1 / 2 | 49,15% / 50,85% |

Contra-blefe comprometido significa aumentar de FECHO para REFECHO com força 0 ou 3 e recuo inicial bloqueado. A definição usa a própria mão, não a carta adversária. Uma rodada comprometida é contada mesmo se o estado foi removido no encerramento.

Taxa de vitória da dificuldade da linha, na posição inicial 1:

| Posição 1 / posição 2 | Fácil | Normal | Difícil |
|---|---:|---:|---:|
| Fácil | 49,33% | 48,33% | 42,00% |
| Normal | 51,00% | 49,67% | 46,00% |
| Difícil | 54,00% | 50,33% | 51,67% |

## Simulação entre perfis

Semente `20261010`; 200 partidas por confronto ordenado, total de **3.200 partidas**. Saída integral em `resultados_perfis.txt`.

Os perfis de teste usam somente a visão pública: conservadora reduz desafios fracos; agressiva pressiona com vantagem estimada; blefadora aumenta a propensão a blefes contextuais; adaptativa usa a estratégia Difícil sem modificações. Não são novas dificuldades do menu.

| Medida | Observado |
|---|---:|
| Rodadas médias por partida | 8,258 |
| Compras por rodada | 1,567 |
| Rodadas com comprometimento | 20,25% |
| FECHO contra comprometido | 1.449 — 7,21% dos FECHOS |
| REFECHO como contra-blefe comprometido | 258 — 7,59% dos REFECHOS |
| Rodadas por recuo | 8.264 — 31,27% |
| Empates | 5.340 — 20,21% |
| Pote médio | 1,620 |
| Maior quantidade de ações por partida | 176 |

Comparações com a primeira estratégia na posição inicial 1:

- Conservadora × agressiva: **52,50%** de vitórias da conservadora.
- Blefadora × conservadora: **45,00%** de vitórias da blefadora.
- Adaptativa × blefadora: **55,00%** de vitórias da adaptativa.

As saídas incluem os confrontos inversos e todos os outros pares. Essas amostras sugerem vantagem da adaptação sobre blefes mais frequentes, mas não demonstram equilíbrio definitivo. Nenhuma das 5.900 partidas excedeu o limite de segurança da simulação ou produziu ação inválida ou duplicação de carta.

## Interface real

O ensaio gráfico usa cliques para iniciar, comprar duas vezes na mesma rodada, escolher cartas, abrir ajuda, responder apostas, avançar rodadas, reiniciar e voltar ao menu. Verificou o destaque da carta e exercitou cinco resoluções: 800 × 450, 960 × 540, 1280 × 720, 1920 × 1080 e 1600 × 1000.

O cenário dirigido captura o aviso antes da segunda compra e o indicador após concluí-la. Ao receber FECHO, a interface mostra ACEITAR e REFECHO, sem RECUAR; a tentativa pelo atalho também é rejeitada. Após REFECHO e FECHO FINAL, o recuo pelo mouse funciona sem revelar a carta adversária. Os controles habilitados são comparados com as ações permitidas pelo motor a cada quadro.

Depois desse cenário, a IA de produção é restaurada. A partida terminou em **7 × 20** e o reinício voltou à rodada 1 com placar zerado. Capturas foram salvas no diretório de dados `fecho_validacao` do LÖVE e inspecionadas para verificar aviso, indicadores e botões.

## Problemas corrigidos e limites

- Removida a reciclagem incompatível com a v0.8.
- Contagem movida do início da compra para sua conclusão.
- Removido o recuo da lista de ações quando comprometido no FECHO inicial; a IA não usa mais recuar como alternativa incondicional.
- Estimativa de apostas não atribui ganho por recuo impossível. Estimativa de mãos passou a considerar amostragem sem reposição.
- Ensaio gráfico atualizado para esperar a renderização após mudanças de fase antes de clicar.

As probabilidades continuam sendo heurísticas: a IA não sabe se o adversário conservou a melhor carta, e descartes adversários continuam desconhecidos. Sem validação em Windows nesta execução, áudio ou arte final. O experimento auxiliar de dois sorteios permanece em 52,03150% observado contra 52,105263% teórico; essa referência não representa a taxa de mãos finais das partidas estratégicas.
