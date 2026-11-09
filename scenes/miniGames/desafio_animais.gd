class_name DesafioAnimais
extends Node2D
## Desafio de Ciências: 5 rodadas. Em cada uma a Yolanda dá as pistas de um animal
## e os exploradores têm um tempo (25 s na 1ª, 5 s a menos a cada rodada, mínimo 10)
## para tirá-lo de trás das estantes
## e levá-lo até o alvo quadriculado. Animal errado no alvo é empurrado de volta.
## Tempo esgotado: animais e estantes voltam ao lugar e a rodada recomeça.
## Depois da última rodada, aparece a medalha de Ciências.
## Animais = filhos AnimalBloco de $Animais (nome, pistas e imagem no Inspector).

signal concluido

const CENA_FALA := preload("res://scenes/ui/fala_yolanda.tscn")
const ALCANCE_ALVO := 48.0
const EMPURRAO_ERRO := 90.0
const COR_ACERTO := Color(0.6, 1.0, 0.6)
const COR_ERRO := Color(1.0, 0.55, 0.55)

## Tempo da 1ª rodada; cada rodada seguinte tem `reducao_por_rodada` a menos,
## sem passar de `tempo_minimo` (25, 20, 15, 10, 10).
@export var tempo_inicial := 25
@export var reducao_por_rodada := 5
@export var tempo_minimo := 10
## Embaralha a ordem dos animais a cada partida.
@export var ordem_aleatoria := true

var rodada := 0
var animal_da_vez: AnimalBloco = null

var _ordem: Array[AnimalBloco] = []
var _segundos := 0
var _valendo := false
var _inicio := {}

@onready var _alvo: Node2D = $Alvo
@onready var _animais: Node = $Animais
@onready var _estantes: Node = $Estantes
@onready var _relogio: Timer = $Cronometro/Relogio
@onready var _tempo: Label = $Cronometro/Moldura/Tempo
@onready var _titulo: Label = $Cronometro/Faixa/Titulo
@onready var _pistas: Label = $Cronometro/Pistas/Texto
@onready var _painel_pistas: Control = $Cronometro/Pistas
@onready var _aviso: Label = $Cronometro/Aviso


func _ready() -> void:
	add_to_group("desafio_animais")
	_relogio.wait_time = 1.0
	_relogio.timeout.connect(_passar_segundo)
	for no in _animais.get_children() + _estantes.get_children():
		_inicio[no] = no.global_position
	for animal in _animais.get_children():
		if animal is AnimalBloco:
			_ordem.append(animal)
	if ordem_aleatoria:
		_ordem.shuffle()
	_aviso.text = ""
	_painel_pistas.hide()
	_mostrar_tempo()
	await get_tree().process_frame
	_comecar_rodada()


## Chamado pelo AnimalBloco enquanto é arrastado.
func animal_movido(animal: AnimalBloco) -> void:
	if not _valendo or animal.entregue:
		return
	if animal.global_position.distance_to(_alvo.global_position) > ALCANCE_ALVO:
		return
	if animal == animal_da_vez:
		_acertou(animal)
	else:
		_errou(animal)


func _comecar_rodada() -> void:
	animal_da_vez = _ordem[rodada]
	_titulo.text = "Rodada %d de %d" % [rodada + 1, _ordem.size()]
	_pistas.text = " ".join(animal_da_vez.pistas)
	_painel_pistas.hide()
	_segundos = tempo_da_rodada()
	_mostrar_tempo()
	await _yolanda(animal_da_vez.pistas, ["normal"])
	_painel_pistas.show()
	_valendo = true
	_relogio.start()


func tempo_da_rodada(indice := rodada) -> int:
	return maxi(tempo_inicial - reducao_por_rodada * indice, tempo_minimo)


func _acertou(animal: AnimalBloco) -> void:
	_valendo = false
	_relogio.stop()
	animal.marcar_entregue(_alvo.global_position)
	_piscar_alvo(COR_ACERTO)
	await _yolanda(["Isso mesmo! Era %s!" % animal.nome_falado], ["asas"])
	animal.hide()
	rodada += 1
	if rodada >= _ordem.size():
		_terminar()
	else:
		_comecar_rodada()


func _errou(animal: AnimalBloco) -> void:
	animal.soltar_se()
	var saida := (animal.global_position - _alvo.global_position).normalized()
	if saida == Vector2.ZERO:
		saida = Vector2.DOWN
	animal.move_and_collide(saida * EMPURRAO_ERRO)
	animal.piscar(COR_ERRO)
	_piscar_alvo(COR_ERRO)
	_avisar("Esse não é o animal das pistas!")


func _passar_segundo() -> void:
	_segundos -= 1
	_mostrar_tempo()
	if _segundos <= 0:
		_tempo_esgotado()


func _tempo_esgotado() -> void:
	_valendo = false
	_relogio.stop()
	await _yolanda(["O tempo acabou! Vamos tentar de novo, vou repetir as pistas..."], ["olhos_fechados"])
	_restaurar()
	_comecar_rodada()


## Animais que ainda não foram entregues e todas as estantes voltam ao começo.
func _restaurar() -> void:
	for estante in _estantes.get_children():
		if estante.has_method("soltar_se"):
			estante.soltar_se()
		estante.global_position = _inicio[estante]
	for animal in _ordem:
		if not animal.entregue:
			animal.restaurar(_inicio[animal])


func _terminar() -> void:
	_painel_pistas.hide()
	_titulo.text = "Desafio concluído!"
	$Medalha.visible = true
	$Medalha.monitoring = true
	concluido.emit()


func _yolanda(falas: Array, rostos: Array) -> void:
	var lista: Array[String] = []
	lista.assign(falas)
	var caras: Array[String] = []
	caras.assign(rostos)
	var fala: FalaYolanda = CENA_FALA.instantiate()
	add_child(fala)
	await fala.mostrar(lista, caras)
	fala.queue_free()


func _mostrar_tempo() -> void:
	_tempo.text = "0:%02d" % maxi(_segundos, 0)


func _avisar(texto: String) -> void:
	_aviso.text = texto
	await get_tree().create_timer(1.5).timeout
	if _aviso.text == texto:
		_aviso.text = ""


func _piscar_alvo(cor: Color) -> void:
	_alvo.destaque = cor
	var volta := create_tween()
	volta.tween_property(_alvo, "destaque", Color.WHITE, 0.6)
