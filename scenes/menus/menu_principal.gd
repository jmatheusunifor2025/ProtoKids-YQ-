extends Control

const VERIFICADOR := preload("res://scenes/teste/verificador_vitoria.gd")

## Controles mostrados no bloco de AJUDA: [tecla, o que faz].
## Mantenha em sincronia com o Mapa de Entrada (project.godot → [input]).
const CONTROLES_P1 := [
	["W A S D", "Andar"],
	["E", "Pegar / Usar"],
	["Q", "Largar"],
]
const CONTROLES_P2 := [
	["Setas", "Andar"],
	["Enter", "Pegar / Usar"],
	["Shift Dir.", "Largar"],
]
## Ação compartilhada (`pedir_dica`): qualquer jogador pode apertar.
const CONTROLES_JUNTOS := [["R", ""], ["H", ""], ["Tab", "Pedir dica à Yolanda"]]

const COR_TEXTO_PLACA := Color(0.99, 0.93, 0.72)
const COR_TEXTO_PLACA_FOCO := Color(0.25, 0.08, 0.04)
const COR_TEXTO_TECLA := Color(1.0, 0.94, 0.78)
const COR_TEXTO_ACAO := Color(0.3, 0.14, 0.05)

@export_file("*.tscn") var cena_novo_jogo := "res://scenes/menus/selecao_explorador_moderna.tscn"
@export var estilo_tecla: StyleBox
@export var fonte_controles: Font

@onready var _novo_jogo: TextureButton = %NovoJogo
@onready var _ajuda: TextureButton = %Ajuda
@onready var _sair: TextureButton = %Sair
@onready var _painel_ajuda: Control = %PainelAjuda
@onready var _voltar: TextureButton = %Voltar
## Só mouse (sem foco pelo teclado) e só no editor/debug: some no jogo exportado.
@onready var _testar_vitoria: Button = %TestarVitoria
@onready var _botoes: Array[TextureButton] = [_novo_jogo, _ajuda, _sair]


func _ready() -> void:
	_novo_jogo.pressed.connect(_ao_novo_jogo)
	_ajuda.pressed.connect(_abrir_ajuda)
	_sair.pressed.connect(_ao_sair)
	_voltar.pressed.connect(_fechar_ajuda)
	_testar_vitoria.visible = OS.is_debug_build()
	_testar_vitoria.pressed.connect(_ao_testar_vitoria)
	for botao: TextureButton in _botoes:
		botao.mouse_entered.connect(botao.grab_focus)
	_voltar.mouse_entered.connect(_voltar.grab_focus)
	# O texto das placas sem desenho (Ajuda/Voltar) acompanha a cor da placa.
	for botao: TextureButton in [_ajuda, _voltar]:
		var texto: Label = botao.get_node("Texto")
		botao.focus_entered.connect(texto.add_theme_color_override.bind("font_color", COR_TEXTO_PLACA_FOCO))
		botao.focus_exited.connect(texto.add_theme_color_override.bind("font_color", COR_TEXTO_PLACA))
	_montar_controles($PainelAjuda/Moldura/Conteudo/Colunas/Player1/Controles, CONTROLES_P1)
	_montar_controles($PainelAjuda/Moldura/Conteudo/Colunas/Player2/Controles, CONTROLES_P2)
	_montar_controles($PainelAjuda/Moldura/Conteudo/Juntos/Controles, CONTROLES_JUNTOS)
	_novo_jogo.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	if _painel_ajuda.visible:
		_input_ajuda(evento)
		return
	for id in [1, 2]:
		if evento.is_action_pressed("p%d_cima" % id):
			get_viewport().set_input_as_handled()
			_mover_foco(-1)
			return
		if evento.is_action_pressed("p%d_baixo" % id):
			get_viewport().set_input_as_handled()
			_mover_foco(1)
			return
		if evento.is_action_pressed("p%d_botao1" % id):
			_apertar_focado()
			return


## Com a ajuda aberta: botão 1 aperta "Voltar"; botão 2 ou Esc fecham direto.
func _input_ajuda(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar_ajuda()
		return
	for id in [1, 2]:
		if evento.is_action_pressed("p%d_botao2" % id):
			get_viewport().set_input_as_handled()
			_fechar_ajuda()
			return
		if evento.is_action_pressed("p%d_botao1" % id):
			_apertar_focado()
			return
	# Nada do menu de trás reage enquanto a ajuda está aberta.
	if evento.is_pressed():
		get_viewport().set_input_as_handled()


func _mover_foco(passo: int) -> void:
	var atual := _botoes.find(get_viewport().gui_get_focus_owner())
	_botoes[posmod(atual + passo, _botoes.size())].grab_focus()


func _apertar_focado() -> void:
	get_viewport().set_input_as_handled()
	var focado := get_viewport().gui_get_focus_owner() as BaseButton
	if focado:
		focado.pressed.emit()


func _abrir_ajuda() -> void:
	_painel_ajuda.visible = true
	_voltar.grab_focus()


func _fechar_ajuda() -> void:
	_painel_ajuda.visible = false
	_ajuda.grab_focus()


## Cria, para cada controle, uma "tecla" desenhada e o texto do que ela faz.
func _montar_controles(destino: Container, controles: Array) -> void:
	for controle: Array in controles:
		var tecla := Label.new()
		tecla.text = controle[0]
		tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tecla.add_theme_stylebox_override("normal", estilo_tecla)
		tecla.add_theme_color_override("font_color", COR_TEXTO_TECLA)
		_aplicar_fonte(tecla)
		destino.add_child(tecla)
		if controle[1] == "":
			continue
		var acao := Label.new()
		acao.text = controle[1]
		acao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		acao.add_theme_color_override("font_color", COR_TEXTO_ACAO)
		_aplicar_fonte(acao)
		destino.add_child(acao)


func _aplicar_fonte(rotulo: Label) -> void:
	if fonte_controles:
		rotulo.add_theme_font_override("font", fonte_controles)
	rotulo.add_theme_font_size_override("font_size", 17)


func _ao_novo_jogo() -> void:
	Partida.exploradores = []
	Partida.ponto_entrada = ""
	get_tree().change_scene_to_file(cena_novo_jogo)


func _ao_sair() -> void:
	get_tree().quit()


func _ao_testar_vitoria() -> void:
	var verificador: Node = VERIFICADOR.new()
	get_tree().root.add_child(verificador)
	verificador.iniciar()
