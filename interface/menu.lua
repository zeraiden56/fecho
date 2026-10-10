local botoes = require('interface.botoes')
local carta = require('interface.carta')
local modulo = {}
function modulo.desenhar(aplicacao)
    carta.desenhar({oculta = true}, {horizontal = 230, vertical = 346, escala = 0.95, angulo = -0.14})
    carta.desenhar({oculta = true}, {horizontal = 1050, vertical = 346, escala = 0.95, angulo = 0.14})
    love.graphics.setFont(aplicacao.fontes.gigante)
    love.graphics.setColor(0.96, 0.69, 0.34)
    love.graphics.printf('FECHO!', 0, 120, 1280, 'center')
    love.graphics.setFont(aplicacao.fontes.normal)
    love.graphics.setColor(0.75, 0.84, 0.79)
    love.graphics.printf('CARTAS, CORAGEM E BLEFE', 0, 221, 1280, 'center')
    love.graphics.printf('Conheça sua mão. Leia seu adversário.', 0, 270, 1280, 'center')
    for indice, dificuldade in ipairs({'facil', 'normal', 'dificil'}) do
        local nomes = {facil = 'Fácil', normal = 'Normal', dificil = 'Difícil'}
        botoes.desenhar(nomes[dificuldade], 368 + (indice - 1) * 184, 338, 176, 48,
            function() aplicacao.dificuldade = dificuldade end, aplicacao.dificuldade == dificuldade)
    end
    botoes.desenhar('Jogar contra IA', 450, 433, 380, 56, aplicacao.nova_partida, true)
    botoes.desenhar('Como jogar', 535, 515, 210, 46, function() aplicacao.ajuda = true end)
    love.graphics.setColor(0.50, 0.67, 0.65)
    love.graphics.setFont(aplicacao.fontes.pequena)
    love.graphics.printf('Uma mesa. Dois jogadores. Doze pontos para vencer.', 0, 633, 1280, 'center')
    love.graphics.setFont(aplicacao.fontes.normal)
end
return modulo
