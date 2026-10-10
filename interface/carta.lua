local disposicao = require('interface.disposicao')

local modulo = {
    imagens = {},
    fontes = {}
}

local PASTA_IMAGENS = 'recursos/imagens/'
local QUALIDADE_TEXTO = 2

local molduras = {
    personagem = PASTA_IMAGENS .. 'personagem_card.png',
    associacao = PASTA_IMAGENS .. 'associacao_card.png',
    verso = PASTA_IMAGENS .. 'verso_card.png'
}

local retratos_conhecidos = {
    bruno = 'personagens/bruno.png',
    bruno_vilacian = 'personagens/bruno.png',
    irapua = 'personagens/irapuan.jpg',
    irapuan = 'personagens/irapuan.jpg',
    irapua_noce = 'personagens/irapuan.jpg',
    irapuan_noce = 'personagens/irapuan.jpg',
    marcela = 'personagens/marcela.jpg',
    marcela_paesano = 'personagens/marcela.jpg'
}

local function limitar(valor, minimo, maximo)
    return math.max(minimo, math.min(maximo, valor))
end

local function normalizar(texto)
    texto = tostring(texto or ''):lower()
    local trocas = {
        ['á'] = 'a', ['à'] = 'a', ['â'] = 'a', ['ã'] = 'a',
        ['é'] = 'e', ['ê'] = 'e', ['í'] = 'i',
        ['ó'] = 'o', ['ô'] = 'o', ['õ'] = 'o',
        ['ú'] = 'u', ['ü'] = 'u', ['ç'] = 'c'
    }
    for letra, substituto in pairs(trocas) do
        texto = texto:gsub(letra, substituto)
    end
    local resultado = texto:gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return resultado
end

local function carregar_imagem(caminho, filtro)
    if not caminho or caminho == '' then
        return nil
    end

    if modulo.imagens[caminho] == nil then
        if not love.filesystem.getInfo(caminho) then
            modulo.imagens[caminho] = false
        else
            local sucesso, imagem = pcall(love.graphics.newImage, caminho)
            if sucesso then
                imagem:setFilter(filtro or 'nearest', filtro or 'nearest')
                modulo.imagens[caminho] = imagem
            else
                modulo.imagens[caminho] = false
                print('FECHO!: nao foi possivel carregar a imagem: ' .. caminho)
            end
        end
    end

    return modulo.imagens[caminho] or nil
end

local function obter_fonte(tamanho)
    tamanho = math.max(9, math.floor(tamanho + 0.5))
    if not modulo.fontes[tamanho] then
        -- A imagem continua pixelada, mas os nomes ganham resolucao extra.
        local fonte = love.graphics.newFont(tamanho * QUALIDADE_TEXTO)
        fonte:setFilter('linear', 'linear')
        fonte:setLineHeight(1.05)
        modulo.fontes[tamanho] = fonte
    end
    return modulo.fontes[tamanho]
end

local function medir_texto(texto, fonte, largura)
    local _, linhas = fonte:getWrap(texto, largura * QUALIDADE_TEXTO)
    local altura_linha = fonte:getHeight() / QUALIDADE_TEXTO * fonte:getLineHeight()
    return #linhas, #linhas * altura_linha
end

local function escolher_fonte(texto, largura, altura, maior, menor, maximo_linhas)
    for tamanho = maior, menor, -1 do
        local fonte = obter_fonte(tamanho)
        local quantidade, altura_texto = medir_texto(texto, fonte, largura)
        if quantidade <= maximo_linhas and altura_texto <= altura then
            return fonte, altura_texto
        end
    end
    local fonte = obter_fonte(menor)
    local _, altura_texto = medir_texto(texto, fonte, largura)
    return fonte, altura_texto
end

local function escrever_centralizado(texto, fonte, x, y, largura)
    love.graphics.push()
    love.graphics.scale(1 / QUALIDADE_TEXTO)
    love.graphics.setFont(fonte)
    love.graphics.printf(
        texto,
        x * QUALIDADE_TEXTO,
        y * QUALIDADE_TEXTO,
        largura * QUALIDADE_TEXTO,
        'center'
    )
    love.graphics.pop()
