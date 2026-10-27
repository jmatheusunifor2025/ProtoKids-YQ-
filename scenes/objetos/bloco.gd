class_name Bloco
extends AnimatableBody2D

signal entregue(bloco: Bloco)

const ALTURA_CARREGADO := Vector2(0, -44)
const DISTANCIA_LARGAR := 30.0

@export var valor := "":
	set(novo):
		valor = novo
		if is_node_ready():
			_rotulo.text = valor

var _portador: Node2D = null

@onready var _forma: CollisionShape2D = $CollisionShape2D
@onready var _rotulo: Label = $Rotulo


func _ready() -> void:
	_rotulo.text = valor


func _physics_process(_delta: float) -> void:
	if _portador:
		global_position = _portador.global_position + ALTURA_CARREGADO


func interagir(jogador: Node2D) -> void:
	_portador = jogador
	_forma.set_deferred("disabled", true)
	jogador.segurar(self)


func largar(jogador: Node2D) -> void:
	_portador = null
	global_position = jogador.global_position + jogador.direcao_olhar * DISTANCIA_LARGAR
	_forma.set_deferred("disabled", false)
	for i in 3:
		await get_tree().physics_frame
	if _portador == null:
		entregue.emit(self)
