local carta = require('interface.carta')
local botoes = require('interface.botoes')
local regras = require('nucleo.regras')
local motor = require('nucleo.partida')
local apostas = require('nucleo.apostas')
local animacoes = require('interface.animacoes')
local disposicao = require('interface.disposicao')
local resultados = require('interface.resultados')
local modulo = {descritores = {}, apontada = nil}
local categorias = {[0] = 'Sem associação', [3] = 'Fraca', [5] = 'Média', [8] = 'Forte', [10] = 'Perfeita'}

-- O LÖVE procura arquivos a partir da raiz do projeto, mesmo que o
-- projeto esteja salvo em outro diretório do computador.
local CAMINHO_FUNDO = 'recursos/imagens/mesa.png'
local LARGURA_MESA, ALTURA_MESA = 1280, 720
local fundo_mesa = nil
local fundo_verificado = false

local function desenhar_fundo()
    -- Carregamos a textura uma vez só. As regras e o restante da interface
    -- continuam funcionando mesmo enquanto ainda não houver uma imagem.
    if not fundo_verificado then
        fundo_verificado = true
        if love.filesystem.getInfo(CAMINHO_FUNDO) then
            fundo_mesa = love.graphics.newImage(CAMINHO_FUNDO)
            fundo_mesa:setFilter('linear', 'linear')
        end
    end

    if not fundo_mesa then return end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        fundo_mesa, 0, 0, 0,
        LARGURA_MESA / fundo_mesa:getWidth(),
        ALTURA_MESA / fundo_mesa:getHeight()
    )
    -- Uma camada discreta impede que a decoração do fundo prejudique
    -- a leitura das apostas e dos indicadores da partida.
    love.graphics.setColor(0.015, 0.035, 0.04, 0.12)
    love.graphics.rectangle('fill', 0, 0, LARGURA_MESA, ALTURA_MESA)
