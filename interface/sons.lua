local modulo = {}
local efeitos = {}

local arquivos = {
    compra = 'comprar_carta.mp3',
    vitoria = 'vitoria.mp3',
    derrota = 'derrota.mp3'
}

local volume_efeitos = 0.45

function modulo.carregar()
    for nome, arquivo in pairs(arquivos) do
        local caminho = 'recursos/sons/' .. arquivo
        if love.filesystem.getInfo(caminho) then
            local sucesso, efeito = pcall(love.audio.newSource, caminho, 'static')
            if sucesso then
                efeito:setVolume(volume_efeitos)
                efeitos[nome] = efeito
            else
                print('FECHO!: nao foi possivel carregar o audio: ' .. caminho)
            end
        end
    end
end

function modulo.tocar(nome)
    local efeito = efeitos[nome]
    if not efeito then return end

    -- Evita que um som antigo continue tocando depois de uma nova acao.
    efeito:stop()
    efeito:play()
end

function modulo.definir_volume(volume)
    volume_efeitos = math.max(0, math.min(1, volume))
    for _, efeito in pairs(efeitos) do
        efeito:setVolume(volume_efeitos)
    end
end

return modulo
