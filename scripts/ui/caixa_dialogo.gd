class_name CaixaDialogo
extends CanvasLayer

signal aberta
signal fala_mostrada(indice: int)
signal fechada

const LETRAS_POR_SEGUNDO := 40.0

var _falas: PackedStringArray = []
var _indice := 0
var _pausado_antes := false
var _quadro_aberta := -1
var _escrita: Tween

@onready var _caixa: Control = $Caixa
@onready var _retrato: TextureRect = $Caixa/Linha/Retrato
@onready var _nome: Label = $Caixa/Linha/Coluna/Nome
@onready var _texto: Label = $Caixa/Linha/Coluna/Texto
@onready var _seta: Label = $Caixa/Linha/Coluna/Seta


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_caixa.hide()


func _unhandled_input(evento: InputEvent) -> void:
	if not esta_aberta() or Engine.get_process_frames() == _quadro_aberta:
		return
	if _apertou(evento, "botao1"):
		avancar()
	elif _apertou(evento, "botao2"):
		fechar()
	else:
		return
	get_viewport().set_input_as_handled()


func esta_aberta() -> bool:
	return _caixa.visible


func mostrar(falas: PackedStringArray, nome := "", retrato: Texture2D = null) -> void:
	if falas.is_empty() or esta_aberta():
		return
	_falas = falas
	_indice = 0
	_nome.text = nome
	_nome.visible = not nome.is_empty()
	_retrato.texture = retrato
	_retrato.visible = retrato != null
	_quadro_aberta = Engine.get_process_frames()
	_pausado_antes = get_tree().paused
	get_tree().paused = true
	_caixa.show()
	aberta.emit()
	_mostrar_fala()
	await fechada


func avancar() -> void:
	if _escrita and _escrita.is_running():
		_escrita.kill()
		_texto.visible_ratio = 1.0
		_seta.show()
		return
	_indice += 1
	if _indice >= _falas.size():
		fechar()
	else:
		_mostrar_fala()


func fechar() -> void:
	if not esta_aberta():
		return
	if _escrita:
		_escrita.kill()
	_caixa.hide()
	get_tree().paused = _pausado_antes
	fechada.emit()


func _mostrar_fala() -> void:
	var fala := _falas[_indice]
	_texto.text = fala
	_texto.visible_ratio = 0.0
	_seta.hide()
	_escrita = create_tween()
	_escrita.tween_property(_texto, "visible_ratio", 1.0, fala.length() / LETRAS_POR_SEGUNDO)
	_escrita.finished.connect(_seta.show)
	fala_mostrada.emit(_indice)


func _apertou(evento: InputEvent, botao: String) -> bool:
	return evento.is_action_pressed("p1_" + botao) or evento.is_action_pressed("p2_" + botao)
