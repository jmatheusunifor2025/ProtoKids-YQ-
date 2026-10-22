extends Node
## Autoload "Partida": guarda as escolhas feitas nos menus para as cenas seguintes.

## Explorador de cada jogador: índice 0 = P1, índice 1 = P2 (só no co-op).
var exploradores: Array[DadosExplorador] = []
## Nome do Marker2D onde os exploradores nascem na próxima sala. Vazio = Entrada.
var ponto_entrada := ""
