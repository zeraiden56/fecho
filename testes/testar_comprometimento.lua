local apoio = require('testes.apoio')
local motor = require('nucleo.partida')
local inteligencia = require('ia.inteligencia_artificial')
local regras = require('nucleo.regras')
local gerador = require('utilitarios.embaralhamento').gerador
local function comprar(partida, jogador)
    apoio.verdadeiro(motor.agir(partida, jogador, 'comprar'))
    apoio.verdadeiro(motor.agir(partida, jogador, 'manter_1'))
end
local function preparar(quantidade, jogador)
    local partida = motor.nova(17)
    partida.turno = jogador
    for indice = 1, quantidade do
        comprar(partida, jogador)
        if indice < quantidade then motor.agir(partida, 3 - jogador, 'passar') end
    end
    return partida
end
apoio.igual(regras.COMPRAS_PARA_COMPROMETIMENTO, 2)
for jogador = 1, 2 do
    local partida = preparar(1, jogador)
    apoio.igual(partida.esta_comprometido[jogador], false)
    motor.agir(partida, 3 - jogador, 'passar')
    motor.agir(partida, jogador, 'comprar')
    apoio.igual(partida.esta_comprometido[jogador], false)
    apoio.igual(partida.quantidade_compras_rodada[jogador], 1)
    motor.agir(partida, jogador, 'manter_1')
    apoio.igual(partida.esta_comprometido[jogador], true)
    motor.agir(partida, 3 - jogador, 'passar')
    comprar(partida, jogador)
    apoio.igual(partida.quantidade_compras_rodada[jogador], 3)
    apoio.igual(partida.esta_comprometido[jogador], true)
    local compromissos = 0
    for _, evento in ipairs(partida.historico) do if evento.acao == 'comprometido' then compromissos = compromissos + 1 end end
    apoio.igual(compromissos, 1)
    comprar(partida, 3 - jogador)
    motor.agir(partida, jogador, 'passar')
    apoio.igual(partida.esta_comprometido[jogador], true)
    motor.agir(partida, 3 - jogador, 'fecho')
    apoio.igual(motor.pode_recuar(partida, jogador), false)
    local tamanho_historico = #partida.historico
    apoio.verdadeiro(not motor.agir(partida, jogador, 'recuar'))
    apoio.igual(#partida.historico, tamanho_historico)
    apoio.igual(partida.placar[1] + partida.placar[2], 0)
    apoio.verdadeiro(motor.agir(partida, jogador, 'aceitar'))
    apoio.igual(partida.esta_comprometido[1], false)
    apoio.igual(partida.esta_comprometido[2], false)
    motor.iniciar_rodada(partida)
    apoio.igual(partida.quantidade_compras_rodada[jogador], 0)
    apoio.igual(partida.esta_comprometido[jogador], false)
    partida = preparar(1, jogador)
    motor.agir(partida, 3 - jogador, 'fecho')
    apoio.verdadeiro(motor.pode_recuar(partida, jogador))
    apoio.verdadeiro(motor.agir(partida, jogador, 'recuar'))
    partida = preparar(2, jogador)
    motor.agir(partida, 3 - jogador, 'fecho')
    apoio.verdadeiro(motor.agir(partida, jogador, 'aumentar'))
    apoio.verdadeiro(motor.pode_recuar(partida, 3 - jogador))
    motor.agir(partida, 3 - jogador, 'aumentar')
    apoio.verdadeiro(motor.pode_recuar(partida, jogador))
    apoio.verdadeiro(motor.agir(partida, jogador, 'recuar'))
    apoio.igual(partida.placar[3 - jogador], 6)
    apoio.igual(partida.reveladas, false)
end
local partida = motor.nova(22)
for _ = 1, 4 do comprar(partida, partida.turno) end
apoio.verdadeiro(partida.esta_comprometido[1] and partida.esta_comprometido[2])
motor.agir(partida, 1, 'fecho')
apoio.verdadeiro(not motor.pode_recuar(partida, 2))
motor.agir(partida, 2, 'aumentar')
apoio.verdadeiro(motor.pode_recuar(partida, 1))
local historico = motor.visao(partida, 1).historico
apoio.igual(historico[#historico].acao, 'refecho')
motor.agir(partida, 1, 'aumentar')
historico = motor.visao(partida, 2).historico
apoio.igual(historico[#historico].acao, 'fecho_final')
motor.agir(partida, 2, 'recuar')
apoio.igual(partida.esta_comprometido[1], false)
for _, dificuldade in ipairs({'facil', 'normal', 'dificil'}) do
    local jogo = apoio.preparar(0, 8)
    jogo.quantidade_compras_rodada[1], jogo.esta_comprometido[1], jogo.turno = 2, true, 2
    motor.agir(jogo, 2, 'fecho')
    local visao = motor.visao(jogo, 1)
    local aceitar, aumentar, aleatorio = 0, 0, gerador(901)
    for _ = 1, 1200 do
        local acao = inteligencia.decidir_jogada_ia(visao, jogo.cadastro, dificuldade, aleatorio)
        apoio.verdadeiro(acao == 'aceitar' or acao == 'aumentar', 'IA comprometida tentou recuar')
        if acao == 'aceitar' then aceitar = aceitar + 1 else aumentar = aumentar + 1 end
    end
    apoio.verdadeiro(aceitar > 0 and aumentar > 0, 'Contra-blefe sem variação')
    jogo = apoio.preparar(3, 0)
    jogo.esta_comprometido[2], jogo.quantidade_compras_rodada[2] = true, 2
    visao = motor.visao(jogo, 1)
    local avaliacao = inteligencia.avaliar_aposta(visao, jogo.cadastro, dificuldade, 2)
    apoio.igual(avaliacao.probabilidade_recuo, 0)
    apoio.verdadeiro(math.abs(avaliacao.probabilidade_aceite + avaliacao.probabilidade_aumento - 1) < 0.000001)
    apoio.verdadeiro(inteligencia.avaliar_aposta(visao, jogo.cadastro, dificuldade, 3).probabilidade_recuo > 0)
    local fechos, outras = 0, 0
    for _ = 1, 1200 do
        local acao = inteligencia.decidir_jogada_ia(visao, jogo.cadastro, dificuldade, aleatorio)
        if acao == 'fecho' then fechos = fechos + 1 else outras = outras + 1 end
    end
    apoio.verdadeiro(fechos > 0 and outras > 0, 'Pressão contra comprometido virou regra fixa')
end
local jogo = apoio.preparar(0, 8)
jogo.quantidade_compras_rodada[1] = 1
local visao = motor.visao(jogo, 1)
local antes = inteligencia.avaliar_compra(visao, jogo.cadastro, 0)
visao.esta_comprometido[1] = true
apoio.verdadeiro(inteligencia.avaliar_compra(visao, jogo.cadastro, 0) > antes, 'Segunda compra ignora o risco adicional')
visao.cartas_restantes = 0
apoio.igual(inteligencia.avaliar_compra(visao, jogo.cadastro, 0), 0)
local empate = apoio.preparar(0, 0)
empate.esta_comprometido = {true, true}
motor.agir(empate, 1, 'passar'); motor.agir(empate, 2, 'passar')
apoio.igual(empate.historico[#empate.historico].acao, 'empate')
apoio.igual(empate.esta_comprometido[1], false)
local vitoria = apoio.preparar(10, 0)
motor.agir(vitoria, 1, 'passar'); motor.agir(vitoria, 2, 'passar')
apoio.igual(vitoria.historico[#vitoria.historico].acao, 'vitoria_revelada')
print('Comprometimento, contra-blefes, histórico e probabilidades de resposta: OK')
