extends Control

const PASTA := "res://scenes/teste/"

@export var outras_cenas: Array[String] = [
	"res://scenes/menus/selecao_explorador.tscn",
	"res://scripts/cenario/sala_principal.tscn",
]

@onready var _lista: VBoxContainer = $Centro/Caixa/Lista


func _ready() -> void:
	for caminho in outras_cenas:
		_adicionar_botao(caminho.get_file().trim_suffix(".tscn").replace("_", " ").capitalize(), caminho)
	var arquivos := Array(DirAccess.get_files_at(PASTA))
	arquivos.sort()
	for arquivo: String in arquivos:
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
