local regras = require('nucleo.regras')
local baralho = require('nucleo.baralho')
local apostas = require('nucleo.apostas')
local embaralhamento = require('utilitarios.embaralhamento')
local modulo = {}
local function registrar(partida, jogador, acao)
    partida.historico[#partida.historico + 1] = {jogador = jogador, acao = acao, rodada = partida.numero,
        nivel = (acao == 'fecho' or acao == 'aumentar') and partida.nivel + 1 or partida.nivel}
end
function modulo.iniciar_rodada(partida)
    assert(partida.fase == 'intervalo' or partida.fase == 'inicio', 'A rodada atual ainda não terminou.')
    partida.numero = partida.numero + 1
    local disponiveis = {}
    for indice, personagem in ipairs(partida.cadastro.habilitados) do disponiveis[indice] = personagem.identificador end
    embaralhamento.embaralhar(disponiveis, partida.aleatorio)
    partida.personagens = {disponiveis[1], disponiveis[2]}
    partida.monte = baralho.montar(partida.cadastro, partida.personagens, partida.aleatorio)
    partida.maos = {{table.remove(partida.monte)}, {table.remove(partida.monte)}}
    partida.descartes = {{}, {}}
    partida.quantidade_compras_rodada = {0, 0}
    partida.esta_comprometido = {false, false}
    partida.iniciativa = (partida.numero - 1) % 2 + 1
    partida.turno, partida.fase = partida.iniciativa, 'normal'
    partida.nivel, partida.passes, partida.reveladas = 1, 0, false
    partida.desafiante, partida.resultado = nil, nil
end
function modulo.nova(semente, cadastro)
    local partida = {cadastro = cadastro or regras.carregar(), aleatorio = embaralhamento.gerador(semente),
        placar = {0, 0}, pote = 0, numero = 0, fase = 'inicio', historico = {}}
    modulo.iniciar_rodada(partida)
    return partida
end
local function encerrar(partida, vencedor, pontos, motivo)
    if vencedor then partida.placar[vencedor] = partida.placar[vencedor] + pontos end
    if motivo == 'empate' then registrar(partida, nil, 'empate')
    elseif motivo == 'revelacao' then registrar(partida, vencedor, 'vitoria_revelada') end
    partida.esta_comprometido = {false, false}
    partida.resultado = {vencedor = vencedor, pontos = pontos, motivo = motivo}
    partida.fase = (partida.placar[1] >= 12 or partida.placar[2] >= 12) and 'fim' or 'intervalo'
end
local function revelar(partida)
    partida.reveladas = true
    local forcas = {}
    for jogador = 1, 2 do
        forcas[jogador] = regras.calcular_associacao(partida.cadastro, partida.personagens[jogador], partida.maos[jogador][1].associacao)
    end
    local pote_anterior = partida.pote
    local valor = apostas.valores[partida.nivel]
    if forcas[1] == forcas[2] then
        partida.pote = partida.pote + valor
        encerrar(partida, nil, 0, 'empate')
    else
        local premio = valor + partida.pote
        partida.pote = 0
        encerrar(partida, forcas[1] > forcas[2] and 1 or 2, premio, 'revelacao')
    end
    partida.resultado.forcas = forcas
    partida.resultado.pote_recebido = partida.resultado.vencedor and pote_anterior or 0
end
function modulo.pode_comprar(partida)
    return partida.fase == 'normal' and #partida.monte > 0
end
function modulo.pode_recuar(partida, jogador)
    -- O comprometimento só impede fugir do FECHO inicial. Aumentar a aposta
    -- devolve ao adversário uma decisão e preserva o espaço para contra-blefes.
    return partida.fase == 'desafio' and partida.turno == jogador and
        not (partida.nivel == 2 and partida.esta_comprometido[jogador])
end
local function concluir_compra(partida, jogador)
    partida.quantidade_compras_rodada[jogador] = partida.quantidade_compras_rodada[jogador] + 1
    if not partida.esta_comprometido[jogador] and
        partida.quantidade_compras_rodada[jogador] >= regras.COMPRAS_PARA_COMPROMETIMENTO then
        partida.esta_comprometido[jogador] = true
        registrar(partida, jogador, 'comprometido')
    end
