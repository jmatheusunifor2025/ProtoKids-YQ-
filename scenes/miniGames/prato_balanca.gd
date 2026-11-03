extends Area2D
## Área do prato no chão. E tira o número e ele não volta até se afastar.

@export var lado := 1


func interagir(jogador: Node2D) -> void:
	var balanca := get_parent()
	var bloco = balanca.bloco_no_lado(lado)
	if bloco == null or not bloco.pode_usar(jogador):
		return
	balanca.retirar(bloco)
	bloco.marcar_saida()
	bloco.interagir(jogador)
