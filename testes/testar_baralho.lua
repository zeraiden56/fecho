local apoio = require('testes.apoio')
local regras = require('nucleo.regras')
local baralho = require('nucleo.baralho')
local aleatorio = require('utilitarios.embaralhamento').gerador(123)
local cadastro = regras.carregar()
apoio.igual(#cadastro.habilitados, 6)
apoio.igual(#cadastro.personagens, 19)
for _, primeiro in ipairs(cadastro.habilitados) do
    for _, segundo in ipairs(cadastro.habilitados) do
        if primeiro ~= segundo then
            local cartas = baralho.montar(cadastro, {primeiro.identificador, segundo.identificador}, aleatorio)
            apoio.igual(#cartas, 20)
            local contagem, fisicos, distracoes = {}, {}, 0
            for _, carta in ipairs(cartas) do
                apoio.verdadeiro(not fisicos[carta.fisico], 'Identificador físico repetido')
                fisicos[carta.fisico] = true
                contagem[carta.associacao] = (contagem[carta.associacao] or 0) + 1
                if regras.calcular_associacao(cadastro, primeiro.identificador, carta.associacao) == 0 and
                    regras.calcular_associacao(cadastro, segundo.identificador, carta.associacao) == 0 then distracoes = distracoes + 1 end
            end
            apoio.igual(distracoes, 8)
            for _, personagem in ipairs({primeiro, segundo}) do
                for associacao, pontos in pairs(cadastro.por_personagem[personagem.identificador]) do
                    apoio.igual(contagem[associacao], pontos >= 8 and 2 or 1)
                end
            end
        end
    end
end
local compartilhado = regras.carregar()
compartilhado.por_personagem.bruno.familia = nil
compartilhado.por_personagem.bruno.falar_demais = 10
compartilhado.por_personagem.bruno.matematica = nil
compartilhado.por_personagem.bruno.imitar_os_outros = 3
local cartas = baralho.montar(compartilhado, {'arthur', 'bruno'}, aleatorio)
local contagem = {}
for _, carta in ipairs(cartas) do contagem[carta.associacao] = (contagem[carta.associacao] or 0) + 1 end
apoio.igual(#cartas, 20)
apoio.igual(contagem.falar_demais, 2)
apoio.igual(contagem.imitar_os_outros, 2)
apoio.igual(regras.calcular_associacao(compartilhado, 'bruno', 'imitar_os_outros'), 3)
apoio.igual(regras.calcular_associacao(cadastro, 'irapua', 'portugal'), 8)
apoio.igual(regras.calcular_associacao(cadastro, 'irapua', 'ex_portugal'), 0)
apoio.igual(regras.calcular_associacao(cadastro, 'fujimura', 'ex_portugal'), 3)
apoio.igual(regras.calcular_associacao(cadastro, 'fujimura', 'portugal'), 0)
local insuficiente = regras.carregar()
insuficiente.associacoes = {cadastro.associacoes[1]}
apoio.falha(function() baralho.montar(insuficiente, {'arthur', 'bruno'}, aleatorio) end, 'distrações insuficientes')
apoio.falha(function() regras.carregar({{identificador = 'incompleto', nome = 'Incompleto', habilitado = true}}, {}, {}) end, 'incompleto')
apoio.falha(function() regras.carregar(nil, nil, {{personagem = 'ninguem', associacao = 'ibm', pontos = 10}}) end, 'inexistente')
print('Baralho e cadastro: OK')
