extends StaticBody2D

const DISTANCIA_POR_SOM := 32.0

var _jogador: Node2D = null
var _ultima_posicao_jogador := Vector2.ZERO
var _distancia_acumulada := 0.0


func _physics_process(_delta: float) -> void:
	if _jogador == null:
		return
	var deslocamento := _jogador.global_position - _ultima_posicao_jogador
	_ultima_posicao_jogador = _jogador.global_position
	if deslocamento == Vector2.ZERO:
		return
	if move_and_collide(deslocamento):
		var jogador := _jogador
		_soltar()
		jogador.liberar(self)
		return
	_distancia_acumulada += deslocamento.length()
	if _distancia_acumulada >= DISTANCIA_POR_SOM:
		_distancia_acumulada = 0.0
		_jogador.registrar_empurrao(self)


func interagir(jogador: Node2D) -> void:
	_jogador = jogador
	_ultima_posicao_jogador = jogador.global_position
	_distancia_acumulada = 0.0
	add_collision_exception_with(jogador)
	jogador.add_collision_exception_with(self)
	jogador.segurar(self, true)


func largar(_jogador_que_solta: Node2D) -> void:
	_soltar()


func _soltar() -> void:
	if _jogador == null:
		return
	remove_collision_exception_with(_jogador)
	_jogador.remove_collision_exception_with(self)
	_jogador = null
