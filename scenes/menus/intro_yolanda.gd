extends Control

const LETRAS_POR_SEGUNDO := 40.0
const INTERVALO_PISCAR := 3.0
const DURACAO_PISCAR := 0.15
const ROSTO := {
	"normal": preload("res://assets/personagens/mentorCoruja/yolanda_01.png"),
	"olhos_fechados": preload("res://assets/personagens/mentorCoruja/yolanda_04.png"),
	"piscadela": preload("res://assets/personagens/mentorCoruja/yolanda_03.png"),
	"asas": preload("res://assets/personagens/mentorCoruja/yolanda_06.png"),
}

@export_file("*.tscn") var proxima_cena := "res://scripts/cenario/sala_principal.tscn"

@export var falas: Array[String] = [
	"Bom vê-los aqui, caros alunos!!",
	"Um grande mal tomou a biblioteca, Os Espíritos da Bagunça!",
	"Precisam me ajudar, por favor! Juntos, organizem as salas para restaurar a ordem e paz na biblioteca, antes que isso se espalhe pela escola toda.",
	"Sejam rápidos, pois o tempo é curto.",
	"Ah! Quase me esqueci...",
	"Depois de organizar as salas, medalhões surgirão. Levem-nos para a sala das estrelas para derrotamos esses bagunceiros!!",
	"Ajudarei vocês nessa jornadas meu queridos, e, com a cooperação de todos, iremos vencer!!!",
]
@export var rostos: Array[String] = ["asas", "normal", "normal", "normal", "piscadela", "normal", "asas"]

var _indice := -1
var _escrita: Tween
var _saindo := false

@onready var _texto: Label = %Texto
@onready var _seta: Label = %Seta
@onready var _retrato: TextureRect = %Retrato
@onready var _caixa: Control = %Caixa


func _ready() -> void:
	var piscar := Timer.new()
	piscar.wait_time = INTERVALO_PISCAR
	piscar.autostart = true
	piscar.timeout.connect(_piscar)
	add_child(piscar)
	_caixa.modulate.a = 0.0
	var entrada := create_tween()
	entrada.tween_property(_caixa, "modulate:a", 1.0, 0.4)
	await entrada.finished
	_proxima_fala()


func _unhandled_input(evento: InputEvent) -> void:
	if _saindo:
		return
	if evento.is_action_pressed("ui_cancel"):
		_ir_para_sala()
	elif _avanca(evento):
		_avancar()
	else:
		return
	get_viewport().set_input_as_handled()


func _avanca(evento: InputEvent) -> bool:
	if evento is InputEventMouseButton:
		return evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT
	for acao in ["ui_accept", "p1_botao1", "p2_botao1"]:
		if evento.is_action_pressed(acao):
			return true
	return false


func _avancar() -> void:
	if _indice < 0:
		return
	if _escrita and _escrita.is_running():
		_escrita.kill()
		_texto.visible_ratio = 1.0
		_seta.show()
		return
	_proxima_fala()


func _proxima_fala() -> void:
	_indice += 1
	if _indice >= falas.size():
		_ir_para_sala()
		return
	var fala := falas[_indice]
	_texto.text = fala
	_texto.visible_ratio = 0.0
	_seta.hide()
	_retrato.texture = ROSTO.get(rostos[_indice] if _indice < rostos.size() else "normal", ROSTO.normal)
	_escrita = create_tween()
	_escrita.tween_property(_texto, "visible_ratio", 1.0, fala.length() / LETRAS_POR_SEGUNDO)
	_escrita.finished.connect(_seta.show)


func _piscar() -> void:
	if _retrato.texture != ROSTO.normal:
		return
	_retrato.texture = ROSTO.olhos_fechados
	await get_tree().create_timer(DURACAO_PISCAR).timeout
	if _retrato.texture == ROSTO.olhos_fechados:
		_retrato.texture = ROSTO.normal


func _ir_para_sala() -> void:
	_saindo = true
	if _escrita:
		_escrita.kill()
	var saida := create_tween()
	saida.tween_property(self, "modulate", Color.BLACK, 0.4)
	await saida.finished
	get_tree().change_scene_to_file(proxima_cena)
