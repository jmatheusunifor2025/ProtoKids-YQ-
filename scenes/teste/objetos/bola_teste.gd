extends RigidBody2D
## Objeto de teste (sem arte): bolinha de papel da Névoa, chutada com Q.

const FORCA_CHUTE := 350.0


func chutar(jogador: Node2D) -> void:
	apply_central_impulse(jogador.direcao_olhar * FORCA_CHUTE)
