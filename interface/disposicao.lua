-- Toda interação usa as mesmas coordenadas da mesa virtual, inclusive em janelas com margens.
local modulo = {largura = 1280, altura = 720, largura_carta = 140, altura_carta = 196,
    monte = {horizontal = 255, vertical = 354, escala = 0.42},
    descarte = {horizontal = 1025, vertical = 354, escala = 0.42}}
function modulo.transformacao(largura, altura)
    local escala = math.min(largura / modulo.largura, altura / modulo.altura)
    return escala, (largura - modulo.largura * escala) / 2, (altura - modulo.altura * escala) / 2
end
function modulo.coordenadas(horizontal, vertical, largura, altura)
    local escala, margem_horizontal, margem_vertical = modulo.transformacao(largura, altura)
    return (horizontal - margem_horizontal) / escala, (vertical - margem_vertical) / escala
end
function modulo.mao(quantidade, jogador)
    local escala = jogador == 1 and 1 or 0.78
    local espaco = modulo.largura_carta * escala + 18
    local largura_total = modulo.largura_carta * escala + (quantidade - 1) * espaco
    local inicio = (modulo.largura - largura_total) / 2 + modulo.largura_carta * escala / 2
    local posicoes = {}
    for indice = 1, quantidade do
        local distancia = indice - (quantidade + 1) / 2
        posicoes[indice] = {horizontal = inicio + (indice - 1) * espaco,
            vertical = (jogador == 1 and 531 or 151) + math.abs(distancia) * 4,
            angulo = distancia * (jogador == 1 and 0.045 or 0.025), escala = escala}
    end
    return posicoes
end
function modulo.contem(posicao, horizontal, vertical)
    local deslocamento_horizontal = horizontal - posicao.horizontal
    local deslocamento_vertical = vertical - posicao.vertical
    local cosseno, seno = math.cos(posicao.angulo), math.sin(posicao.angulo)
    local local_horizontal = (deslocamento_horizontal * cosseno + deslocamento_vertical * seno) / posicao.escala
    local local_vertical = (-deslocamento_horizontal * seno + deslocamento_vertical * cosseno) / posicao.escala
    return math.abs(local_horizontal) <= modulo.largura_carta / 2 and math.abs(local_vertical) <= modulo.altura_carta / 2
end
return modulo
