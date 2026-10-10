-- Perfis de avaliação, usados somente nas simulações; recebem a mesma visão limitada.
local inteligencia = require('ia.inteligencia_artificial')
local modulo = {}
function modulo.decidir(visao, cadastro, perfil, aleatorio)
    local dificuldade = perfil == 'adaptativa' and 'dificil' or 'normal'
    local acao = inteligencia.decidir_jogada_ia(visao, cadastro, dificuldade, aleatorio)
    if visao.fase ~= 'normal' then return acao end
    local vencer, empatar, forca = inteligencia.avaliar_risco(visao, cadastro, dificuldade)
    if perfil == 'conservadora' and acao == 'fecho' and forca < 8 then return 'passar' end
    if perfil == 'agressiva' and forca >= 5 and vencer + empatar * 0.3 > 0.4 and aleatorio() < 0.35 then return 'fecho' end
    if perfil == 'blefadora' and forca <= 3 then
        local avaliacao = inteligencia.avaliar_aposta(visao, cadastro, dificuldade, 2)
        local chance = avaliacao.probabilidade_recuo * 0.35 + empatar * 0.03
        if aleatorio() < chance then return 'fecho' end
    end
    return acao
end
return modulo
