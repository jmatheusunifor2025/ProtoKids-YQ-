extends Area2D
## Some quando o explorador encosta e guarda o sprite na Partida.

@export var materia := "portugues"

var _pegou := false

@onready var _visual: Sprite2D = $Visual
@onready var _som: AudioStreamPlayer = $Som


func _ready() -> void:
	monitoring = false
	_ajustar_ao_mundo()
	body_entered.connect(_ao_encostar)


## A sala pode escalar o minijogo. A medalha fica no tamanho do mundo.
func _ajustar_ao_mundo() -> void:
	var pai := get_parent() as Node2D
	if pai == null:
		return
	var escala := pai.global_scale
	if absf(escala.x) < 0.001 or absf(escala.y) < 0.001:
		return
	scale = Vector2(1.0 / escala.x, 1.0 / escala.y)


func _ao_encostar(corpo: Node2D) -> void:
	if _pegou or not (corpo is Player):
		return
	_pegou = true
	set_deferred("monitoring", false)
	Partida.guardar_medalha(materia, _visual.texture.resource_path)
	_visual.visible = false
	_som.play()
