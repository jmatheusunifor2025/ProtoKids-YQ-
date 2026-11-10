class_name VerificadorVitoria
extends Node
## Ferramenta de desenvolvimento: joga sozinho do HUB até a tela de vitória para
## mostrar se o jogo é vencível. Entra em cada sala pela porta, resolve o desafio
## com a solução que o próprio desafio conhece, pega a medalha, volta ao HUB e
## coloca as três medalhas nos pedestais da sala final.
## Não testa se o caminho é possível andando: o explorador desliza até os alvos.
## Fica na raiz da árvore (sobrevive às trocas de cena). Esc fecha e volta ao menu.

const SALA_PRINCIPAL := "res://scripts/cenario/sala_principal.tscn"
const MENU := "res://scenes/menus/menu_principal.tscn"
const EXPLORADOR := preload("res://data/exploradores/sofia.tres")
const MATERIAS := [
	["portugues", "Portugues", "Sala de Português (Forca)", "Português"],
	["matematica", "Matematica", "Sala de Matemática (Balança)", "Matemática"],
	["ciencias", "Ciencias", "Sala de Ciências (Animais)", "Ciências"],
]
const LIMITE_ESPERA := 8.0
const DESLIZE := 0.35

var _lista: VBoxContainer
var _titulo: Label
var _falhou := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar_painel()


func iniciar() -> void:
	var exploradores: Array[DadosExplorador] = [EXPLORADOR]
	Partida.exploradores = exploradores
	Partida.ponto_entrada = ""
	Partida.medalhas = {}
	await _passo("Abrir o HUB", _abrir_hub)
	for m in MATERIAS:
		if _falhou:
			return
		await _passo("Entrar na " + m[2], _entrar_porta.bind(m[1]))
		await _passo("Resolver o desafio de " + m[3], _resolver.bind(m[0]))
		await _passo("Pegar a medalha de " + m[3], _pegar_medalha.bind(m[0]))
		await _passo("Voltar ao HUB", _entrar_porta.bind("Porta"))
	await _passo("Entrar na Sala Final", _entrar_porta.bind("Final"))
	await _passo("Colocar as 3 medalhas nos pedestais", _colocar_medalhas)
	await _passo("Chegar na tela de vitória", _esperar_vitoria)
	if not _falhou:
		_titulo.text = "O JOGO É VENCÍVEL!  (Esc volta ao menu)"
		_titulo.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and (_falhou or _titulo.text.begins_with("O JOGO")):
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU)
		queue_free()


# --- Passos ---

## Roda um passo. Ele devolve "" se deu certo, ou o motivo da falha.
func _passo(descricao: String, acao: Callable) -> void:
	if _falhou:
		return
	var linha := _adicionar_linha("…  " + descricao, Color.WHITE)
	var erro: String = await acao.call()
	if erro.is_empty():
		linha.text = "OK  " + descricao
		linha.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		return
	_falhou = true
	linha.text = "FALHOU  " + descricao + "\n        " + erro
	linha.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	_titulo.text = "O jogo NÃO é vencível do jeito que está  (Esc volta ao menu)"
	_titulo.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))


func _abrir_hub() -> String:
	get_tree().change_scene_to_file(SALA_PRINCIPAL)
	return "" if await _esperar_cena(SALA_PRINCIPAL) else "a sala principal não abriu"


func _entrar_porta(nome: String) -> String:
	var cena := get_tree().current_scene
	var porta := cena.get_node_or_null(nome) as Node2D
	if porta == null:
		return "não achei a porta \"%s\" em %s" % [nome, cena.name]
	var id_cena := cena.get_instance_id()
	await _deslizar(_jogador(), _ponto_de_contato(porta))
	if not await _esperar(func(): return get_tree().current_scene != null and get_tree().current_scene.get_instance_id() != id_cena):
		return "encostei na porta \"%s\" e a sala não trocou" % nome
	await _quadros(5)
	return ""


func _resolver(materia: String) -> String:
	match materia:
		"portugues":
			return await _resolver_forca()
		"matematica":
			return await _resolver_balanca()
		"ciencias":
			return await _resolver_animais()
	return "matéria desconhecida"


