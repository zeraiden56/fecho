local modulo = {}
function modulo.embaralhar(cartas, aleatorio)
    for indice = #cartas, 2, -1 do
        local outro = aleatorio(indice)
        cartas[indice], cartas[outro] = cartas[outro], cartas[indice]
    end
    return cartas
end
-- Gerador local: uma partida não altera a sequência aleatória de outra.
function modulo.gerador(semente)
    local estado = math.floor(semente or 1) % 2147483647
    if estado <= 0 then estado = 1 end
    return function(limite)
        estado = (estado * 16807) % 2147483647
        if limite then return math.floor(estado / 2147483647 * limite) + 1 end
        return estado / 2147483647
    end
end
return modulo
