extends StaticBody2D
## Bloco de letra: E dá um empurrão e solta. Continuar andando não leva a letra.
## Gruda sozinha no giz da vez.

## Um toque afasta a letra o bastante para sair de cima do explorador.
const EMPURRAO := 48.0

var letra := "A"
var _jogador: Node2D = null
var _fixada := false


func definir(nova_letra: String, textura: Texture2D) -> void:
	letra = nova_letra
	$Visual.texture = textura


func interagir(jogador: Node2D) -> void:
	if _fixada:
		return
	var pessoa := jogador as Player
	var direcao := _eixo_do_empurrao(pessoa)
	add_collision_exception_with(pessoa)
	pessoa.add_collision_exception_with(self)
	move_and_collide(direcao * EMPURRAO)
	remove_collision_exception_with(pessoa)
	pessoa.remove_collision_exception_with(self)
	pessoa.registrar_empurrao(self)
	_tentar_fixar()


## Lateral empurra só no X. Cima ou baixo empurra só no Y.
func _eixo_do_empurrao(pessoa: Player) -> Vector2:
	var delta := global_position - pessoa.global_position
	if absf(delta.x) <= 1.0 and absf(delta.y) <= 1.0:
		delta = pessoa.direcao_olhar
	if absf(delta.x) > absf(delta.y):
		return Vector2(signf(delta.x), 0.0)
	if absf(delta.y) > 0.0:
		return Vector2(0.0, signf(delta.y))
	return Vector2.DOWN


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
