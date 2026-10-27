extends Area2D
## Troca de sala quando o corpo do explorador encosta.

@export_file("*.tscn") var cena_destino := ""
@export var ponto_chegada := "Entrada"

var _trocando := false

@onready var _som: AudioStreamPlayer2D = $Som


func _ready() -> void:
	body_entered.connect(_ao_encostar)


func _ao_encostar(corpo: Node2D) -> void:
	if _trocando or cena_destino.is_empty() or not (corpo is Player):
		return
	_trocando = true
	set_deferred("monitoring", false)
	Partida.ponto_entrada = ponto_chegada
	_som.play()
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file(cena_destino)
