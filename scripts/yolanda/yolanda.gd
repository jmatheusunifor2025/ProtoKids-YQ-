@tool
extends Node2D
## Cada sala preenche "texto" no Inspetor. O balão é o mesmo para todas.

@export_multiline var texto := "Arraste as letras até a lousa.\nCada palavra tem um minuto.":
	set(valor):
		texto = valor
		if is_node_ready():
			_aplicar_texto()


func _ready() -> void:
	_aplicar_texto()


func _aplicar_texto() -> void:
	var rotulo := get_node_or_null("Balao/Texto") as Label
	if rotulo:
		rotulo.text = texto
