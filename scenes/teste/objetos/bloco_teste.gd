extends StaticBody2D

const ALTURA_CARREGADO := Vector2(0, -44)
const DISTANCIA_LARGAR := 30.0

var _portador: Node2D = null


func _physics_process(_delta: float) -> void:
	if _portador:
		global_position = _portador.global_position + ALTURA_CARREGADO


func interagir(jogador: Node2D) -> void:
	_portador = jogador
	$CollisionShape2D.set_deferred("disabled", true)
	jogador.segurar(self)


func largar(jogador: Node2D) -> void:
	_portador = null
	global_position = jogador.global_position + jogador.direcao_olhar * DISTANCIA_LARGAR
	$CollisionShape2D.set_deferred("disabled", false)