end
function modulo.acoes_disponiveis(partida, jogador)
    if partida.turno ~= jogador then return {} end
    if partida.fase == 'normal' then
        local acoes = {'passar', 'fecho'}
        if modulo.pode_comprar(partida) then acoes[#acoes + 1] = 'comprar' end
        return acoes
    elseif partida.fase == 'escolha' then return {'manter_1', 'manter_2'}
    elseif partida.fase == 'desafio' then
        local acoes = {'aceitar'}
        if modulo.pode_recuar(partida, jogador) then acoes[#acoes + 1] = 'recuar' end
        if partida.nivel < 4 then acoes[#acoes + 1] = 'aumentar' end
        return acoes
    end
    return {}
end
-- Toda entrada passa por este comando; uma futura rede pode reutilizá-lo.
function modulo.agir(partida, jogador, acao)
    local permitida = false
    for _, candidata in ipairs(modulo.acoes_disponiveis(partida, jogador)) do if acao == candidata then permitida = true end end
    if not permitida then return false, 'Ação indisponível neste turno.' end
    registrar(partida, jogador, acao)
    if acao == 'comprar' then
        partida.passes = 0
        partida.maos[jogador][2] = table.remove(partida.monte)
        partida.fase = 'escolha'
    elseif acao == 'manter_1' or acao == 'manter_2' then
        local manter = acao == 'manter_1' and 1 or 2
        partida.descartes[jogador][#partida.descartes[jogador] + 1] = partida.maos[jogador][3 - manter]
        partida.maos[jogador] = {partida.maos[jogador][manter]}
        concluir_compra(partida, jogador)
        partida.fase, partida.turno = 'normal', 3 - jogador
    elseif acao == 'passar' then
        partida.passes = partida.passes + 1
        if partida.passes == 2 then revelar(partida) else partida.turno = 3 - jogador end
    elseif acao == 'fecho' or acao == 'aumentar' then
        partida.nivel = partida.nivel + 1
        partida.desafiante, partida.turno, partida.fase = jogador, 3 - jogador, 'desafio'
    elseif acao == 'aceitar' then revelar(partida)
    elseif acao == 'recuar' then
        -- O pote exige confronto revelado e sobrevive a qualquer recuo.
        encerrar(partida, 3 - jogador, apostas.valores[partida.nivel - 1], 'recuo')
    end
    return true
end
function modulo.visao(partida, jogador)
    local visao = {jogador = jogador, fase = partida.fase, turno = partida.turno, nivel = partida.nivel,
        pote = partida.pote, numero = partida.numero, placar = {partida.placar[1], partida.placar[2]},
        personagens = {partida.personagens[1], partida.personagens[2]}, quantidade_compras_rodada = {partida.quantidade_compras_rodada[1], partida.quantidade_compras_rodada[2]},
        passes = partida.passes, cartas_restantes = #partida.monte,
        esta_comprometido = {partida.esta_comprometido[1], partida.esta_comprometido[2]},
        mao = {}, descartes_proprios = {}, historico = {}, acoes = modulo.acoes_disponiveis(partida, jogador)}
    for indice, carta in ipairs(partida.maos[jogador]) do visao.mao[indice] = carta.associacao end
    for indice, carta in ipairs(partida.descartes[jogador]) do visao.descartes_proprios[indice] = carta.associacao end
    for indice, evento in ipairs(partida.historico) do
        -- A escolha do índice revelaria qual carta foi conservada.
        visao.historico[indice] = {jogador = evento.jogador, rodada = evento.rodada,
            acao = evento.acao:match('^manter') and 'descartar' or
                (evento.acao == 'aumentar' and (evento.nivel == 3 and 'refecho' or 'fecho_final') or evento.acao),
            nivel = evento.nivel}
    end
    return visao
end
return modulo
