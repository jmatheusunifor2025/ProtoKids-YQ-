class_name CenaCenario
extends Node2D
## Coloca os exploradores da Partida em cima de um Marker2D.

const CENA_PLAYER := preload("res://scenes/player/player.tscn")
const EXPLORADOR_PADRAO := preload("res://data/exploradores/sofia.tres")
const SEPARACAO_P2 := Vector2(48, 0)


func _ready() -> void:
	var escolhidos: Array[DadosExplorador] = Partida.exploradores
	if escolhidos.is_empty():
		escolhidos = [EXPLORADOR_PADRAO]
	var marca := _marca_de_chegada()
	for i in escolhidos.size():
		var jogador: Player = CENA_PLAYER.instantiate()
		jogador.id_jogador = i + 1
		jogador.dados = escolhidos[i]
		jogador.position = marca.position + SEPARACAO_P2 * i
		add_child(jogador)
	Partida.ponto_entrada = ""


func _marca_de_chegada() -> Marker2D:
	if not Partida.ponto_entrada.is_empty():
		var achada := get_node_or_null(Partida.ponto_entrada) as Marker2D
		if achada:
			return achada
	return $Entrada