func _resolver_forca() -> String:
	var forca := get_tree().get_first_node_in_group("forca")
	if forca == null:
		return "não há Forca nesta sala"
	while forca._indice_palavra < forca.PALAVRAS.size():
		var indice: int = forca._indice_palavra
		var palavra: String = forca.PALAVRAS[indice].to_upper()
		while forca._indice_palavra == indice and forca._proxima < palavra.length():
			var letra := palavra[forca._proxima]
			var bloco: Node2D = null
			for candidato in forca._letras:
				if is_instance_valid(candidato) and not candidato._fixada and candidato.letra.to_upper() == letra:
					bloco = candidato
					break
			if bloco == null:
				return "na palavra \"%s\" falta mais um bloco da letra %s: o alfabeto tem só uma de cada, e \"%s\" usa %s %d vezes" % [
					palavra, letra, palavra, letra, palavra.count(letra)]
			var antes: int = forca._proxima
			var giz: Node2D = forca._espacos[forca._proxima]
			await _deslizar(bloco, giz.global_position + Vector2(0, 4))
			bloco._tentar_fixar()
			await _quadros(2)
			if forca._proxima == antes and forca._indice_palavra == indice:
				return "a letra %s não grudou no giz da palavra \"%s\"" % [letra, palavra]
		if not await _esperar(_proxima_palavra_pronta.bind(forca)):
			return "a próxima palavra não apareceu depois de \"%s\" (palavra %d, letra %d, %d espaços)" % [
				palavra, forca._indice_palavra, forca._proxima, forca._espacos.size()]
	return ""


func _proxima_palavra_pronta(forca: Node) -> bool:
	if forca._indice_palavra >= forca.PALAVRAS.size():
		return true
	var tamanho: int = forca.PALAVRAS[forca._indice_palavra].length()
	return forca._proxima == 0 and forca._espacos.size() == tamanho


func _resolver_balanca() -> String:
	var balanca := get_tree().get_first_node_in_group("balanca")
	if balanca == null:
		return "não há Balança nesta sala"
	var jogador := _jogador()
	while balanca._indice < balanca.DESAFIOS.size():
		var indice: int = balanca._indice
		var desafio: Dictionary = balanca.DESAFIOS[indice]
		var par := _par_certo(balanca, desafio)
		if par.is_empty():
			return "a conta %d (%s = %d) não tem resposta com os números que aparecem" % [indice + 1, desafio.operacao, desafio.alvo]
		for bloco in par:
			await _deslizar(jogador, bloco.global_position + Vector2(0, 30))
			bloco.interagir(jogador)
			await _deslizar(jogador, balanca._prato_do_lado(bloco.lado).global_position)
			if not await _esperar(func(): return bloco.no_prato, 2.0):
				return "o número %d não entrou no prato %s" % [bloco.numero, "esquerdo" if bloco.lado == 1 else "direito"]
		if not await _esperar(func(): return balanca._indice > indice and (balanca._indice >= balanca.DESAFIOS.size() or not balanca._avancando)):
			return "a conta %d estava certa e a balança não avançou" % (indice + 1)
		await _quadros(5)
	return ""


func _par_certo(balanca: Node, desafio: Dictionary) -> Array:
	var esquerda: Array = balanca._blocos.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion() and b.lado == 1)
	var direita: Array = balanca._blocos.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion() and b.lado == 2)
	for e in esquerda:
		for d in direita:
			var resultado: int = e.numero - d.numero if desafio.operacao == "subtracao" else e.numero + d.numero
			if resultado == int(desafio.alvo):
				return [e, d]
	return []


func _resolver_animais() -> String:
	var desafio := get_tree().get_first_node_in_group("desafio_animais")
	if desafio == null:
		return "não há desafio dos animais nesta sala"
	var total: int = desafio._ordem.size()
	while desafio.rodada < total:
		var rodada: int = desafio.rodada
		if not await _esperar(func(): return desafio._valendo, LIMITE_ESPERA * 2):
			return "a rodada %d não começou (pistas da Yolanda)" % (rodada + 1)
		var animal: Node2D = desafio.animal_da_vez
		await _deslizar(animal, desafio._alvo.global_position)
		desafio.animal_movido(animal)
		if not await _esperar(func(): return desafio.rodada > rodada, LIMITE_ESPERA * 2):
			return "levei %s ao alvo na rodada %d e não contou" % [animal.nome, rodada + 1]
	return ""


