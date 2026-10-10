local motor = require('nucleo.partida')
local regras = require('nucleo.regras')
local inteligencia = require('ia.inteligencia_artificial')
local embaralhamento = require('utilitarios.embaralhamento')
local animacoes = require('interface.animacoes')
local botoes = require('interface.botoes')
local mesa = require('interface.mesa')
local menu = require('interface.menu')
local apostas = require('nucleo.apostas')
local disposicao = require('interface.disposicao')
local sons = require('interface.sons')

local aplicacao = {
    tela = 'menu',
    dificuldade = 'normal',
    espera = 0,
    mensagem = '',
    tempo_mensagem = 0,
    ajuda = false
}

-- A interface continua usando as coordenadas de 1280 x 720.
-- O que muda e onde desenhamos: diretamente na janela, sem ampliar
-- uma imagem pronta de baixa resolucao junto com as letras.
local LARGURA_REFERENCIA = 1280
local ALTURA_REFERENCIA = 720

local function criar_fonte(tamanho, densidade)
    -- A fonte tem mais pixels internamente, mas continua ocupando
    -- o mesmo espaco na interface. Isso melhora a nitidez ao redimensionar.
    local fonte = love.graphics.newFont(tamanho, 'normal', densidade)
    fonte:setFilter('linear', 'linear')
    return fonte
end

local function atualizar_fontes()
    local largura, altura = love.graphics.getDimensions()
    local escala = disposicao.transformacao(largura, altura)
    local densidade_tela = love.graphics.getDPIScale()
    local densidade = math.min(4, math.max(2, math.ceil(escala * densidade_tela)))

    aplicacao.fontes = {
        normal = criar_fonte(18, densidade),
        pequena = criar_fonte(15, densidade),
        titulo = criar_fonte(30, densidade),
        destaque = criar_fonte(46, densidade),
        gigante = criar_fonte(86, densidade)
    }
end

function aplicacao.voltar_menu()
    aplicacao.tela, aplicacao.ajuda = 'menu', false
    animacoes.transicao = 1
end

function aplicacao.nova_partida()
    local sucesso, partida = pcall(motor.nova, os.time(), aplicacao.cadastro)
    if not sucesso then
        aplicacao.erro = tostring(partida)
        return
    end

    aplicacao.partida = partida
    aplicacao.aleatorio_ia = embaralhamento.gerador(os.time() + 731)
    aplicacao.tela, aplicacao.espera, aplicacao.mensagem =
        'mesa', 0, 'Uma nova mesa. Faça sua associação.'
    aplicacao.tempo_mensagem = 2.5
    animacoes.distribuir()
    mesa.sincronizar(aplicacao, 0)
end

function aplicacao.proxima_rodada()
    if animacoes.ocupada() or aplicacao.partida.fase ~= 'intervalo' then
        return
    end

    local sucesso, erro = pcall(motor.iniciar_rodada, aplicacao.partida)
    if not sucesso then
        aplicacao.erro = tostring(erro)
        return
    end

    aplicacao.espera, aplicacao.mensagem =
        0, 'Cartas distribuídas. A aposta começa em 1.'
    aplicacao.tempo_mensagem = 2.5
    animacoes.distribuir()
    mesa.sincronizar(aplicacao, 0)
end

function aplicacao.agir(acao)
    if animacoes.ocupada() or aplicacao.ajuda then
        return false
    end

    local partida = aplicacao.partida
    local jogador = partida.turno
    local posicao_descarte

    if acao:match('^manter') then
        posicao_descarte = mesa.posicao_descarte(
            jogador, acao == 'manter_1' and 2 or 1
        )
    end

    local comprometido_antes = partida.esta_comprometido[jogador]
    local permitido = motor.agir(partida, jogador, acao)
    if not permitido then
        return false
    end

    if acao == 'comprar' then
        sons.tocar('compra')
    end

    local sujeito = jogador == 1 and 'Você' or 'Adversário'
    local mensagens = {
        comprar = ' comprou uma carta.',
        passar = ' passou.',
        recuar = ' recuou!',
        aceitar = ' aceitou o confronto.',
        manter_1 = ' descartou em segredo.',
        manter_2 = ' descartou em segredo.'
    }

    aplicacao.mensagem = sujeito .. (
        mensagens[acao] or
        (' pediu ' .. (apostas.nomes[partida.nivel] or 'FECHO!'))
    )

    if acao == 'comprar' then
        animacoes.comprar()
    end
    if acao:match('^manter') then
        animacoes.descartar(posicao_descarte)
    end
    if acao == 'fecho' or acao == 'aumentar' then
        animacoes.apostar()
    end
    if partida.reveladas then
        animacoes.revelar()
    end

    aplicacao.espera, aplicacao.tempo_mensagem = 0, 2.5

    if not comprometido_antes and partida.esta_comprometido[jogador] then
        aplicacao.mensagem = jogador == 1 and
            'Você ficou comprometido.' or 'Adversário ficou comprometido.'
    end
    if acao == 'aceitar' then
        aplicacao.mensagem = 'APOSTA ACEITA!'
    end
    if acao == 'fecho' or acao == 'aumentar' then
        aplicacao.mensagem = apostas.nomes[partida.nivel]
    end

    mesa.sincronizar(aplicacao, 0)
    return true
end

function love.load()
    -- Os desenhos em pixel art continuam com pixels definidos.
    -- As fontes usam filtro linear individualmente para nao ficarem serrilhadas.
    love.graphics.setDefaultFilter('nearest', 'nearest')
    atualizar_fontes()
    sons.carregar()

    local sucesso, cadastro = pcall(regras.carregar)
    if sucesso then
        aplicacao.cadastro = cadastro
    else
        aplicacao.erro = tostring(cadastro)
    end

    love.graphics.setLineWidth(2)
