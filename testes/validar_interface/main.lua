-- Ensaio da aplicação real: a automação usa apenas cliques para jogar.
local raiz = love.filesystem.getSource()..'/../../'
package.path = raiz..'?.lua;'..package.path
os.time = function() return 20261010 end
assert(loadfile(raiz..'main.lua'))()
local carregar, atualizar, desenhar = love.load, love.update, love.draw
local aplicacao
for indice = 1, 20 do
    local nome, valor = debug.getupvalue(carregar, indice)
    if nome == 'aplicacao' then aplicacao = valor end
end
assert(aplicacao)
local motor = require('nucleo.partida')
local inteligencia = require('ia.inteligencia_artificial')
local estrategia = inteligencia.decidir_jogada_ia
local animacoes = require('interface.animacoes')
local mesa = require('interface.mesa')
local botoes = require('interface.botoes')
local disposicao = require('interface.disposicao')
local etapa, espera, quadros, captura = 'menu', 0, 0, nil
local capturas, indice_resolucao = {}, 1
local resolucoes = {{800,450}, {960,540}, {1280,720}, {1920,1080}, {1600,1000}}
local carta_escolhida, altura_inicial
local function avancar(proxima) etapa, espera = proxima, 0 end
local function coordenadas(horizontal, vertical)
    local largura, altura = love.graphics.getDimensions()
    local escala, margem_horizontal, margem_vertical = disposicao.transformacao(largura, altura)
    return horizontal * escala + margem_horizontal, vertical * escala + margem_vertical
end
local function clicar(horizontal, vertical)
    horizontal, vertical = coordenadas(horizontal, vertical)
    love.mousemoved(horizontal, vertical)
    love.mousepressed(horizontal, vertical, 1)
end
local function clicar_botao(identificador)
    for _, botao in ipairs(botoes.lista) do
        if botao.identificador == identificador then
            assert(not botao.desabilitado, 'Botão deveria estar disponível: '..identificador)
            clicar(botao.esquerda + botao.largura / 2, botao.topo + botao.altura / 2)
            return
        end
    end
    error('Botão não encontrado: '..identificador..' na etapa '..etapa)
end
local function associacao(indice)
    for _, dados in ipairs(mesa.descritores) do if dados.jogador == 1 and dados.indice == indice then return dados end end
    error('Associação não desenhada')
end
function love.load()
    carregar()
    assert(not aplicacao.erro)
    -- Primeiro isolamos duas compras humanas; depois restauramos a IA de produção.
    inteligencia.decidir_jogada_ia = function(visao, cadastro, dificuldade, aleatorio)
        if visao.jogador == 2 and visao.fase == 'normal' then return visao.esta_comprometido[1] and 'fecho' or 'passar' end
        if visao.jogador == 2 and visao.fase == 'desafio' and visao.nivel == 3 then return 'aumentar' end
        return estrategia(visao, cadastro, dificuldade, aleatorio)
    end
