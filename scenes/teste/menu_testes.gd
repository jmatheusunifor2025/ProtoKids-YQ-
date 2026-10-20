extends Control
## Cena principal provisória: lista as cenas de teste (scenes/teste/teste_*.tscn)
## e abre a escolhida. Esc dentro de um teste volta para cá.
## Cena de teste nova aparece aqui sozinha, sem editar este script.

const PASTA := "res://scenes/teste/"

## Cenas fora de scenes/teste que também aparecem no topo do menu.
@export var outras_cenas: Array[String] = ["res://scenes/menus/selecao_explorador.tscn"]

@onready var _lista: VBoxContainer = $Centro/Caixa/Lista


func _ready() -> void:
	for caminho in outras_cenas:
		_adicionar_botao(caminho.get_file().trim_suffix(".tscn").replace("_", " ").capitalize(), caminho)
	var arquivos := Array(DirAccess.get_files_at(PASTA))
	arquivos.sort()
	for arquivo: String in arquivos:
		# No jogo exportado as cenas aparecem como ".tscn.remap".
		arquivo = arquivo.trim_suffix(".remap")
		if not (arquivo.begins_with("teste_") and arquivo.ends_with(".tscn")):
			continue
		_adicionar_botao(arquivo.trim_prefix("teste_").trim_suffix(".tscn").replace("_", " ").capitalize(), PASTA + arquivo)
	if _lista.get_child_count() > 0:
		_lista.get_child(0).grab_focus()


func _adicionar_botao(texto: String, caminho: String) -> void:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(360, 48)
	botao.pressed.connect(get_tree().change_scene_to_file.bind(caminho))
	_lista.add_child(botao)
