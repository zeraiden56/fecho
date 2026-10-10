local botoes = require('interface.botoes')
local modulo = {}
function modulo.texto(partida)
    local resultado = partida.resultado
    if resultado.motivo == 'empate' then return 'EMPATE · POTE '..partida.pote end
    if partida.fase == 'fim' then return resultado.vencedor == 1 and 'VOCÊ VENCEU A PARTIDA!' or 'A PARTIDA FOI DO ADVERSÁRIO' end
    return resultado.vencedor == 1 and 'VOCÊ VENCEU A RODADA!' or 'O ADVERSÁRIO VENCEU A RODADA'
end
function modulo.desenhar(aplicacao)
    local partida, resultado = aplicacao.partida, aplicacao.partida.resultado
    love.graphics.setColor(0.94, 0.74, 0.42)
    love.graphics.setFont(aplicacao.fontes.normal)
    love.graphics.printf(modulo.texto(partida), 340, 268, 600, 'center')
    love.graphics.setColor(0.86, 0.89, 0.83)
    love.graphics.setFont(aplicacao.fontes.titulo)
    local detalhe = resultado.motivo == 'empate' and '+'..require('nucleo.apostas').valores[partida.nivel]..' no pote' or '+'..resultado.pontos..' pontos'
    love.graphics.printf(detalhe, 380, 299, 520, 'center')
    love.graphics.setFont(aplicacao.fontes.pequena)
    if resultado.forcas then
        love.graphics.printf('Sua força '..resultado.forcas[1]..'  ×  '..resultado.forcas[2]..' força adversária', 350, 346, 580, 'center')
        local pote = resultado.pote_recebido or 0
        love.graphics.printf(pote > 0 and ('Inclui '..pote..' pontos do pote acumulado.') or
            (resultado.motivo == 'empate' and 'O pote continua para a próxima rodada.' or 'Confronto revelado.'), 350, 371, 580, 'center')
    else love.graphics.printf('Vitória por recuo. Cartas ocultas; pote preservado.', 350, 350, 580, 'center') end
    love.graphics.setFont(aplicacao.fontes.normal)
end
function modulo.controles(aplicacao)
    botoes.desenhar(aplicacao.partida.fase == 'fim' and 'Jogar novamente' or 'Próxima rodada', 510, 659, 260, 46,
        aplicacao.partida.fase == 'fim' and aplicacao.nova_partida or aplicacao.proxima_rodada, true)
end
return modulo