end

function love.resize(largura, altura)
    -- Quando a janela muda de tamanho, recriamos as fontes com
    -- densidade suficiente para o novo fator de escala.
    atualizar_fontes()
end

function love.update(delta)
    botoes.atualizar(delta)
    if aplicacao.erro or aplicacao.ajuda then
        return
    end

    animacoes.atualizar(delta)
    aplicacao.tempo_mensagem = math.max(0, aplicacao.tempo_mensagem - delta)

    if aplicacao.tela ~= 'mesa' then
        return
    end

    mesa.sincronizar(aplicacao, delta)
    local partida = aplicacao.partida

    if not animacoes.ocupada()
        and partida.turno == 2
        and #motor.acoes_disponiveis(partida, 2) > 0 then

        aplicacao.espera = aplicacao.espera + delta
        if aplicacao.espera >= 0.85 then
            local acao = inteligencia.decidir_jogada_ia(
                motor.visao(partida, 2),
                aplicacao.cadastro,
                aplicacao.dificuldade,
                aplicacao.aleatorio_ia
            )
            aplicacao.agir(acao)
        end
    end
end

function love.draw()
    local largura, altura = love.graphics.getDimensions()
    local escala, margem_horizontal, margem_vertical =
        disposicao.transformacao(largura, altura)

    -- Desenhamos no tamanho real da janela. As margens preservam a
    -- proporcao da mesa sem esticar cartas ou alterar as areas de clique.
    love.graphics.clear(0.02, 0.04, 0.05)
    love.graphics.push('all')
    love.graphics.setScissor(
        math.floor(margem_horizontal),
        math.floor(margem_vertical),
        math.ceil(LARGURA_REFERENCIA * escala),
        math.ceil(ALTURA_REFERENCIA * escala)
    )
    love.graphics.translate(margem_horizontal, margem_vertical)
    love.graphics.scale(escala, escala)

    love.graphics.setColor(0.045, 0.10, 0.13)
    love.graphics.rectangle('fill', 0, 0, LARGURA_REFERENCIA, ALTURA_REFERENCIA)

    love.graphics.setFont(aplicacao.fontes.normal)
    for linha = 0, 90 do
        love.graphics.setColor(0.07, 0.16, 0.18, 0.45)
        love.graphics.line(0, linha * 8, LARGURA_REFERENCIA, linha * 8)
    end

    botoes.limpar()
    if aplicacao.erro then
        love.graphics.setColor(1, 0.7, 0.4)
        love.graphics.printf(
            'Erro de configuração\n' .. aplicacao.erro,
            120, 240, 1040, 'center'
        )
    else
        love.graphics.push()
        love.graphics.translate(
            math.sin(animacoes.tempo * 45) * animacoes.impacto * 1.5,
            0
        )

        if aplicacao.tela == 'menu' then
            menu.desenhar(aplicacao)
        else
            mesa.desenhar(aplicacao)
        end

        love.graphics.pop()

        if aplicacao.ajuda then
            botoes.limpar()
            mesa.ajuda(aplicacao)
        end
    end

    if animacoes.transicao > 0 then
        love.graphics.setColor(0.02, 0.05, 0.07, animacoes.transicao * 0.65)
        love.graphics.rectangle(
            'fill', 0, 0, LARGURA_REFERENCIA, ALTURA_REFERENCIA
        )
    end

    love.graphics.pop()
end

function love.mousemoved(horizontal, vertical)
    local largura, altura = love.graphics.getDimensions()
    horizontal, vertical = disposicao.coordenadas(
        horizontal, vertical, largura, altura
    )
    botoes.apontar(horizontal, vertical)
    if aplicacao.tela == 'mesa' and not aplicacao.ajuda then
        mesa.apontar(horizontal, vertical)
    end
end

function love.mousepressed(horizontal, vertical, botao)
    if botao ~= 1 or aplicacao.erro then
        return
    end

    local largura, altura = love.graphics.getDimensions()
    horizontal, vertical = disposicao.coordenadas(
        horizontal, vertical, largura, altura
    )

    if botoes.clicar(horizontal, vertical) then
        return
    end
    if aplicacao.tela == 'mesa'
        and not aplicacao.ajuda
        and not animacoes.ocupada() then
        mesa.clicar(aplicacao, horizontal, vertical)
    end
end

function love.keypressed(tecla)
    if aplicacao.erro then
        return
    end
    if tecla == 'h' then
        aplicacao.ajuda = not aplicacao.ajuda
        return
    end
    if tecla == 'escape' then
        if aplicacao.ajuda then
            aplicacao.ajuda = false
        else
            aplicacao.voltar_menu()
        end
        return
    end
    if aplicacao.ajuda or animacoes.ocupada() then
        return
    end
    if tecla == 'return' then
        if aplicacao.tela == 'menu' or aplicacao.partida.fase == 'fim' then
            aplicacao.nova_partida()
        elseif aplicacao.partida.fase == 'intervalo' then
            aplicacao.proxima_rodada()
        end
        return
    end
    if aplicacao.tela ~= 'mesa' or aplicacao.partida.turno ~= 1 then
        return
    end

    local atalhos = {
        c = 'comprar',
        p = 'passar',
        f = aplicacao.partida.fase == 'desafio' and 'aumentar' or 'fecho',
        a = 'aceitar',
        r = 'recuar',
        ['1'] = 'manter_1',
        ['2'] = 'manter_2'
    }
    if atalhos[tecla] then
        aplicacao.agir(atalhos[tecla])
    end
end
