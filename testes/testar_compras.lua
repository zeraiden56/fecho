local apoio = require('testes.apoio')
local motor = require('nucleo.partida')
local partida = motor.nova(333)
local originais, descartadas = {}, {}
for _, conjunto in ipairs({partida.monte, partida.maos[1], partida.maos[2]}) do
    for _, carta in ipairs(conjunto) do originais[carta.fisico] = carta end
end
local function conservar()
    local encontrados, total = {}, 0
    for _, conjunto in ipairs({partida.monte, partida.maos[1], partida.maos[2], partida.descartes[1], partida.descartes[2]}) do
        for _, carta in ipairs(conjunto) do
            apoio.verdadeiro(not encontrados[carta.fisico], 'Carta duplicada')
            apoio.igual(carta, originais[carta.fisico], 'Carta recriada')
            encontrados[carta.fisico], total = true, total + 1
        end
    end
    apoio.igual(total, 20)
end
apoio.igual(#partida.monte, 18)
for turno = 1, 18 do
    local jogador = partida.turno
    local adversaria = partida.maos[3 - jogador][1]
    local compras_antes = partida.quantidade_compras_rodada[jogador]
    apoio.verdadeiro(motor.agir(partida, jogador, 'comprar'))
    apoio.igual(partida.quantidade_compras_rodada[jogador], compras_antes, 'Só contar a compra concluída')
    apoio.verdadeiro(not motor.agir(partida, jogador, 'comprar'))
    apoio.igual(partida.passes, 0)
    apoio.igual(#partida.monte, 18 - turno)
    apoio.verdadeiro(not descartadas[partida.maos[jogador][2].fisico], 'Descarte retornou à mão')
    conservar()
    apoio.verdadeiro(motor.agir(partida, jogador, turno % 2 == 0 and 'manter_2' or 'manter_1'))
    apoio.igual(partida.quantidade_compras_rodada[jogador], compras_antes + 1)
    apoio.igual(partida.turno, 3 - jogador)
    apoio.igual(partida.maos[3 - jogador][1], adversaria)
    for _, carta in ipairs(partida.descartes[jogador]) do descartadas[carta.fisico] = true end
    conservar()
end
apoio.igual(partida.quantidade_compras_rodada[1], 9)
apoio.igual(partida.quantidade_compras_rodada[2], 9)
apoio.igual(#partida.descartes[1] + #partida.descartes[2], 18)
apoio.verdadeiro(not motor.pode_comprar(partida))
apoio.verdadeiro(not motor.agir(partida, partida.turno, 'comprar'))
apoio.igual(#partida.monte, 0)
motor.agir(partida, partida.turno, 'passar')
motor.agir(partida, partida.turno, 'passar')
apoio.igual(partida.fase, 'intervalo')
motor.iniciar_rodada(partida)
apoio.igual(#partida.monte, 18)
apoio.igual(#partida.descartes[1] + #partida.descartes[2], 0)
print('Compras alternadas, monte finito e conservação: OK')
