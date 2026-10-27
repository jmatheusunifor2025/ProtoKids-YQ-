class_name AlvoBloco
extends Area2D

signal acertou(bloco: Bloco)
signal errou(bloco: Bloco)
signal esvaziou(bloco: Bloco)

const COR_ACERTO := Color(0.55, 1.0, 0.55)
const COR_ERRO := Color(1.0, 0.55, 0.55)

@export var esperado := "":
	set(novo):
		esperado = novo
		if is_node_ready():
			_rotulo.text = esperado

var bloco_atual: Bloco = null

@onready var _forma: CollisionShape2D = $CollisionShape2D
@onready var _visual: CanvasItem = $Visual
@onready var _rotulo: Label = $Rotulo


func _ready() -> void:
	_rotulo.text = esperado
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func esta_correto() -> bool:
	return bloco_atual != null and bloco_atual.valor == esperado


func _ao_entrar(corpo: Node2D) -> void:
	if corpo is Bloco and not corpo.entregue.is_connected(_conferir):
		corpo.entregue.connect(_conferir)


func _ao_sair(corpo: Node2D) -> void:
	if not corpo is Bloco:
		return
	if corpo.entregue.is_connected(_conferir):
		corpo.entregue.disconnect(_conferir)
	if corpo == bloco_atual:
		bloco_atual = null
		_visual.modulate = Color.WHITE
		esvaziou.emit(corpo)


func _conferir(bloco: Bloco) -> void:
	var area: Rect2 = _forma.shape.get_rect()
	if bloco_atual != null or not area.has_point(to_local(bloco.global_position)):
		return
	bloco_atual = bloco
	bloco.global_position = global_position
	_visual.modulate = COR_ACERTO if esta_correto() else COR_ERRO
	if esta_correto():
		acertou.emit(bloco)
	else:
		errou.emit(bloco)
