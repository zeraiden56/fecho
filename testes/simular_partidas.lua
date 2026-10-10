local motor = require('nucleo.partida')
local inteligencia = require('ia.inteligencia_artificial')
local regras = require('nucleo.regras')
local embaralhamento = require('utilitarios.embaralhamento')
local quantidade = tonumber(arg[1]) or 300
local semente = tonumber(arg[2]) or 20261010
assert(quantidade >= 1 and quantidade == math.floor(quantidade), 'Informe uma quantidade inteira positiva.')
local cadastro = regras.carregar()
local comparar_perfis = arg[3] == 'perfis'
local dificuldades = comparar_perfis and {'conservadora', 'agressiva', 'blefadora', 'adaptativa'} or {'facil', 'normal', 'dificil'}
local decidir = comparar_perfis and require('testes.estrategias').decidir or inteligencia.decidir_jogada_ia
local estatisticas = {partidas = 0, rodadas = 0, recuos = 0, empates = 0, soma_pote = 0, maximo_pote = 0,
    compras = 0, blefes = 0, blefes_refecho = 0, blefes_final = 0, rodadas_comprometidas = 0, fechos_comprometidos = 0, contra_blefes = 0, maximo_decisoes = 0,
    vitorias_primeiro = 0, fecho = 0, aumentar = 0, refecho = 0, final = 0, forcas = {[0]=0, [3]=0, [5]=0, [8]=0, [10]=0}}
local function simular(primeira, segunda, numero)
    local partida = motor.nova(semente + numero * 97, cadastro)
    local aleatorio = embaralhamento.gerador(semente + numero * 977 + 13)
    local decisoes, rodadas = 0, 0
    while partida.fase ~= 'fim' do
        local rodada_comprometida = false
        while partida.fase ~= 'intervalo' and partida.fase ~= 'fim' do
            local jogador = partida.turno
            local acao = decidir(motor.visao(partida, jogador), cadastro, jogador == 1 and primeira or segunda, aleatorio)
            local forca_antes = regras.calcular_associacao(cadastro, partida.personagens[jogador], partida.maos[jogador][1].associacao)
            if acao == 'fecho' and partida.esta_comprometido[3 - jogador] then estatisticas.fechos_comprometidos = estatisticas.fechos_comprometidos + 1 end
            if acao == 'aumentar' and partida.nivel == 2 and partida.esta_comprometido[jogador] and forca_antes <= 3 then
                estatisticas.contra_blefes = estatisticas.contra_blefes + 1
            end
            assert(motor.agir(partida, jogador, acao), 'A IA propôs ação inválida.')
            rodada_comprometida = rodada_comprometida or partida.esta_comprometido[1] or partida.esta_comprometido[2]
            if acao == 'comprar' then estatisticas.compras = estatisticas.compras + 1 end
            if forca_antes <= 3 then
                if acao == 'fecho' then estatisticas.blefes = estatisticas.blefes + 1 end
                if acao == 'aumentar' then
                    local chave = partida.nivel == 3 and 'blefes_refecho' or 'blefes_final'
                    estatisticas[chave] = estatisticas[chave] + 1
                end
            end
            decisoes = decisoes + 1
            assert(decisoes < 20000, 'Partida sem término.')
            if acao == 'fecho' then estatisticas.fecho = estatisticas.fecho + 1 end
            if acao == 'aumentar' then
                local chave = partida.nivel == 3 and 'refecho' or 'final'
                estatisticas[chave] = estatisticas[chave] + 1
            end
            -- Conservação das vinte cartas, inclusive durante a escolha.
            local fisicos, total = {}, 0
            local function conferir(cartas)
                for _, carta in ipairs(cartas) do
                    assert(not fisicos[carta.fisico], 'Carta física duplicada durante partida.')
                    fisicos[carta.fisico], total = true, total + 1
                end
            end
            conferir(partida.monte)
            for indice = 1, 2 do conferir(partida.maos[indice]); conferir(partida.descartes[indice]) end
            assert(total == 20, 'Carta física perdida durante partida.')
        end
        if rodada_comprometida then estatisticas.rodadas_comprometidas = estatisticas.rodadas_comprometidas + 1 end
        rodadas = rodadas + 1
        estatisticas.rodadas = estatisticas.rodadas + 1
        if partida.resultado.motivo == 'recuo' then estatisticas.recuos = estatisticas.recuos + 1 end
        if partida.resultado.motivo == 'empate' then estatisticas.empates = estatisticas.empates + 1 end
        estatisticas.soma_pote = estatisticas.soma_pote + partida.pote
        estatisticas.maximo_pote = math.max(estatisticas.maximo_pote, partida.pote)
        for jogador = 1, 2 do
            local forca = regras.calcular_associacao(cadastro, partida.personagens[jogador], partida.maos[jogador][1].associacao)
            estatisticas.forcas[forca] = estatisticas.forcas[forca] + 1
        end
        if partida.fase ~= 'fim' then motor.iniciar_rodada(partida) end
    end
    estatisticas.maximo_decisoes = math.max(estatisticas.maximo_decisoes, decisoes)
    estatisticas.partidas = estatisticas.partidas + 1
    local primeiro_venceu = partida.placar[1] >= 12
    if primeiro_venceu then estatisticas.vitorias_primeiro = estatisticas.vitorias_primeiro + 1 end
    return primeiro_venceu