end
function modulo.sincronizar(aplicacao, delta)
    local partida = aplicacao.partida
    if not partida then return end
    local descritores, presentes = {}, {}
    for jogador = 2, 1, -1 do
        local posicoes = disposicao.mao(#partida.maos[jogador] + 1, jogador)
        local personagem
        for _, candidato in ipairs(aplicacao.cadastro.personagens) do
            if candidato.identificador == partida.personagens[jogador] then personagem = candidato end
        end
        local cartas = {{chave = jogador..'_personagem', titulo = personagem.nome, personagem = true,
            identificador = personagem.identificador, subtitulo = 'FECHO!'}}
        for indice, associacao in ipairs(partida.maos[jogador]) do
            local oculta = jogador == 2 and (not partida.reveladas or animacoes.virada > 0.5)
            local forca = regras.calcular_associacao(aplicacao.cadastro, personagem.identificador, associacao.associacao)
            cartas[#cartas + 1] = {chave = jogador..'_'..associacao.fisico, indice = indice, oculta = oculta,
                titulo = not oculta and aplicacao.cadastro.por_associacao[associacao.associacao].nome or '',
                identificador = not oculta and associacao.associacao or nil,
                subtitulo = not oculta and (categorias[forca]..' · '..forca) or '',
                selecionavel = jogador == 1 and partida.turno == 1 and partida.fase == 'escolha'}
        end
        for indice, dados in ipairs(cartas) do
            dados.jogador, dados.destino = jogador, posicoes[indice]
            local estado = animacoes.cartas[dados.chave]
            if not estado then
                estado = {horizontal = disposicao.monte.horizontal, vertical = disposicao.monte.vertical,
                    escala = disposicao.monte.escala, angulo = 0, sobre = 0}
                animacoes.cartas[dados.chave] = estado
            end
            local sobre = modulo.apontada == dados.chave and jogador == 1 and not aplicacao.ajuda and 1 or 0
            estado.sobre = animacoes.interpolar(estado.sobre, sobre, delta)
            estado.horizontal = animacoes.interpolar(estado.horizontal, dados.destino.horizontal, delta)
            estado.vertical = animacoes.interpolar(estado.vertical, dados.destino.vertical - sobre * 16, delta)
            estado.escala = animacoes.interpolar(estado.escala, dados.destino.escala * (1 + sobre * 0.035), delta)
            estado.angulo = animacoes.interpolar(estado.angulo, dados.destino.angulo * (1 - sobre), delta)
            estado.virada = jogador == 2 and dados.indice and partida.reveladas and math.max(0.025, math.abs(1 - 2 * animacoes.virada)) or 1
            dados.posicao = estado
            presentes[dados.chave], descritores[#descritores + 1] = true, dados
        end
    end
    for chave in pairs(animacoes.cartas) do if not presentes[chave] then animacoes.cartas[chave] = nil end end
    modulo.descritores = descritores
end
function modulo.apontar(horizontal, vertical)
    local anterior = modulo.apontada
    modulo.apontada = nil
    -- A carta levantada mantém a prioridade nas áreas sobrepostas.
    for _, dados in ipairs(modulo.descritores) do
        if dados.chave == anterior and dados.jogador == 1 and disposicao.contem(dados.posicao, horizontal, vertical) then
            modulo.apontada = dados.chave
            return
        end
    end
    for indice = #modulo.descritores, 1, -1 do
        local dados = modulo.descritores[indice]
        if dados.jogador == 1 and disposicao.contem(dados.posicao, horizontal, vertical) then modulo.apontada = dados.chave; return end
    end
end
function modulo.clicar(aplicacao, horizontal, vertical)
    modulo.apontar(horizontal, vertical)
    for _, dados in ipairs(modulo.descritores) do
        if dados.chave == modulo.apontada and dados.selecionavel then
            aplicacao.agir('manter_'..dados.indice)
            return true
        end
    end
    return false
end
function modulo.posicao_descarte(jogador, indice)
    for _, dados in ipairs(modulo.descritores) do
        if dados.jogador == jogador and dados.indice == indice then return dados.posicao end
    end
end
local function texto(aplicacao, conteudo, horizontal, vertical, largura, fonte, cor)
    love.graphics.setFont(aplicacao.fontes[fonte or 'normal'])
    love.graphics.setColor(unpack(cor or {0.83, 0.87, 0.81}))
    love.graphics.printf(conteudo, horizontal, vertical, largura, 'center')
end
local function pilhas(aplicacao)
    local partida = aplicacao.partida
    for camada = 3, 1, -1 do
        if #partida.monte > 0 then
            carta.desenhar({oculta = true}, {horizontal = disposicao.monte.horizontal + camada * 2,
                vertical = disposicao.monte.vertical - camada * 2, escala = disposicao.monte.escala, angulo = -0.06})
        end
    end
    texto(aplicacao, 'MONTE · '..#partida.monte, 185, 405, 140, 'pequena')
    local descartes = #partida.descartes[1] + #partida.descartes[2]
    love.graphics.setColor(0.24, 0.37, 0.37)
    love.graphics.rectangle('line', 994, 308, 62, 88, 4)
    if descartes > 0 then carta.desenhar({oculta = true}, disposicao.descarte) end
    texto(aplicacao, 'DESCARTE', 965, 405, 120, 'pequena')
    for _, descartada in ipairs(animacoes.descartadas) do
        local progresso = descartada.progresso
        local suave = progresso * progresso * (3 - 2 * progresso)
        carta.desenhar({oculta = true}, {horizontal = descartada.horizontal + (disposicao.descarte.horizontal - descartada.horizontal) * suave,
            vertical = descartada.vertical + (disposicao.descarte.vertical - descartada.vertical) * suave,
            escala = descartada.escala + (disposicao.descarte.escala - descartada.escala) * suave, angulo = progresso * 0.12})
    end
end
local function indicadores_comprometimento(aplicacao)
    local partida = aplicacao.partida
    for jogador = 1, 2 do
        local horizontal = jogador == 1 and 70 or 190
        local topo = jogador == 1 and 569 or 178
        texto(aplicacao, 'Compras: '..partida.quantidade_compras_rodada[jogador], horizontal, topo - 23, 250, 'pequena')
        if partida.esta_comprometido[jogador] then
            texto(aplicacao, '[!] COMPROMETIDO', horizontal, topo, 250, 'pequena', {0.95, 0.74, 0.40})
            texto(aplicacao, 'Recuo bloqueado\nno FECHO inicial.', horizontal, topo + 22, 250, 'pequena')
        end
    end
end
local function controles(aplicacao)
    local partida = aplicacao.partida
    if partida.fase == 'intervalo' or partida.fase == 'fim' then
        if not animacoes.ocupada() then resultados.controles(aplicacao) end
        return
    end
    if partida.turno ~= 1 or partida.fase == 'escolha' then return end
    local acoes = partida.fase == 'normal' and {'comprar', 'passar', 'fecho'} or motor.acoes_disponiveis(partida, 1)
    local rotulos = {comprar = 'COMPRAR', passar = 'PASSAR', fecho = 'FECHO!', aceitar = 'ACEITAR', recuar = 'RECUAR',
        aumentar = apostas.nomes[partida.nivel + 1]}
    local inicio = (1280 - (#acoes * 172 + (#acoes - 1) * 14)) / 2
    for indice, acao in ipairs(acoes) do
        local desabilitado = animacoes.ocupada() or (acao == 'comprar' and not motor.pode_comprar(partida))
        botoes.desenhar(rotulos[acao], inicio + (indice - 1) * 186, 659, 172, 46,
            function() aplicacao.agir(acao) end, acao == 'fecho' or acao == 'aumentar', desabilitado, acao)
    end
end
function modulo.desenhar(aplicacao)
    local partida = aplicacao.partida
    -- O fundo vem primeiro para não cobrir cartas, menus e botões.
    desenhar_fundo()
    texto(aplicacao, 'FECHO!', 32, 28, 140, 'titulo', {0.94, 0.69, 0.36})
    texto(aplicacao, 'RODADA '..partida.numero, 42, 65, 120, 'pequena', {0.48, 0.64, 0.64})
    botoes.desenhar('Como jogar', 972, 25, 148, 40, function() aplicacao.ajuda = true end)
    botoes.desenhar('Menu', 1134, 25, 108, 40, aplicacao.voltar_menu)
    texto(aplicacao, 'ADVERSÁRIO', 490, 25, 300, 'pequena')
    texto(aplicacao, partida.placar[2]..' / 12', 820, 120, 160, 'titulo')
    texto(aplicacao, aplicacao.dificuldade:upper(), 820, 159, 160, 'pequena', {0.48, 0.64, 0.64})
    -- Na escolha de três cartas, o placar sai do espaço ocupado pela mão.
    if #partida.maos[1] == 2 then
        texto(aplicacao, 'VOCÊ  '..partida.placar[1]..' / 12', 78, 525, 190, 'normal')
    else
        texto(aplicacao, 'VOCÊ', 302, 512, 150, 'pequena')
        texto(aplicacao, partida.placar[1]..' / 12', 302, 535, 150, 'titulo')
    end
    pilhas(aplicacao)
    local levantada
    for _, dados in ipairs(modulo.descritores) do
        if dados.chave == modulo.apontada then levantada = dados else carta.desenhar(dados, dados.posicao) end
    end
    if levantada then carta.desenhar(levantada, levantada.posicao) end
    if animacoes.virada > 0 then
        love.graphics.setColor(0.94, 0.74, 0.42, math.sin(animacoes.virada * math.pi) * 0.10)
        love.graphics.rectangle('fill', 335, 248, 610, 159, 12)
    end
    if partida.resultado and not animacoes.ocupada() then resultados.desenhar(aplicacao)
    else
        texto(aplicacao, partida.fase == 'desafio' and 'APOSTA PROPOSTA' or 'APOSTA', 460, 259, 160, 'pequena')
        texto(aplicacao, tostring(apostas.valores[partida.nivel]), 465, 279, 150, 'destaque', {0.98, 0.76, 0.40})
        texto(aplicacao, 'POTE', 665, 259, 150, 'pequena')
        texto(aplicacao, tostring(partida.pote), 665, 280, 150, 'destaque')
        if aplicacao.tempo_mensagem > 0 then
            texto(aplicacao, aplicacao.mensagem, 335, 348 - math.min(1, aplicacao.tempo_mensagem / 2) * 3, 610, 'normal',
                {0.94, 0.75, 0.45, math.min(1, aplicacao.tempo_mensagem * 2)})
        end
        local contexto = ''
        if not animacoes.ocupada() then
            if partida.turno == 2 then contexto = 'Adversário pensando'..string.rep('.', math.floor(animacoes.tempo * 2) % 4)
            elseif partida.fase == 'escolha' then contexto = 'Escolha a associação que deseja manter.'
            elseif partida.fase == 'desafio' then
                contexto = motor.pode_recuar(partida, 1) and (apostas.nomes[partida.nivel]..' Você aceita?') or
                    'Comprometido: aceite ou aumente. Recuo bloqueado.'
            else contexto = 'Sua vez' end
        elseif partida.reveladas then contexto = 'Revelando as associações…' end
        texto(aplicacao, contexto, 350, 391, 580, 'pequena')
    end
    for _, particula in ipairs(animacoes.particulas) do
        love.graphics.setColor(0.97, 0.75, 0.40, particula.vida)
        love.graphics.rectangle('fill', particula.horizontal, particula.vertical, 3, 3)
    end
    indicadores_comprometimento(aplicacao)
    controles(aplicacao)
    local risco_compra = partida.fase == 'normal' and partida.turno == 1 and
        partida.quantidade_compras_rodada[1] == regras.COMPRAS_PARA_COMPROMETIMENTO - 1 and motor.pode_comprar(partida)
    for _, botao in ipairs(botoes.lista) do
        if risco_compra and botao.identificador == 'comprar' and not botao.desabilitado and
            botoes.horizontal >= botao.esquerda and botoes.horizontal <= botao.esquerda + botao.largura and
            botoes.vertical >= botao.topo and botoes.vertical <= botao.topo + botao.altura then
            love.graphics.setColor(0.025, 0.06, 0.08, 0.98)
            love.graphics.rectangle('fill', 838, 535, 410, 91, 6)
            texto(aplicacao, 'Comprar novamente fará você ficar comprometido.\nVocê não poderá recuar do próximo FECHO inicial.',
                852, 550, 382, 'pequena', {0.96, 0.78, 0.49})
        end
    end
end
function modulo.ajuda(aplicacao)
    love.graphics.setColor(0.015, 0.035, 0.045, 0.95)
    love.graphics.rectangle('fill', 0, 0, 1280, 720)
    texto(aplicacao, 'COMO FECHAR A MESA', 180, 85, 920, 'titulo', {0.96, 0.72, 0.38})
    texto(aplicacao, 'Compre, passe ou desafie. Ao comprar, clique na associação que quer manter.\nA segunda compra compromete: sem recuo no FECHO inicial de 3 pontos.\nNo REFECHO e FECHO FINAL, o recuo volta a ser permitido.\nO monte é finito: descartes secretos não retornam nesta rodada.\nDois passes seguidos revelam as cartas por 1 ponto.\nFECHO: 3 · REFECHO: 6 · FECHO FINAL: 9. Aceitar revela as mãos.\nRecuar concede 1 / 3 / 6 ao desafiante, preservando o pote.\nEmpates acumulam a aposta. Vitória revelada leva aposta + pote.', 180, 151, 920)
    if aplicacao.tela == 'mesa' then
        for jogador = 1, 2 do
            local identificador = aplicacao.partida.personagens[jogador]
            local linhas = {jogador == 1 and 'SEU PERSONAGEM' or 'PERSONAGEM ADVERSÁRIO', ''}
            for _, relacao in ipairs(aplicacao.cadastro.relacoes) do
                if relacao.personagem == identificador then linhas[#linhas + 1] = relacao.pontos..'  '..aplicacao.cadastro.por_associacao[relacao.associacao].nome end
            end
            texto(aplicacao, table.concat(linhas, '\n'), 200 + (jogador - 1) * 460, 377, 420)
        end
    end
    botoes.desenhar('Entendi', 535, 590, 210, 48, function() aplicacao.ajuda = false end, true)
end
return modulo
