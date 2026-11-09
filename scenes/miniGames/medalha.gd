extends Area2D
## Some quando o explorador encosta e guarda o sprite na Partida.
## Em seguida a Yolanda comenta a conquista (FALAS[materia]).

const CENA_FALA := preload("res://scenes/ui/fala_yolanda.tscn")
## Matéria -> [falas, rostos]. Matéria sem entrada aqui não tem fala.
const FALAS := {
	"portugues": [
		["Caramba, essa foi difícil! Aqueles blocos até parecem estar organizados de uma forma intencionalmente difícil de empurrar...",
			"Rápido, continuem a organização!!!"],
		["olhos_fechados", "asas"],
	],
	"matematica": [
		["Vocês são muito bons em cálculos, meus alunos!!!",
			"Vamos! Juntos, iremos derrotar esses bagunceiros!"],
		["asas", "normal"],
	],
	"ciencias": [
		["Qual foi aquele último animal mesmo? Já me esqueci...",
			"Vamos nessa, sem perder tempo com essa bagunça."],
		["piscadela", "asas"],
	],
}

@export var materia := "portugues"

var _pegou := false

@onready var _visual: Sprite2D = $Visual
@onready var _som: AudioStreamPlayer = $Som


func _ready() -> void:
	monitoring = false
	# A fala da Yolanda pausa o jogo logo depois; o som da medalha não pode parar junto.
	_som.process_mode = Node.PROCESS_MODE_ALWAYS
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
	await _yolanda_comenta()


func _yolanda_comenta() -> void:
	if not FALAS.has(materia):
		return
	var falas: Array[String] = []
	falas.assign(FALAS[materia][0])
	var rostos: Array[String] = []
	rostos.assign(FALAS[materia][1])
	var fala: FalaYolanda = CENA_FALA.instantiate()
	get_tree().current_scene.add_child(fala)
	await fala.mostrar(falas, rostos)
	fala.queue_free()