end
print(string.format('Semente: %d | %d partidas por confronto ordenado', semente, quantidade))
for _, primeira in ipairs(dificuldades) do
    for _, segunda in ipairs(dificuldades) do
        local vitorias = 0
        for _ = 1, quantidade do
            if simular(primeira, segunda, estatisticas.partidas + 1) then vitorias = vitorias + 1 end
        end
        print(string.format('%s × %s: posição 1 venceu %.2f%% (%d/%d)', primeira, segunda, 100 * vitorias / quantidade, vitorias, quantidade))
    end
end
print(string.format('Partidas: %d | Rodadas: %d | Média de rodadas: %.3f', estatisticas.partidas, estatisticas.rodadas, estatisticas.rodadas / estatisticas.partidas))
for _, forca in ipairs({0, 3, 5, 8, 10}) do
    print(string.format('Força final %d: %d (%.2f%%)', forca, estatisticas.forcas[forca], 100 * estatisticas.forcas[forca] / (2 * estatisticas.rodadas)))
end
for _, chave in ipairs({'fecho', 'refecho', 'final', 'recuos', 'empates'}) do
    print(string.format('%s: %d (%.2f%% das rodadas)', chave, estatisticas[chave], 100 * estatisticas[chave] / estatisticas.rodadas))
end
print(string.format('Pote ao final de cada rodada: média %.3f; máximo %d', estatisticas.soma_pote / estatisticas.rodadas, estatisticas.maximo_pote))
print(string.format('Vitória por posição inicial: 1 = %.2f%%; 2 = %.2f%%', 100 * estatisticas.vitorias_primeiro / estatisticas.partidas, 100 * (1 - estatisticas.vitorias_primeiro / estatisticas.partidas)))
print(string.format('Compras: %d | Média por rodada: %.3f | Máximo de ações por partida: %d', estatisticas.compras, estatisticas.compras / estatisticas.rodadas, estatisticas.maximo_decisoes))
print(string.format('Rodadas com comprometimento: %d (%.2f%%)', estatisticas.rodadas_comprometidas, 100 * estatisticas.rodadas_comprometidas / estatisticas.rodadas))
print(string.format('FECHO contra comprometido: %d (%.2f%% dos FECHOS; %.2f%% das rodadas)', estatisticas.fechos_comprometidos, 100 * estatisticas.fechos_comprometidos / math.max(1, estatisticas.fecho), 100 * estatisticas.fechos_comprometidos / estatisticas.rodadas))
print(string.format('REFECHO como contra-blefe comprometido (força 0 ou 3): %d (%.2f%% dos REFECHOS)', estatisticas.contra_blefes, 100 * estatisticas.contra_blefes / math.max(1, estatisticas.refecho)))
print(string.format('Desafios com força 0 ou 3: FECHO %d; REFECHO %d; FECHO FINAL %d', estatisticas.blefes, estatisticas.blefes_refecho, estatisticas.blefes_final))
-- Experimento independente da política de compras/blefes dos agentes.
local aleatorio, positivas, amostras = embaralhamento.gerador(semente + 999999), 0, 200000
for _ = 1, amostras do
    local primeira = aleatorio(20)
    local segunda = aleatorio(19)
    if segunda >= primeira then segunda = segunda + 1 end
    if primeira <= 6 or segunda <= 6 then positivas = positivas + 1 end
end
local exata, observada = 1 - (14 / 20) * (13 / 19), positivas / amostras
print(string.format('Referência de dois sorteios: %.5f%% exata; %.5f%% observada (%d amostras); diferença %.5f p.p.', 100 * exata, 100 * observada, amostras, 100 * (observada - exata)))
assert(math.abs(observada - exata) < 0.006, 'Investigar divergência da referência combinatória.')
