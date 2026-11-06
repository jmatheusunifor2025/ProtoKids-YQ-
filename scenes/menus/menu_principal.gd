extends Control

@export_file("*.tscn") var cena_novo_jogo := "res://scenes/menus/selecao_explorador.tscn"

@onready var _novo_jogo: TextureButton = %NovoJogo
@onready var _sair: TextureButton = %Sair


func _ready() -> void:
	_novo_jogo.pressed.connect(_ao_novo_jogo)
	_sair.pressed.connect(_ao_sair)
	for botao: TextureButton in [_novo_jogo, _sair]:
		botao.mouse_entered.connect(botao.grab_focus)
	_novo_jogo.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	for id in [1, 2]:
		if evento.is_action_pressed("p%d_cima" % id) or evento.is_action_pressed("p%d_baixo" % id):
			get_viewport().set_input_as_handled()
			(_sair if _novo_jogo.has_focus() else _novo_jogo).grab_focus()
			return
		if evento.is_action_pressed("p%d_botao1" % id):
			var focado := get_viewport().gui_get_focus_owner() as TextureButton
			get_viewport().set_input_as_handled()
			if focado:
				focado.pressed.emit()
			return


func _ao_novo_jogo() -> void:
	Partida.exploradores = []
	Partida.ponto_entrada = ""
	get_tree().change_scene_to_file(cena_novo_jogo)


func _ao_sair() -> void:
	get_tree().quit()
