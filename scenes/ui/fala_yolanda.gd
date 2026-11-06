class_name FalaYolanda
extends CanvasLayer
## Caixa de fala da Yolanda, reutilizável em qualquer cena: `await fala.mostrar(falas, rostos)`.
## E / Enter / Espaço / clique: completa a fala ou passa para a próxima. Esc: pula todas.
## Com `pausar_jogo`, o jogo fica pausado enquanto ela fala (a caixa continua rodando).

signal terminou

const LETRAS_POR_SEGUNDO := 40.0
const INTERVALO_PISCAR := 3.0
const DURACAO_PISCAR := 0.15
const DURACAO_FADE := 0.3
const ROSTO := {
	"normal": preload("res://assets/personagens/mentorCoruja/yolanda_01.png"),
	"olhos_fechados": preload("res://assets/personagens/mentorCoruja/yolanda_04.png"),
	"piscadela": preload("res://assets/personagens/mentorCoruja/yolanda_03.png"),
	"asas": preload("res://assets/personagens/mentorCoruja/yolanda_06.png"),
}

@export var pausar_jogo := true

var _falas: Array[String] = []
var _rostos: Array[String] = []
var _indice := -1
var _escrita: Tween
var _ativa := false
var _aceitando := false
var _pausado_antes := false

@onready var _caixa: Control = %Caixa
@onready var _texto: Label = %Texto
@onready var _seta: Label = %Seta
@onready var _retrato: TextureRect = %Retrato


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_caixa.hide()
	var piscar := Timer.new()
	piscar.wait_time = INTERVALO_PISCAR
	piscar.autostart = true
	piscar.timeout.connect(_piscar)
	add_child(piscar)


## Mostra as falas em ordem e só retorna quando a última for fechada.
## `rostos`: uma chave de ROSTO por fala (faltando = "normal").
func mostrar(falas: Array[String], rostos: Array[String] = []) -> void:
	if _ativa or falas.is_empty():
		return
	_falas = falas
	_rostos = rostos
	_indice = -1
	_ativa = true
	if pausar_jogo:
		_pausado_antes = get_tree().paused
		get_tree().paused = true
	_caixa.modulate.a = 0.0
	_caixa.show()
	var entrada := create_tween()
	entrada.tween_property(_caixa, "modulate:a", 1.0, DURACAO_FADE)
	await entrada.finished
	_aceitando = true
	_proxima_fala()
	await terminou


func esta_ativa() -> bool:
	return _ativa


func _unhandled_input(evento: InputEvent) -> void:
	if not _aceitando:
		return
	if evento.is_action_pressed("ui_cancel"):
		_encerrar()
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
	if _escrita and _escrita.is_running():
		_escrita.kill()
		_texto.visible_ratio = 1.0
		_seta.show()
		return
	_proxima_fala()


func _proxima_fala() -> void:
	_indice += 1
	if _indice >= _falas.size():
		_encerrar()
		return
	var fala := _falas[_indice]
	_texto.text = fala
	_texto.visible_ratio = 0.0
	_seta.hide()
	var rosto: String = _rostos[_indice] if _indice < _rostos.size() else "normal"
	_retrato.texture = ROSTO.get(rosto, ROSTO.normal)
	_escrita = create_tween()
	_escrita.tween_property(_texto, "visible_ratio", 1.0, fala.length() / LETRAS_POR_SEGUNDO)
	_escrita.finished.connect(_seta.show)


func _encerrar() -> void:
	_aceitando = false
	if _escrita:
		_escrita.kill()
	var saida := create_tween()
	saida.tween_property(_caixa, "modulate:a", 0.0, DURACAO_FADE)
	await saida.finished
	_caixa.hide()
	if pausar_jogo:
		get_tree().paused = _pausado_antes
	_ativa = false
	terminou.emit()


func _piscar() -> void:
	if _retrato.texture != ROSTO.normal:
		return
	_retrato.texture = ROSTO.olhos_fechados
	await get_tree().create_timer(DURACAO_PISCAR).timeout
	if _retrato.texture == ROSTO.olhos_fechados:
		_retrato.texture = ROSTO.normal
