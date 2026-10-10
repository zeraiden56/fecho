local embaralhamento = require('utilitarios.embaralhamento')
local modulo = {}
function modulo.composicao(cadastro, personagens)
    local quantidades = {}
    for _, personagem in ipairs(personagens) do
        for associacao, pontos in pairs(cadastro.por_personagem[personagem]) do
            quantidades[associacao] = math.max(quantidades[associacao] or 0, pontos >= 8 and 2 or 1)
        end
    end
    return quantidades
end
function modulo.montar(cadastro, personagens, aleatorio)
    local quantidades = modulo.composicao(cadastro, personagens)
    local cartas, distracoes = {}, {}
    local function adicionar(associacao)
        cartas[#cartas + 1] = {fisico = #cartas + 1, associacao = associacao}
    end
    -- A ordem do catálogo mantém as sementes reproduzíveis entre execuções.
    for _, associacao in ipairs(cadastro.associacoes) do
        local quantidade = quantidades[associacao.identificador]
        if quantidade then
            for _ = 1, quantidade do adicionar(associacao.identificador) end
        else distracoes[#distracoes + 1] = associacao.identificador end
    end
    assert(#cartas <= 20 and #distracoes >= 20 - #cartas, 'Configuração: distrações insuficientes para formar 20 cartas.')
    embaralhamento.embaralhar(distracoes, aleatorio)
    local faltantes = 20 - #cartas
    for indice = 1, faltantes do adicionar(distracoes[indice]) end
    return embaralhamento.embaralhar(cartas, aleatorio)
end
return modulo
