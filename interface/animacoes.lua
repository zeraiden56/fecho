local modulo = {tempo = 0, bloqueio = 0, virada = 0, transicao = 0, impacto = 0, cartas = {}, descartadas = {}, particulas = {}}
function modulo.interpolar(atual, destino, delta, velocidade)
    return atual + (destino - atual) * (1 - math.exp(-(velocidade or 12) * delta))
end
function modulo.atualizar(delta)
    modulo.tempo = modulo.tempo + delta
    modulo.bloqueio = math.max(0, modulo.bloqueio - delta)
    modulo.virada = math.max(0, modulo.virada - delta / 0.65)
    modulo.transicao = math.max(0, modulo.transicao - delta * 2.5)
    modulo.impacto = math.max(0, modulo.impacto - delta * 2)
    for indice = #modulo.descartadas, 1, -1 do
        local carta = modulo.descartadas[indice]
        carta.progresso = carta.progresso + delta / 0.45
        if carta.progresso >= 1 then table.remove(modulo.descartadas, indice) end
    end
    for indice = #modulo.particulas, 1, -1 do
        local particula = modulo.particulas[indice]
        particula.vida = particula.vida - delta
        particula.horizontal = particula.horizontal + particula.velocidade_horizontal * delta
        particula.vertical = particula.vertical + particula.velocidade_vertical * delta
        if particula.vida <= 0 then table.remove(modulo.particulas, indice) end
    end
end
function modulo.distribuir()
    modulo.cartas, modulo.descartadas = {}, {}
    modulo.bloqueio, modulo.transicao, modulo.virada = 0.65, 1, 0
end
function modulo.comprar() modulo.bloqueio = 0.48 end
function modulo.descartar(posicao)
    if posicao then
        modulo.descartadas[#modulo.descartadas + 1] = {horizontal = posicao.horizontal,
            vertical = posicao.vertical, escala = posicao.escala, angulo = posicao.angulo, progresso = 0}
    end
    modulo.bloqueio = 0.45
end
function modulo.apostar()
    modulo.impacto, modulo.bloqueio = 1, 0.38
    for indice = 1, 18 do
        local angulo = indice * math.pi * 2 / 18
        modulo.particulas[#modulo.particulas + 1] = {horizontal = 640, vertical = 321, vida = 0.7,
            velocidade_horizontal = math.cos(angulo) * 135, velocidade_vertical = math.sin(angulo) * 70}
    end
end
function modulo.revelar() modulo.virada, modulo.bloqueio = 1, 0.85 end
function modulo.ocupada() return modulo.bloqueio > 0 end
return modulo
