local regras = require('nucleo.regras')
local baralho = require('nucleo.baralho')
local apostas = require('nucleo.apostas')
local modulo = {}
local function limitar(valor, minimo, maximo) return math.max(minimo, math.min(maximo, valor)) end
local function contem(lista, valor)
    for _, item in ipairs(lista) do if item == valor then return true end end
    return false
end
function modulo.estimar_perfil(visao)
    local perfil = {fechos = 0, aumentos = 0, recuos = 0, aceites = 0, compras_recentes = 0,
        ultima_acao = '', pressionou = false}
    for _, evento in ipairs(visao.historico) do
        if evento.jogador == 3 - visao.jogador then
            if evento.acao == 'fecho' then perfil.fechos = perfil.fechos + 1 end
            if evento.acao == 'aumentar' or evento.acao == 'refecho' or evento.acao == 'fecho_final' then perfil.aumentos = perfil.aumentos + 1 end
            if evento.acao == 'recuar' then perfil.recuos = perfil.recuos + 1 end
            if evento.acao == 'aceitar' then perfil.aceites = perfil.aceites + 1 end
            if evento.rodada == visao.numero then
                if evento.acao == 'comprar' then perfil.compras_recentes = perfil.compras_recentes + 1 end
                if evento.acao == 'passar' or evento.acao == 'comprar' or evento.acao == 'fecho' or evento.acao == 'refecho' or evento.acao == 'fecho_final' then perfil.ultima_acao = evento.acao end
                if evento.acao == 'fecho' or evento.acao == 'aumentar' or evento.acao == 'refecho' or evento.acao == 'fecho_final' then perfil.pressionou = true end
            end
        end
    end
    -- Uma pequena amostra não deve transformar um único recuo em certeza de blefe.
    local respostas = perfil.recuos + perfil.aceites + perfil.aumentos
    perfil.taxa_recuo = (perfil.recuos + 2) / (respostas + 5)
    perfil.taxa_aceite = (perfil.aceites + 2) / (respostas + 5)
    perfil.agressividade = (perfil.fechos + perfil.aumentos + 1) / (visao.numero + respostas + 3)
    perfil.confianca = respostas / (respostas + 8)
    return perfil
end
local function distribuicao_publica(visao, cadastro, personagem)
    local quantidades = baralho.composicao(cadastro, visao.personagens)
    local distribuicao, total = {[0] = 20, [3] = 0, [5] = 0, [8] = 0, [10] = 0}, 20
    for associacao, quantidade in pairs(quantidades) do
        local pontos = regras.calcular_associacao(cadastro, personagem, associacao)
        if pontos > 0 then
            distribuicao[pontos] = distribuicao[pontos] + quantidade
            distribuicao[0] = distribuicao[0] - quantidade
        end
    end
    -- As cartas próprias vistas e descartadas estão definitivamente fora do monte.
    -- Os descartes adversários continuam desconhecidos e não são consultados.
    for _, conjunto in ipairs({visao.mao, visao.descartes_proprios}) do
        for _, associacao in ipairs(conjunto) do
            local pontos = regras.calcular_associacao(cadastro, personagem, associacao)
            distribuicao[pontos], total = distribuicao[pontos] - 1, total - 1
        end
    end
    return distribuicao, math.max(1, total)
end
function modulo.avaliar_risco(visao, cadastro, dificuldade)
    local proprio, adversario = visao.jogador, 3 - visao.jogador
    local forca = regras.calcular_associacao(cadastro, visao.personagens[proprio], visao.mao[1])
    local distribuicao, total = distribuicao_publica(visao, cadastro, visao.personagens[adversario])
    local inferior, igual = 0, 0
    for pontos, quantidade in pairs(distribuicao) do
        if pontos < forca then inferior = inferior + quantidade elseif pontos == forca then igual = quantidade end
    end
    local vencer, empatar = inferior / total, igual / total
    if dificuldade ~= 'facil' then
        -- Estimamos a melhor carta entre as compras públicas, sem reposição.
        -- É uma aproximação: não sabemos se ele realmente guardou sempre a melhor.
        local amostras = math.min(total, 1 + visao.quantidade_compras_rodada[adversario])
        local function todas_abaixo(quantidade)
            local chance = 1
            for indice = 0, amostras - 1 do
                chance = chance * math.max(0, quantidade - indice) / (total - indice)
            end
            return chance
        end
        vencer = todas_abaixo(inferior)
        empatar = todas_abaixo(inferior + igual) - vencer
    end
    local perfil = modulo.estimar_perfil(visao)
    if dificuldade == 'dificil' and perfil.pressionou then
        local cautela = limitar(0.20 - perfil.agressividade * 0.24, 0.025, 0.18)
        vencer, empatar = vencer * (1 - cautela), empatar * (1 - cautela)
    end
    return vencer, empatar, forca
