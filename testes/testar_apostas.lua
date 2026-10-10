local apoio = require('testes.apoio')
local motor = require('nucleo.partida')
for nivel = 2, 4 do
    local partida = apoio.preparar(10, 0)
    partida.pote = 9
    motor.agir(partida, 1, 'fecho')
    for _ = 3, nivel do motor.agir(partida, partida.turno, 'aumentar') end
    local vencedor = 3 - partida.turno
    apoio.verdadeiro(not motor.agir(partida, partida.turno, 'comprar'))
    if nivel == 4 then apoio.verdadeiro(not motor.agir(partida, partida.turno, 'aumentar')) end
    motor.agir(partida, partida.turno, 'recuar')
    apoio.igual(partida.placar[vencedor], ({1, 3, 6})[nivel - 1])
    apoio.igual(partida.pote, 9)
    apoio.igual(partida.reveladas, false)
end
for nivel = 1, 4 do
    local partida = apoio.preparar(8, 8)
    partida.pote = 3
    if nivel == 1 then motor.agir(partida, 1, 'passar'); motor.agir(partida, 2, 'passar')
    else
        motor.agir(partida, 1, 'fecho')
        for _ = 3, nivel do motor.agir(partida, partida.turno, 'aumentar') end
        motor.agir(partida, partida.turno, 'aceitar')
    end
    apoio.igual(partida.pote, 3 + ({1, 3, 6, 9})[nivel])
    apoio.igual(partida.placar[1] + partida.placar[2], 0)
    apoio.igual(partida.reveladas, true)
end
local partida = apoio.preparar(10, 8)
partida.pote, partida.placar[1] = 9, 2
motor.agir(partida, 1, 'passar')
motor.agir(partida, 2, 'passar')
apoio.igual(partida.placar[1], 12)
apoio.igual(partida.pote, 0)
apoio.igual(partida.fase, 'fim')
apoio.verdadeiro(not motor.agir(partida, 1, 'passar'))
apoio.falha(function() motor.iniciar_rodada(partida) end, 'não terminou')
partida = apoio.preparar(0, 10)
partida.placar[1] = 11
motor.agir(partida, 1, 'fecho')
motor.agir(partida, 2, 'recuar')
apoio.igual(partida.fase, 'fim')
print('Apostas, pote e encerramento: OK')
