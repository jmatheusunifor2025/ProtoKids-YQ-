class_name AudioExplorador
extends Node2D

@export var som_carregar: AudioStream = preload("res://assets/sounds/sfx/sfx_block_pickup.wav")
@export var som_largar: AudioStream = preload("res://assets/sounds/sfx/sfx_block_place.wav")
@export var som_empurrar: AudioStream = preload("res://assets/sounds/sfx/sfx_push_heavy.wav")

var _andando := false
var _player_movimento := AudioStreamPlayer2D.new()
var _player_acoes := AudioStreamPlayer2D.new()


func _ready() -> void:
	add_child(_player_movimento)
	add_child(_player_acoes)
	_player_movimento.finished.connect(_repetir_movimento)

	var alvo := get_parent()
	_conectar(alvo, "andou", _ao_andar)
	_conectar(alvo, "parou", _ao_parar)
	_conectar(alvo, "carregou", _tocar_acao.bind(som_carregar).unbind(1))
	_conectar(alvo, "largou", _tocar_acao.bind(som_largar).unbind(1))
	_conectar(alvo, "empurrou", _tocar_acao.bind(som_empurrar).unbind(1))


func _conectar(alvo: Node, sinal: StringName, metodo: Callable) -> void:
	if alvo.has_signal(sinal):
		alvo.connect(sinal, metodo)


func _ao_andar() -> void:
	_andando = true
	var dados: DadosExplorador = get_parent().get("dados")
	_player_movimento.stream = dados.som_movimento if dados else null
	_repetir_movimento()


func _ao_parar() -> void:
	_andando = false
	_player_movimento.stop()


func _repetir_movimento() -> void:
	if _andando and _player_movimento.stream:
		_player_movimento.play()


func _tocar_acao(som: AudioStream) -> void:
	if som == null:
		return
	_player_acoes.stream = som
	_player_acoes.play()
