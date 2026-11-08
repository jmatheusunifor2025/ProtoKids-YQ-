@tool
extends Node2D
## Alvo quadriculado do desafio de Ciências (desenhado, sem arte).
## O DesafioAnimais muda `destaque` para dar retorno (acerto/erro).

@export var tamanho := 96.0:
	set(valor):
		tamanho = valor
		queue_redraw()
@export var casas := 4:
	set(valor):
		casas = maxi(valor, 1)
		queue_redraw()
@export var cor_clara := Color(0.98, 0.93, 0.78, 0.85)
@export var cor_escura := Color(0.35, 0.6, 0.3, 0.85)
@export var cor_borda := Color(0.95, 0.75, 0.25, 1.0)

var destaque := Color.WHITE:
	set(valor):
		destaque = valor
		queue_redraw()


func _draw() -> void:
	var lado := tamanho / casas
	var inicio := -Vector2.ONE * tamanho / 2.0
	for x in casas:
		for y in casas:
			var cor := cor_clara if (x + y) % 2 == 0 else cor_escura
			draw_rect(Rect2(inicio + Vector2(x, y) * lado, Vector2.ONE * lado), cor * destaque)
	draw_rect(Rect2(inicio, Vector2.ONE * tamanho), cor_borda * destaque, false, 4.0)
