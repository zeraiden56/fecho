local modulo = {COMPRAS_PARA_COMPROMETIMENTO = 2}
function modulo.carregar(personagens, associacoes, relacoes)
    local cadastro = {personagens = personagens or require('dados.personagens'),
        associacoes = associacoes or require('dados.associacoes'),
        relacoes = relacoes or require('dados.relacoes'), por_personagem = {}, por_associacao = {}, habilitados = {}}
    local nomes = {}
    for _, personagem in ipairs(cadastro.personagens) do
        assert(not nomes[personagem.identificador], 'Configuração: personagem duplicado.')
        nomes[personagem.identificador] = personagem
        cadastro.por_personagem[personagem.identificador] = {}
    end
    for _, associacao in ipairs(cadastro.associacoes) do
        assert(not cadastro.por_associacao[associacao.identificador], 'Configuração: associação duplicada.')
        cadastro.por_associacao[associacao.identificador] = associacao
    end
    for _, relacao in ipairs(cadastro.relacoes) do
        local mapa = cadastro.por_personagem[relacao.personagem]
        assert(mapa and cadastro.por_associacao[relacao.associacao], 'Configuração: relação com identificador inexistente.')
        assert(relacao.pontos == 10 or relacao.pontos == 8 or relacao.pontos == 5 or relacao.pontos == 3, 'Configuração: força inválida.')
        assert(not mapa[relacao.associacao], 'Configuração: relação duplicada.')
        mapa[relacao.associacao] = relacao.pontos
    end
    for _, personagem in ipairs(cadastro.personagens) do
        local categorias, quantidade = {}, 0
        for _, pontos in pairs(cadastro.por_personagem[personagem.identificador]) do
            assert(not categorias[pontos], 'Configuração: categoria repetida em '..personagem.nome)
            categorias[pontos], quantidade = true, quantidade + 1
        end
        if personagem.habilitado then
            assert(quantidade == 4, 'Configuração: personagem habilitado incompleto: '..personagem.nome)
            cadastro.habilitados[#cadastro.habilitados + 1] = personagem
        end
    end
    assert(#cadastro.habilitados >= 2, 'Configuração: são necessários dois personagens completos.')
    return cadastro
end
function modulo.calcular_associacao(cadastro, personagem, associacao)
    return cadastro.por_personagem[personagem][associacao] or 0
end
return modulo
