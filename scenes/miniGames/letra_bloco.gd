extends StaticBody2D
## Bloco de letra: E agarra, andar arrasta, Q solta.
## Gruda sozinho no próximo giz quando a letra é a da vez.

const DISTANCIA_POR_SOM := 32.0

var letra := "A"
var _jogador: Node2D = null
var _fixada := false
var _ultima_posicao_jogador := Vector2.ZERO
var _distancia_acumulada := 0.0


func definir(nova_letra: String, textura: Texture2D) -> void:
	letra = nova_letra
	$Visual.texture = textura


func _physics_process(_delta: float) -> void:
	if _fixada or _jogador == null:
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
	_tentar_fixar()


func interagir(jogador: Node2D) -> void:
	if _fixada:
		return
	_jogador = jogador
	_ultima_posicao_jogador = jogador.global_position
	_distancia_acumulada = 0.0
	add_collision_exception_with(jogador)
	jogador.add_collision_exception_with(self)
	jogador.segurar(self)


func largar(_jogador_que_solta: Node2D) -> void:
	_soltar()


## A forca chama isto antes de apagar os blocos, para o jogador não ficar segurando um nó livre.
func soltar_se() -> void:
	if _jogador == null:
		return
	var jogador := _jogador
	_soltar()
	jogador.liberar(self)


func _tentar_fixar() -> void:
	var forca := get_tree().get_first_node_in_group("forca")
	if forca == null:
		return
	if forca.destino_da_letra(letra, self) == null:
		return
	_fixada = true
	var jogador := _jogador
	_soltar()
	$CollisionShape2D.set_deferred("disabled", true)
	if jogador:
		jogador.liberar(self)
	forca.prender(self)


func _soltar() -> void:
	if _jogador == null:
		return
	remove_collision_exception_with(_jogador)
	_jogador.remove_collision_exception_with(self)
	_jogador = null
