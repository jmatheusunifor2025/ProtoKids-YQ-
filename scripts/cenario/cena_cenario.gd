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
		jogador.position = _posicao_do_jogador(i, escolhidos.size(), marca)
		add_child(jogador)
	Partida.ponto_entrada = ""


## Sala com EntradaEsquerda e EntradaDireita separa os dois jogadores.
## Sala sem esses marcadores continua nascendo na Entrada, com o P2 ao lado.
func _posicao_do_jogador(indice: int, total: int, marca: Marker2D) -> Vector2:
	if total >= 2:
		var esquerda := get_node_or_null("EntradaEsquerda") as Marker2D
		var direita := get_node_or_null("EntradaDireita") as Marker2D
		if esquerda and direita:
			return esquerda.position if indice == 0 else direita.position
	return marca.position + SEPARACAO_P2 * indice


func _marca_de_chegada() -> Marker2D:
	if not Partida.ponto_entrada.is_empty():
		var achada := get_node_or_null(Partida.ponto_entrada) as Marker2D
		if achada:
			return achada
	return $Entrada
