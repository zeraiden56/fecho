local apoio = require('testes.apoio')
local motor = require('nucleo.partida')
local inteligencia = require('ia.inteligencia_artificial')
local gerador = require('utilitarios.embaralhamento').gerador
local function preparar(forca, nivel)
    local partida = apoio.preparar(forca, 8)
    if nivel then
        partida.turno = 2
        motor.agir(partida, 2, 'fecho')
        if nivel == 3 then motor.agir(partida, 1, 'aumentar'); motor.agir(partida, 2, 'aumentar'); partida.nivel = 3; partida.turno = 1 end
    end
    return partida
end
for _, dificuldade in ipairs({'facil', 'normal', 'dificil'}) do
    local acoes = {fecho = 0, aumentar = 0, recuar = 0, comprar = 0, passar = 0, final = 0}
    local aleatorio = gerador(2026)
    for _, forca in ipairs({0, 3}) do
        for _, nivel in ipairs({1, 2, 3}) do
            local partida = preparar(forca, nivel > 1 and nivel or nil)
            local visao = motor.visao(partida, 1)
            for _ = 1, 2500 do
                local acao = inteligencia.decidir_jogada_ia(visao, partida.cadastro, dificuldade, aleatorio)
                local valida = false
                for _, candidata in ipairs(visao.acoes) do if candidata == acao then valida = true end end
                apoio.verdadeiro(valida, 'Ação inválida na IA')
                if acoes[acao] then acoes[acao] = acoes[acao] + 1 end
                if nivel == 3 and acao == 'aumentar' then acoes.final = acoes.final + 1 end
            end
        end
    end
    for _, acao in ipairs({'fecho', 'aumentar', 'recuar', 'comprar', 'passar', 'final'}) do
        apoio.verdadeiro(acoes[acao] > 0, dificuldade..' não exercitou '..acao)
    end
end
local partida = preparar(0)
local visao = motor.visao(partida, 1)
local function perfil(acao)
    visao.historico = {}
    for rodada = 1, 20 do visao.historico[#visao.historico + 1] = {jogador = 2, acao = acao, rodada = rodada} end
    visao.numero = 21
    return inteligencia.estimar_perfil(visao)
end
local recua, aceita = perfil('recuar'), perfil('aceitar')
apoio.verdadeiro(inteligencia.probabilidade_blefe(visao, recua, 'dificil') > inteligencia.probabilidade_blefe(visao, aceita, 'dificil') * 2)
local ganho_inicial = inteligencia.avaliar_compra(visao, partida.cadastro, 0)
visao.quantidade_compras_rodada[1] = 30
apoio.verdadeiro(inteligencia.avaliar_compra(visao, partida.cadastro, 0) < ganho_inicial / 10)
-- O adversário acompanha as compras, mas aceita o encerramento quando a IA
-- passa ou desafia. Um humano que insiste em comprar pode prolongar a rodada.
for _, dificuldade in ipairs({'facil', 'normal', 'dificil'}) do
    for semente = 1, 60 do
        local jogo = motor.nova(semente)
        local aleatorio, passos = gerador(semente + 9), 0
        while jogo.fase ~= 'intervalo' and jogo.fase ~= 'fim' do
            local acao
            if jogo.turno == 1 then acao = inteligencia.decidir_jogada_ia(motor.visao(jogo, 1), jogo.cadastro, dificuldade, aleatorio)
            elseif jogo.fase == 'escolha' then acao = 'manter_1'
            elseif jogo.fase == 'desafio' then acao = 'aceitar'
            else acao = (jogo.passes > 0 or not motor.pode_comprar(jogo)) and 'passar' or 'comprar' end
            apoio.verdadeiro(motor.agir(jogo, jogo.turno, acao))
            passos = passos + 1
            assert(passos < 3000, 'Estratégia entrou em ciclo de compras')
        end
    end
end
print('IA: compras, blefes fracos nos três níveis, recuos, adaptação e término: OK')