end

local function desenhar_texto_ajustado(texto, x, y, largura, altura, maior, menor, linhas)
    texto = tostring(texto or '')
    if texto == '' then return end
    local fonte, altura_texto = escolher_fonte(texto, largura, altura, maior, menor, linhas)
    local posicao_y = y + (altura - math.min(altura_texto, altura)) / 2
    escrever_centralizado(texto, fonte, x, posicao_y, largura)
end

local function buscar_arte(dados)
    local caminhos = {}

    -- O cadastro pode informar a imagem explicitamente, sem alterar o resto do jogo.
    if type(dados.imagem) == 'string' and dados.imagem ~= '' then
        if dados.imagem:sub(1, #PASTA_IMAGENS) == PASTA_IMAGENS then
            table.insert(caminhos, dados.imagem)
        else
            table.insert(caminhos, PASTA_IMAGENS .. dados.imagem)
        end
    end

    local identificador = normalizar(dados.identificador)
    local nome = normalizar(dados.titulo)
    if dados.personagem then
        local conhecido = retratos_conhecidos[identificador] or retratos_conhecidos[nome]
        if conhecido then
            table.insert(caminhos, PASTA_IMAGENS .. conhecido)
        end

        for _, chave in ipairs({identificador, nome}) do
            if chave ~= '' then
                table.insert(caminhos, PASTA_IMAGENS .. 'personagens/' .. chave .. '.png')
                table.insert(caminhos, PASTA_IMAGENS .. 'personagens/' .. chave .. '.jpg')
            end
        end
    else
        for _, chave in ipairs({identificador, nome}) do
            if chave ~= '' then
                table.insert(caminhos, PASTA_IMAGENS .. 'associacoes/' .. chave .. '.png')
                table.insert(caminhos, PASTA_IMAGENS .. 'associacoes/' .. chave .. '.jpg')
            end
        end
    end

    -- Mantem a compatibilidade com as imagens antigas na raiz da pasta.
    if identificador ~= '' then
        table.insert(caminhos, PASTA_IMAGENS .. identificador .. '.png')
    end

    for _, caminho in ipairs(caminhos) do
        local imagem = carregar_imagem(caminho, 'linear')
        if imagem then return imagem end
    end
    return nil
end

local function desenhar_imagem_ajustada(imagem, x, y, largura, altura)
    local largura_imagem, altura_imagem = imagem:getDimensions()
    local escala = math.max(largura / largura_imagem, altura / altura_imagem)
    local x_imagem = x + (largura - largura_imagem * escala) / 2
    local y_imagem = y + (altura - altura_imagem * escala) / 2

    -- O retrato ocupa apenas a janela central e nao invade a borda da carta.
    love.graphics.stencil(function()
        love.graphics.rectangle('fill', x, y, largura, altura, 2)
    end, 'replace', 1, true)
    love.graphics.setStencilTest('greater', 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(imagem, x_imagem, y_imagem, 0, escala, escala)
    love.graphics.setStencilTest()
end

local function desenhar_moldura(caminho, largura, altura)
    local imagem = carregar_imagem(caminho, 'nearest')
    if imagem then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            imagem, 0, 0, 0,
            largura / imagem:getWidth(),
            altura / imagem:getHeight()
        )
        return true
    end

    -- A carta continua utilizavel mesmo que alguma arte ainda nao exista.
    love.graphics.setColor(0.94, 0.85, 0.68, 1)
    love.graphics.rectangle('fill', 0, 0, largura, altura, 5)
    love.graphics.setColor(0.67, 0.49, 0.25, 1)
    love.graphics.rectangle('line', 3, 3, largura - 6, altura - 6, 4)
    return false
end

local function desenhar_campos(dados, largura, altura, possui_moldura)
    local margem = largura * 0.13
    local largura_campo = largura - margem * 2

    if not possui_moldura then
        love.graphics.setColor(0.08, 0.22, 0.23, 1)
        desenhar_texto_ajustado(
            dados.personagem and 'PERSONAGEM' or 'ASSOCIAÇÃO',
            largura * 0.12, altura * 0.085, largura * 0.76,
            altura * 0.08, 13, 10, 1
        )
    end

    -- As artes atuais tem textos de exemplo impressos na propria imagem.
    -- Estes paineis escondem os exemplos e reservam o espaco para os dados reais.
    local nome_y = altura * 0.653
    local nome_altura = altura * 0.153
    love.graphics.setColor(0.976, 0.881, 0.735, 1)
    love.graphics.rectangle('fill', margem, nome_y, largura_campo, nome_altura, 2)
    love.graphics.setColor(0.66, 0.48, 0.28, 0.8)
    love.graphics.rectangle('line', margem, nome_y, largura_campo, nome_altura, 2)
    love.graphics.setColor(0.07, 0.14, 0.13, 1)
    desenhar_texto_ajustado(
        dados.titulo,
        margem + 3, nome_y + 2, largura_campo - 6,
        nome_altura - 4, 20, 10, 3
    )

    local rodape_y = altura * 0.836
    local rodape_altura = altura * 0.082
    love.graphics.setColor(0.926, 0.773, 0.558, 1)
    love.graphics.rectangle('fill', margem, rodape_y, largura_campo, rodape_altura, 2)
    love.graphics.setColor(0.64, 0.46, 0.27, 0.65)
    love.graphics.rectangle('line', margem, rodape_y, largura_campo, rodape_altura, 2)
    love.graphics.setColor(0.16, 0.20, 0.17, 1)
    desenhar_texto_ajustado(
        dados.subtitulo,
        margem + 2, rodape_y + 1, largura_campo - 4,
        rodape_altura - 2, 12, 9, 2
    )
end

function modulo.desenhar(dados, posicao)
    dados = dados or {}
    posicao = posicao or {}

    local largura = disposicao.largura_carta
    local altura = disposicao.altura_carta
    local escala = posicao.escala or 1
    local virada = posicao.virada or 1
    local destaque = limitar(posicao.sobre or 0, 0, 1)

    -- Preservamos as transformacoes existentes; o hover e as animacoes
    -- continuam usando exatamente as mesmas coordenadas da mesa.
    love.graphics.push('all')
    love.graphics.translate(posicao.horizontal or 0, posicao.vertical or 0)
    love.graphics.rotate(posicao.angulo or 0)
    love.graphics.scale(escala * virada, escala)
    love.graphics.translate(-largura / 2, -altura / 2)

    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle('fill', 3, 7, largura, altura, 5)

    local caminho_moldura
    if dados.oculta then
        caminho_moldura = molduras.verso
    elseif dados.personagem then
        caminho_moldura = molduras.personagem
    else
        caminho_moldura = molduras.associacao
    end

    local possui_moldura = desenhar_moldura(caminho_moldura, largura, altura)

    if not dados.oculta then
        local imagem = buscar_arte(dados)
        if imagem then
            desenhar_imagem_ajustada(
                imagem,
                largura * 0.225, altura * 0.238,
                largura * 0.55, altura * 0.365
            )
        end
        desenhar_campos(dados, largura, altura, possui_moldura)
    elseif not possui_moldura then
        love.graphics.setColor(0.10, 0.22, 0.23, 1)
        desenhar_texto_ajustado('FECHO!', 8, altura * 0.4, largura - 16, altura * 0.2, 26, 13, 1)
    end

    if destaque > 0.01 or dados.selecionavel then
        love.graphics.setColor(0.98, 0.75, 0.34, limitar(0.30 + destaque * 0.6, 0, 1))
        love.graphics.setLineWidth(2)
        love.graphics.rectangle('line', 2, 2, largura - 4, altura - 4, 5)
    end

    love.graphics.pop()
end

return modulo
