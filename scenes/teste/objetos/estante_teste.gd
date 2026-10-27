extends StaticBody2D

const PASSO := 32.0


func interagir(jogador: Node2D) -> void:
	var direcao: Vector2 = jogador.direcao_olhar
	direcao = Vector2(signf(direcao.x), 0) if absf(direcao.x) > absf(direcao.y) else Vector2(0, signf(direcao.y))
	if move_and_collide(direcao * PASSO) == null:
		jogador.registrar_empurrao(self)