end
function modulo.avaliar_compra(visao, cadastro, forca)
    if visao.cartas_restantes == 0 then return 0 end
    local distribuicao, total = distribuicao_publica(visao, cadastro, visao.personagens[visao.jogador])
    local ganho = 0
    for pontos, quantidade in pairs(distribuicao) do ganho = ganho + math.max(0, pontos - forca) * quantidade / total end
    -- Cada turno cedido dá ao adversário outra chance de melhorar ou fechar a mesa.
    -- O retorno esperado cai com a busca prolongada, sem limitar a ação nas regras.
    local compras = visao.quantidade_compras_rodada[visao.jogador] or 0
    local retorno = ganho / (1 + compras * 0.45)
    local perfil = modulo.estimar_perfil(visao)
    if compras == regras.COMPRAS_PARA_COMPROMETIMENTO - 1 and not visao.esta_comprometido[visao.jogador] then
        local risco = (1 - forca / 10) * (0.25 + perfil.agressividade)
        local decisiva = visao.placar[3 - visao.jogador] + 3 + visao.pote >= 12 and 1.5 or 1
        retorno = retorno - risco * (1 + visao.pote * 0.10) * decisiva
    end
    -- Com poucas cartas, outra busca deixa menos margem para recuperar uma mão ruim.
    return retorno * (0.65 + 0.35 * math.min(1, visao.cartas_restantes / 6))
end
function modulo.probabilidade_blefe(visao, perfil, dificuldade, avaliacao)
    local base = dificuldade == 'facil' and 0.055 or 0.11
    if dificuldade == 'dificil' then
        base = 0.035 + perfil.taxa_recuo * 0.32 - perfil.taxa_aceite * 0.10 - perfil.agressividade * 0.08
    end
    if visao.fase == 'normal' and visao.esta_comprometido[3 - visao.jogador] then
        -- Sem recuo inicial, pressão fraca depende de confronto/empate e de contra-aumentos.
        base = 0.02 + (avaliacao and (avaliacao.vencer * 0.08 + avaliacao.empatar * 0.06) or 0)
        base = base / (1 + perfil.agressividade)
    end
    if avaliacao and avaliacao.valor_esperado < 0 then base = base / (1 + math.abs(avaliacao.valor_esperado) * 0.15) end
    if perfil.ultima_acao == 'passar' then base = base + 0.045 end
    if perfil.ultima_acao == 'comprar' then base = base - 0.015 end
    base = base / (1 + perfil.compras_recentes * 0.16)
    local diferenca = visao.placar[3 - visao.jogador] - visao.placar[visao.jogador]
    base = base + math.max(0, diferenca) * 0.007
    if visao.placar[visao.jogador] >= 9 then base = base * 0.65 end
    base = base / (1 + visao.pote * 0.10)
    if visao.fase == 'desafio' then base = base * (visao.nivel == 3 and 0.14 or 0.42) end
    return limitar(base, 0.003, 0.35)
end
function modulo.avaliar_aposta(visao, cadastro, dificuldade, nivel)
    local vencer, empatar = modulo.avaliar_risco(visao, cadastro, dificuldade)
    local perder = math.max(0, 1 - vencer - empatar)
    local perfil = modulo.estimar_perfil(visao)
    local recuar = perfil.taxa_recuo
    if nivel == 2 and visao.esta_comprometido[3 - visao.jogador] then recuar = 0 end
    local aumentar = nivel < #apostas.valores and (1 - recuar) * limitar(perfil.agressividade, 0.08, 0.55) or 0
    local aceitar = 1 - recuar - aumentar
    local valor, anterior = apostas.valores[nivel], apostas.valores[nivel - 1]
    local confronto = (vencer - perder) * (valor + visao.pote)
    local resposta_aumento = nivel < #apostas.valores and
        math.max(-valor, (vencer - perder) * (apostas.valores[nivel + 1] + visao.pote)) or 0
    return {probabilidade_recuo = recuar, probabilidade_aceite = aceitar, probabilidade_aumento = aumentar,
        vencer = vencer, empatar = empatar, valor_esperado = recuar * anterior + aceitar * confronto + aumentar * resposta_aumento}
