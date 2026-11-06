extends Area2D
## Área do prato. E no prato chama o mesmo interagir do bloco.

@export var lado := 1


func interagir(jogador: Node2D) -> void:
	var balanca := get_parent()
	var bloco = balanca.bloco_no_lado(lado)
	if bloco == null or not bloco.pode_usar(jogador):
		return
	bloco.interagir(jogador)