func _pegar_medalha(materia: String) -> String:
	var medalha: Area2D = null
	for no in get_tree().current_scene.find_children("Medalha", "Area2D", true, false):
		if no.get("materia") == materia:
			medalha = no
	if medalha == null:
		return "não achei a medalha de %s na sala" % materia
	if not await _esperar(func(): return medalha.visible and medalha.monitoring):
		return "a medalha de %s não apareceu depois do desafio" % materia
	await _deslizar(_jogador(), _ponto_de_contato(medalha))
	if not await _esperar(func(): return Partida.tem_medalha(materia)):
		return "encostei na medalha e ela não foi guardada"
	await _esperar(func(): return not get_tree().paused)
	return ""


func _colocar_medalhas() -> String:
	var pedestais := get_tree().current_scene.get_children().filter(func(n): return n.has_method("esta_colocada"))
	if pedestais.size() != 3:
		return "a sala final tem %d pedestais (esperava 3)" % pedestais.size()
	var jogador := _jogador()
	for pedestal in pedestais:
		await _deslizar(jogador, _ponto_de_contato(pedestal) + Vector2(0, 40))
		pedestal.interagir(jogador)
		await _quadros(3)
		if not pedestal.esta_colocada():
			return "o pedestal de %s não aceitou a medalha" % pedestal.get("materia")
	return ""


func _esperar_vitoria() -> String:
	return "" if await _esperar(func(): return get_tree().current_scene and get_tree().current_scene.scene_file_path.ends_with("vitoria.tscn")) else "as 3 medalhas foram colocadas e a vitória não abriu"


# --- Auxiliares ---

## Onde encostar num objeto: a colisão dele (o nó pode estar longe do desenho).
func _ponto_de_contato(no: Node2D) -> Vector2:
	for filho in no.get_children():
		if filho is CollisionShape2D:
			return filho.global_position
	return no.global_position


func _jogador() -> Player:
	var cena := get_tree().current_scene
	var lista := cena.find_children("", "Player", true, false) if cena else []
	return lista[0] if lista else null


func _deslizar(no: Node2D, destino: Vector2) -> void:
	if no == null:
		return
	var tween := create_tween()
	tween.tween_property(no, "global_position", destino, DESLIZE)
	await tween.finished
	await _quadros(3)


## Espera a condição ser verdadeira, pulando as falas da Yolanda. false = desistiu.
## O limite é em tempo de jogo (não depende de a máquina estar lenta).
func _esperar(condicao: Callable, limite := LIMITE_ESPERA) -> bool:
	var passado := 0.0
	while passado < limite:
		_pular_falas()
		if condicao.call():
			return true
		await get_tree().process_frame
		passado += get_process_delta_time()
	return false


func _esperar_cena(caminho: String) -> bool:
	return await _esperar(func(): return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == caminho)


func _pular_falas() -> void:
	for fala in get_tree().root.find_children("", "FalaYolanda", true, false):
		if fala._aceitando:
			for apertado in [true, false]:
				var evento := InputEventAction.new()
				evento.action = "ui_cancel"
				evento.pressed = apertado
				Input.parse_input_event(evento)
			return


func _quadros(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _montar_painel() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)
	var painel := PanelContainer.new()
	painel.position = Vector2(16, 120)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.05, 0.04, 0.1, 0.85)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(12)
	painel.add_theme_stylebox_override("panel", estilo)
	camada.add_child(painel)
	_lista = VBoxContainer.new()
	painel.add_child(_lista)
	_titulo = _adicionar_linha("Verificando se o jogo é vencível...", Color(1, 0.85, 0.4))
	_titulo.add_theme_font_size_override("font_size", 20)


func _adicionar_linha(texto: String, cor: Color) -> Label:
	var linha := Label.new()
	linha.text = texto
	linha.add_theme_color_override("font_color", cor)
	linha.add_theme_font_size_override("font_size", 15)
	_lista.add_child(linha)
	return linha
