extends Area2D

signal abriu

const ESPERA_TROCA := 0.4

@export_file("*.tscn") var destino := ""
@export var chegada := ""

var _abrindo := false


func interagir(_jogador: Node2D) -> void:
	if _abrindo or destino.is_empty():
		return
	_abrindo = true
	abriu.emit()
	Partida.ponto_entrada = chegada
	await get_tree().create_timer(ESPERA_TROCA).timeout
	get_tree().change_scene_to_file(destino)