end
function modulo.decidir_jogada_ia(visao, cadastro, dificuldade, aleatorio)
    aleatorio, dificuldade = aleatorio or math.random, dificuldade or 'normal'
    if #visao.acoes == 0 then return nil end
    if visao.fase == 'escolha' then
        local primeira = regras.calcular_associacao(cadastro, visao.personagens[visao.jogador], visao.mao[1])
        local segunda = regras.calcular_associacao(cadastro, visao.personagens[visao.jogador], visao.mao[2])
        local erro = dificuldade == 'facil' and 0.08 or (dificuldade == 'dificil' and 0.008 or 0.02)
        if aleatorio() < erro then return segunda > primeira and 'manter_1' or 'manter_2' end
        return segunda > primeira and 'manter_2' or 'manter_1'
    end
    local vencer, empatar, forca = modulo.avaliar_risco(visao, cadastro, dificuldade)
    local perfil = modulo.estimar_perfil(visao)
    local avaliacao = modulo.avaliar_aposta(visao, cadastro, dificuldade, math.min(4, visao.nivel + 1))
    local blefe = modulo.probabilidade_blefe(visao, perfil, dificuldade, avaliacao)
    local proprio, adversario = visao.jogador, 3 - visao.jogador
    local ruido = (aleatorio() - 0.5) * (dificuldade == 'facil' and 0.28 or 0.12)
    local confianca = vencer + empatar * 0.35 + ruido
    if visao.fase == 'desafio' then
        local valor, anterior = apostas.valores[visao.nivel], apostas.valores[visao.nivel - 1]
        local perder = math.max(0, 1 - vencer - empatar)
        local expectativa = (vencer - perder) * (valor + visao.pote)
        if dificuldade ~= 'facil' and visao.placar[adversario] + anterior >= 12 then return 'aceitar' end
        if dificuldade == 'dificil' then
            if visao.placar[proprio] + valor + visao.pote >= 12 then expectativa = expectativa + vencer * 2 end
            if visao.placar[adversario] + valor + visao.pote >= 12 then expectativa = expectativa - perder * 2 end
        end
        if contem(visao.acoes, 'aumentar') then
            local pressionar = confianca > 0.72 and aleatorio() < 0.76
            if not contem(visao.acoes, 'recuar') and forca <= 3 then
                local vantagem = avaliacao.valor_esperado - expectativa
                local contra_blefe = limitar(0.16 + vantagem * 0.075, 0.025, 0.72)
                if dificuldade == 'facil' then contra_blefe = contra_blefe * 0.65 end
                if aleatorio() < contra_blefe then return 'aumentar' end
            end
            if pressionar or (forca <= 3 and aleatorio() < blefe) then return 'aumentar' end
        end
        if forca == 10 or expectativa + ruido * 4 >= -anterior then return 'aceitar' end
        return contem(visao.acoes, 'recuar') and 'recuar' or 'aceitar'
    end
    -- O blefe vem antes da compra: uma mão ruim também pode pressionar.
    if forca <= 3 and aleatorio() < blefe then return 'fecho' end
    -- A mão perfeita não perde nem contra uma busca longa: vale fechar a mesa
    -- mesmo quando a estimativa aponta mais empates do que vitórias.
    if forca == 10 and aleatorio() < 0.58 then return 'fecho' end
    local ganho = modulo.avaliar_compra(visao, cadastro, forca)
    local custo_turno = 0.28 + perfil.compras_recentes * 0.045 + visao.pote * 0.015
    if perfil.ultima_acao == 'passar' and forca >= 5 then custo_turno = custo_turno + 0.28 end
    local comprar = limitar((ganho - custo_turno) * 0.75, 0, 0.91)
    if dificuldade == 'facil' then comprar = comprar * 0.87 end
    if forca == 8 then comprar = comprar * 0.55 end
    if contem(visao.acoes, 'comprar') and aleatorio() < comprar then return 'comprar' end
    local limiar = dificuldade == 'facil' and 0.74 or 0.63
    if visao.placar[proprio] + visao.pote + 3 >= 12 then limiar = limiar - 0.05 end
    if confianca > limiar and aleatorio() < 0.78 then return 'fecho' end
    return 'passar'
end
return modulo
