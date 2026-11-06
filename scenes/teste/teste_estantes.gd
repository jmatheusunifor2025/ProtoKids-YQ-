extends TesteBase
## Teste das estantes (scenes/objetos/estante.tscn): horizontal e vertical
## agarradas com E, arrastadas e soltas com Q; travar na parede solta sozinha;
## `movel` desmarcado não deixa agarrar; cada instância tem a própria colisão.

@onready var _p1: Player = $P1
@onready var _horizontal: Estante = $EstanteHorizontal
@onready var _vertical: Estante = $EstanteVertical
@onready var _fixa: Estante = $EstanteFixa


func _rodar_testes() -> void:
	await get_tree().physics_frame

	print("[TESTE] --- colisão por orientação ---")
	var forma_h: Vector2 = _horizontal.get_node("CollisionShape2D").shape.size
	var forma_v: Vector2 = _vertical.get_node("CollisionShape2D").shape.size
	checar(forma_h == Vector2(72, 32), "horizontal usa colisão 72x32")
	checar(forma_v == Vector2(28, 56), "vertical usa colisão 28x56")
	checar(_horizontal.get_node("CollisionShape2D").shape != _vertical.get_node("CollisionShape2D").shape, "cada estante tem a própria forma de colisão")

	for estante: Estante in [_horizontal, _vertical]:
		var nome := "horizontal" if estante == _horizontal else "vertical"
		print("[TESTE] --- estante %s ---" % nome)
		await posicionar(_p1, estante.global_position + Vector2(0, 50), Vector2.UP)
		await apertar("p1_botao1")
		checar(_p1.objeto_carregado == estante and eventos.has("P1:carregou"), "E agarra a estante %s" % nome)
		var antes := estante.global_position
		await andar(_p1, "baixo", 40)
		checar(estante.global_position.y > antes.y + 50, "puxando: a estante acompanha o jogador")
		var velocidade := await andar(_p1, "cima", 30)
		checar(is_equal_approx(snappedf(velocidade, 1.0), Player.VELOCIDADE), "empurrando: o jogador não fica mais lento (%.0f)" % velocidade)
		await apertar("p1_botao2")
		checar(_p1.objeto_carregado == null and eventos.has("P1:largou"), "Q solta a estante %s" % nome)
		var parada := estante.global_position
		await andar(_p1, "baixo", 20)
		checar(estante.global_position == parada, "solta, a estante fica no lugar")

	print("[TESTE] --- travar na parede ---")
	await posicionar(_p1, _horizontal.global_position + Vector2(-60, 0), Vector2.RIGHT)
	await apertar("p1_botao1")
	checar(_p1.objeto_carregado == _horizontal, "agarra a horizontal pela esquerda")
	eventos.clear()
	await andar(_p1, "direita", 240)
	checar(_p1.objeto_carregado == null and eventos.has("P1:largou"), "bateu na parede: a estante solta sozinha")
	var parede_x: float = $Parede.global_position.x
	checar(_horizontal.global_position.x + 36 <= parede_x, "a estante não atravessa a parede")

	print("[TESTE] --- estante fixa (movel = false) ---")
	await posicionar(_p1, _fixa.global_position + Vector2(0, 50), Vector2.UP)
	var antes_fixa := _fixa.global_position
	await apertar("p1_botao1")
	checar(_p1.objeto_carregado == null and not eventos.has("P1:carregou"), "E não agarra a estante fixa")
	await andar(_p1, "cima", 40)
	checar(_fixa.global_position == antes_fixa, "a estante fixa bloqueia e não se mexe")
