local modulo = {lista = {}, estados = {}, horizontal = -1, vertical = -1}
function modulo.limpar() modulo.lista = {} end
function modulo.apontar(horizontal, vertical) modulo.horizontal, modulo.vertical = horizontal, vertical end
local function contem(botao, horizontal, vertical)
    return horizontal >= botao.esquerda and horizontal <= botao.esquerda + botao.largura and
        vertical >= botao.topo and vertical <= botao.topo + botao.altura
end
function modulo.atualizar(delta)
    for _, estado in pairs(modulo.estados) do estado.clique = math.max(0, estado.clique - delta * 5) end
    for _, botao in ipairs(modulo.lista) do
        local estado = modulo.estados[botao.identificador]
        local destino = not botao.desabilitado and contem(botao, modulo.horizontal, modulo.vertical) and 1 or 0
        estado.destaque = estado.destaque + (destino - estado.destaque) * (1 - math.exp(-15 * delta))
    end
end
function modulo.desenhar(rotulo, esquerda, topo, largura, altura, acao, destaque, desabilitado, identificador)
    identificador = identificador or rotulo
    local estado = modulo.estados[identificador] or {destaque = 0, clique = 0}
    modulo.estados[identificador] = estado
    local brilho = estado.destaque * 0.06
    local deslocamento = estado.clique * 2
    love.graphics.setColor(0.015, 0.027, 0.03, 0.6)
    love.graphics.rectangle('fill', esquerda, topo + 4, largura, altura, 5)
    if desabilitado then love.graphics.setColor(0.10, 0.15, 0.17)
    elseif destaque then love.graphics.setColor(0.91 + brilho, 0.65 + brilho, 0.32 + brilho)
    else love.graphics.setColor(0.15 + brilho, 0.25 + brilho, 0.27 + brilho) end
    love.graphics.rectangle('fill', esquerda, topo + deslocamento, largura, altura, 5)
    love.graphics.setColor(0.65, 0.77, 0.73, desabilitado and 0.10 or 0.22 + estado.destaque * 0.35)
    love.graphics.rectangle('line', esquerda + 1, topo + 1 + deslocamento, largura - 2, altura - 2, 5)
    if desabilitado then love.graphics.setColor(0.40, 0.47, 0.47)
    elseif destaque then love.graphics.setColor(0.09, 0.13, 0.15)
    else love.graphics.setColor(0.90, 0.92, 0.84) end
    love.graphics.printf(rotulo, esquerda + 8, topo + deslocamento + (altura - love.graphics.getFont():getHeight()) / 2, largura - 16, 'center')
    modulo.lista[#modulo.lista + 1] = {identificador = identificador, esquerda = esquerda, topo = topo,
        largura = largura, altura = altura, acao = acao, desabilitado = desabilitado}
end
function modulo.clicar(horizontal, vertical)
    for indice = #modulo.lista, 1, -1 do
        local botao = modulo.lista[indice]
        if contem(botao, horizontal, vertical) then
            if not botao.desabilitado then
                modulo.estados[botao.identificador].clique = 1
                modulo.lista = {}
                botao.acao()
            end
            return true
        end
    end
    return false
end
return modulo
