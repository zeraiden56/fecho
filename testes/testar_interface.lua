local apoio = require('testes.apoio')
local disposicao = require('interface.disposicao')
local animacoes = require('interface.animacoes')
for _, resolucao in ipairs({{800,450}, {960,540}, {1280,720}, {1920,1080}, {1600,1000}}) do
    local escala, margem_horizontal, margem_vertical = disposicao.transformacao(resolucao[1], resolucao[2])
    for quantidade = 2, 3 do
        for jogador = 1, 2 do
            local posicoes = disposicao.mao(quantidade, jogador)
            local centro = (posicoes[1].horizontal + posicoes[#posicoes].horizontal) / 2
            apoio.igual(centro, 640)
            apoio.igual(disposicao.largura_carta / disposicao.altura_carta, 5 / 7)
            for _, posicao in ipairs(posicoes) do
                local horizontal, vertical = disposicao.coordenadas(posicao.horizontal * escala + margem_horizontal,
                    posicao.vertical * escala + margem_vertical, resolucao[1], resolucao[2])
                apoio.verdadeiro(disposicao.contem(posicao, horizontal, vertical))
                apoio.verdadeiro(not disposicao.contem(posicao, horizontal + 300, vertical + 300))
                local raio_horizontal = posicao.escala * (70 * math.abs(math.cos(posicao.angulo)) + 98 * math.abs(math.sin(posicao.angulo)))
                local raio_vertical = posicao.escala * (98 * math.abs(math.cos(posicao.angulo)) + 70 * math.abs(math.sin(posicao.angulo)))
                apoio.verdadeiro(posicao.horizontal - raio_horizontal > 0 and posicao.horizontal + raio_horizontal < 1280)
                apoio.verdadeiro(posicao.vertical - raio_vertical > 0 and posicao.vertical + raio_vertical < 650)
            end
        end
    end
end
local atual = 0
for _ = 1, 60 do atual = animacoes.interpolar(atual, 1, 1 / 60) end
apoio.verdadeiro(atual > 0.99 and atual < 1)
for _ = 1, 60 do atual = animacoes.interpolar(atual, 0, 1 / 60) end
apoio.verdadeiro(atual < 0.01 and atual > 0)
for _, caminho in ipairs({'interface/menu.lua', 'interface/mesa.lua', 'interface/resultados.lua'}) do
    local arquivo = assert(io.open(caminho))
    local texto = arquivo:read('*a'); arquivo:close()
    apoio.verdadeiro(not texto:find('%[Enter%]') and not texto:find('%[[CPFAR]%]') and not texto:find('Esc:') and not texto:find('H:'), 'Atalho permanente na interface')
end
print('Geometria, proporção, interpolação e textos da interface: OK')
