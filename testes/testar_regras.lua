local apoio = require('testes.apoio')
local motor = require('nucleo.partida')
local regras = require('nucleo.regras')
local cadastro = regras.carregar()
for semente = 1, 200 do
    local partida = motor.nova(semente)
    apoio.verdadeiro(partida.personagens[1] ~= partida.personagens[2])
    for _, identificador in ipairs(partida.personagens) do
        local completo = false
        for _, personagem in ipairs(cadastro.habilitados) do if personagem.identificador == identificador then completo = true end end
        apoio.verdadeiro(completo)
    end
end
for _, relacao in ipairs(cadastro.relacoes) do
    apoio.igual(regras.calcular_associacao(cadastro, relacao.personagem, relacao.associacao), relacao.pontos)
end
local partida = motor.nova(12)
local adversaria = partida.maos[2][1]
apoio.verdadeiro(not motor.agir(partida, 2, 'comprar'))
apoio.verdadeiro(motor.agir(partida, 1, 'comprar'))
apoio.igual(#partida.maos[1], 2)
apoio.verdadeiro(not motor.agir(partida, 1, 'comprar'))
apoio.verdadeiro(not motor.agir(partida, 1, 'fecho'))
local comprada = partida.maos[1][2]
apoio.verdadeiro(motor.agir(partida, 1, 'manter_2'))
apoio.igual(partida.maos[1][1], comprada)
apoio.igual(partida.maos[2][1], adversaria)
apoio.igual(#partida.descartes[1], 1)
motor.agir(partida, 2, 'passar')
apoio.verdadeiro(motor.agir(partida, 1, 'comprar'))
motor.agir(partida, 1, 'manter_1')
motor.agir(partida, 2, 'passar')
motor.agir(partida, 1, 'fecho')
apoio.verdadeiro(not motor.agir(partida, 2, 'comprar'))
local visao = motor.visao(partida, 2)
local permitidos = {jogador=true, fase=true, turno=true, nivel=true, pote=true, numero=true, placar=true,
    personagens=true, quantidade_compras_rodada=true, passes=true, cartas_restantes=true, esta_comprometido=true, mao=true, descartes_proprios=true, historico=true, acoes=true}
for chave in pairs(visao) do apoio.verdadeiro(permitidos[chave], 'Campo privado vazou: '..chave) end
apoio.igual(#visao.mao, 1)
apoio.igual(visao.mao[1], adversaria.associacao)
apoio.igual(#visao.descartes_proprios, 0)
apoio.igual(visao.historico[2].acao, 'descartar')
visao.placar[1] = 999
visao.personagens[1] = 'alterado'
apoio.igual(partida.placar[1], 0)
apoio.verdadeiro(partida.personagens[1] ~= 'alterado')
local copia = motor.visao(partida, 2)
partida.maos[1][1].associacao = 'ibm'
partida.monte[1], partida.monte[2] = partida.monte[2], partida.monte[1]
partida.descartes[1] = {{associacao = 'familia'}}
local outra = motor.visao(partida, 2)
local inteligencia = require('ia.inteligencia_artificial')
for _, dificuldade in ipairs({'facil', 'normal', 'dificil'}) do
    local gerador = require('utilitarios.embaralhamento').gerador
    apoio.igual(inteligencia.decidir_jogada_ia(copia, cadastro, dificuldade, gerador(7)),
        inteligencia.decidir_jogada_ia(outra, cadastro, dificuldade, gerador(7)), 'IA depende de segredo')
end
local passes = apoio.preparar(3, 5)
motor.agir(passes, 1, 'passar')
motor.agir(passes, 2, 'comprar')
apoio.igual(passes.passes, 0)
motor.agir(passes, 2, 'manter_1')
motor.agir(passes, 1, 'passar')
apoio.igual(passes.fase, 'normal')
motor.agir(passes, 2, 'passar')
apoio.igual(passes.fase, 'intervalo')
motor.iniciar_rodada(passes)
apoio.igual(passes.iniciativa, 2)
apoio.igual(#passes.monte, 18)
apoio.igual(passes.quantidade_compras_rodada[1], 0)
apoio.igual(passes.quantidade_compras_rodada[2], 0)
print('Regras, turnos e privacidade: OK')