end
function love.update(delta)
    quadros, espera = quadros + 1, espera + 1
    local turno_anterior = aplicacao.partida and aplicacao.partida.turno
    local fase_anterior = aplicacao.partida and aplicacao.partida.fase
    local ocupada_anterior = animacoes.ocupada()
    atualizar(0.10)
    if ocupada_anterior ~= animacoes.ocupada() or (aplicacao.partida and (turno_anterior ~= aplicacao.partida.turno or fase_anterior ~= aplicacao.partida.fase)) then return end
    assert(not aplicacao.erro, aplicacao.erro)
    assert(quadros < 12000, 'Ensaio gráfico excedeu o limite')
    if etapa == 'menu' and espera == 4 then captura = 'menu'
    elseif etapa == 'menu' and espera > 5 then clicar_botao('Jogar contra IA'); avancar('inicio')
    elseif etapa == 'inicio' and espera > 12 then
        captura = 'mesa'; avancar('primeira_compra')
    elseif etapa == 'primeira_compra' and espera > 2 then
        clicar_botao('comprar'); avancar('escolha')
    elseif etapa == 'escolha' and espera > 10 then
        assert(aplicacao.partida.fase == 'escolha')
        assert(#aplicacao.partida.maos[1] == 2)
        captura = 'compra'
        local dados = associacao(2)
        carta_escolhida, altura_inicial = aplicacao.partida.maos[1][2], dados.posicao.vertical
        local horizontal, vertical = coordenadas(dados.posicao.horizontal, dados.posicao.vertical)
        love.mousemoved(horizontal, vertical)
        avancar('sobre_carta')
    elseif etapa == 'sobre_carta' and espera > 6 then
        local dados = associacao(2)
        assert(dados.posicao.sobre > 0.9 and dados.posicao.vertical < altura_inicial - 10)
        captura = 'destaque'; avancar('selecionar')
    elseif etapa == 'selecionar' and espera > 2 then
        local dados = associacao(2)
        clicar(dados.posicao.horizontal, dados.posicao.vertical)
        assert(aplicacao.partida.maos[1][1] == carta_escolhida)
        assert(#animacoes.descartadas == 1)
        avancar('segunda_compra')
    elseif etapa == 'segunda_compra' and aplicacao.partida.turno == 1 and not animacoes.ocupada() and espera > 2 then
        for _, botao in ipairs(botoes.lista) do
            if botao.identificador == 'comprar' then
                local horizontal, vertical = coordenadas(botao.esquerda + 80, botao.topo + 20)
                love.mousemoved(horizontal, vertical)
            end
        end
        captura = 'aviso_comprometimento'; avancar('confirmar_compra')
    elseif etapa == 'confirmar_compra' and espera > 3 then
        clicar_botao('comprar'); avancar('segunda_escolha')
    elseif etapa == 'segunda_escolha' and espera > 10 then
        assert(aplicacao.partida.quantidade_compras_rodada[1] == 1)
        local dados = associacao(1)
        clicar(dados.posicao.horizontal, dados.posicao.vertical)
        assert(aplicacao.partida.esta_comprometido[1])
        assert(aplicacao.partida.quantidade_compras_rodada[1] == 2)
        avancar('responder_comprometido')
    elseif etapa == 'responder_comprometido' and aplicacao.partida.fase == 'desafio' and aplicacao.partida.turno == 1 and not animacoes.ocupada() then
        for _, botao in ipairs(botoes.lista) do assert(botao.identificador ~= 'recuar') end
        love.keypressed('r')
        assert(aplicacao.partida.fase == 'desafio' and aplicacao.partida.turno == 1)
        captura = 'comprometido'; avancar('contra_blefar')
    elseif etapa == 'contra_blefar' and espera > 3 then
        clicar_botao('aumentar'); avancar('recuar_final')
    elseif etapa == 'recuar_final' and aplicacao.partida.nivel == 4 and aplicacao.partida.turno == 1 and not animacoes.ocupada() then
        clicar_botao('recuar')
        assert(not aplicacao.partida.reveladas and not aplicacao.partida.esta_comprometido[1])
        inteligencia.decidir_jogada_ia = estrategia
        avancar('redimensionar')
    elseif etapa == 'redimensionar' and espera > 10 then
        local resolucao = resolucoes[indice_resolucao]
        love.window.setMode(resolucao[1], resolucao[2], {resizable = true})
        avancar('abrir_ajuda')
    elseif etapa == 'abrir_ajuda' and espera > 3 then
        captura = 'mesa_'..resolucoes[indice_resolucao][1]
        avancar('clicar_ajuda')
    elseif etapa == 'clicar_ajuda' and espera > 2 then
        clicar_botao('Como jogar'); avancar('fechar_ajuda')
    elseif etapa == 'fechar_ajuda' and espera == 3 then
        captura = 'ajuda_'..resolucoes[indice_resolucao][1]
    elseif etapa == 'fechar_ajuda' and espera > 5 then
        assert(aplicacao.ajuda)
        clicar_botao('Entendi')
        assert(not aplicacao.ajuda)
        indice_resolucao = indice_resolucao + 1
        avancar(indice_resolucao <= #resolucoes and 'redimensionar' or 'jogar')
    elseif etapa == 'jogar' and not animacoes.ocupada() then
        local partida = aplicacao.partida
        if partida.fase == 'fim' then
            captura = 'fim'
            print('Partida gráfica completa: '..partida.placar[1]..' x '..partida.placar[2])
            avancar('reiniciar')
        elseif partida.fase == 'intervalo' then
            if partida.resultado.motivo == 'recuo' then assert(not partida.reveladas) end
            if not capturas.resultado then captura = 'resultado'; avancar('resultado')
            else clicar_botao('Próxima rodada') end
        elseif partida.turno == 1 then
            local acao = estrategia(motor.visao(partida, 1), aplicacao.cadastro, 'normal', aplicacao.aleatorio_ia)
            if acao:match('^manter') then
                local dados = associacao(acao == 'manter_1' and 1 or 2)
                clicar(dados.posicao.horizontal, dados.posicao.vertical)
            else clicar_botao(acao) end
        end
    elseif etapa == 'resultado' and espera > 4 then clicar_botao('Próxima rodada'); avancar('jogar')
    elseif etapa == 'reiniciar' and espera > 5 then
        clicar_botao('Jogar novamente')
        assert(aplicacao.partida.numero == 1 and aplicacao.partida.placar[1] == 0)
        avancar('voltar_menu')
    elseif etapa == 'voltar_menu' and espera > 10 then
        clicar_botao('Menu')
        assert(aplicacao.tela == 'menu')
        print('Mouse: início, duas compras, seleção, hover, ajuda, cinco resoluções, partida, reinício e menu: OK')
        print('Capturas: '..love.filesystem.getSaveDirectory())
        love.event.quit(0)
    end
end
function love.draw()
    desenhar()
    if aplicacao.tela == 'mesa' and not aplicacao.ajuda then
        local permitidas = {}
        for _, acao in ipairs(motor.acoes_disponiveis(aplicacao.partida, 1)) do permitidas[acao] = true end
        local acoes = {comprar=true, passar=true, fecho=true, aceitar=true, recuar=true, aumentar=true}
        for _, botao in ipairs(botoes.lista) do
            if acoes[botao.identificador] and not botao.desabilitado then assert(permitidas[botao.identificador], 'Interface ofereceu ação inválida') end
        end
    end
    if captura then
        local nome = captura
        captura = nil
        love.graphics.captureScreenshot(function(imagem)
            assert(love.filesystem.write('validacao_'..nome..'.png', imagem:encode('png')))
            capturas[nome] = true
        end)
    end
end
function love.errorhandler(mensagem)
    print(debug.traceback(mensagem))
    return function() return 1 end
end
