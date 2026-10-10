local modulo = {quantidade = 0}
function modulo.igual(recebido, esperado, mensagem)
    assert(recebido == esperado, (mensagem or 'Valor inesperado')..': '..tostring(recebido)..' ~= '..tostring(esperado))
    modulo.quantidade = modulo.quantidade + 1
end
function modulo.verdadeiro(valor, mensagem)
    assert(valor, mensagem or 'Condição não atendida')
    modulo.quantidade = modulo.quantidade + 1
end
function modulo.falha(funcao, trecho)
    local sucesso, erro = pcall(funcao)
    assert(not sucesso and tostring(erro):find(trecho, 1, true), 'Esperava erro: '..trecho)
    modulo.quantidade = modulo.quantidade + 1
end
function modulo.preparar(forca_um, forca_dois)
    local partida = require('nucleo.partida').nova(17)
    partida.personagens = {'arthur', 'bruno'}
    local cartas = {
        [1] = {[0] = 'ibm', [3] = 'remedio_psiquiatrico', [5] = 'terno', [8] = 'imitar_os_outros', [10] = 'falar_demais'},
        [2] = {[0] = 'ibm', [3] = 'matematica', [5] = 'antigravity', [8] = 'jogos_de_tabuleiro', [10] = 'familia'}}
    partida.maos = {{{fisico = 101, associacao = cartas[1][forca_um]}}, {{fisico = 102, associacao = cartas[2][forca_dois]}}}
    return partida
end
return modulo
