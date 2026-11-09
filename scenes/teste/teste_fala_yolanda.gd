extends TesteBase
## Teste da caixa de fala da Yolanda (scenes/ui/fala_yolanda.tscn) e das falas
## ao pegar cada medalha (scenes/miniGames/medalha.gd).

const MEDALHA := preload("res://scenes/miniGames/medalha.gd")

@onready var _p1: Player = $P1
@onready var _fala: FalaYolanda = $FalaYolanda


func _rodar_testes() -> void:
	Partida.medalhas = {}
	await get_tree().physics_frame

	print("[TESTE] --- caixa de fala ---")
	var falas: Array[String] = ["Primeira fala de teste.", "Segunda."]
	var fim := [false]
	_fala.terminou.connect(func(): fim[0] = true, CONNECT_ONE_SHOT)
	_fala.mostrar(falas)
	await _esperar_aceitar()
	checar(get_tree().paused, "o jogo pausa enquanto a Yolanda fala")
	checar(_texto() == falas[0], "mostra a 1ª fala")
	await apertar("p1_botao1")
	checar(_label().visible_ratio == 1.0, "E completa a fala que está sendo escrita")
	await apertar("p1_botao1")
	checar(_texto() == falas[1], "E de novo passa para a 2ª fala")
	await apertar("p1_botao1")
	await apertar("p1_botao1")
	await _esperar_fim(fim)
	checar(fim[0] and not get_tree().paused and not _fala.esta_ativa(), "depois da última: fecha e despausa")

	fim[0] = false
	_fala.terminou.connect(func(): fim[0] = true, CONNECT_ONE_SHOT)
	_fala.mostrar(falas)
	await _esperar_aceitar()
	await apertar("ui_cancel")
	await _esperar_fim(fim)
	checar(fim[0] and not get_tree().paused, "Esc pula todas as falas")

	for materia in ["portugues", "matematica", "ciencias"]:
		print("[TESTE] --- medalha de %s ---" % materia)
		var medalha: Area2D = get_node("Medalha_" + materia)
		medalha.monitoring = true
		await posicionar(_p1, medalha.global_position, Vector2.DOWN)
		var caixa := await _caixa_da_medalha()
		checar(Partida.tem_medalha(materia), "encostar guarda a medalha na Partida")
		checar(caixa != null, "a Yolanda aparece para comentar")
		if caixa == null:
			continue
		var esperadas: Array = MEDALHA.FALAS[materia][0]
		await _esperar_aceitar(caixa)
		checar(_texto(caixa) == esperadas[0], "1ª fala: \"%s\"" % esperadas[0].left(40))
		checar(get_tree().paused, "o jogo fica pausado durante a fala")
		await apertar("p1_botao1")
		await apertar("p1_botao1")
		checar(_texto(caixa) == esperadas[1], "2ª fala: \"%s\"" % esperadas[1])
		await apertar("p1_botao1")
		await apertar("p1_botao1")
		for i in 60:
			await get_tree().process_frame
			if not is_instance_valid(caixa):
				break
		checar(not is_instance_valid(caixa) and not get_tree().paused, "fecha, some e o jogo volta")

	Partida.medalhas = {}


func _label(caixa: FalaYolanda = _fala) -> Label:
	return caixa.get_node("%Texto")


func _texto(caixa: FalaYolanda = _fala) -> String:
	return _label(caixa).text


func _esperar_aceitar(caixa: FalaYolanda = _fala) -> void:
	for i in 300:
		if caixa._aceitando:
			return
		await get_tree().process_frame


func _esperar_fim(fim: Array) -> void:
	for i in 300:
		if fim[0]:
			return
		await get_tree().process_frame


func _caixa_da_medalha() -> FalaYolanda:
	for i in 60:
		for filho in get_children():
			if filho is FalaYolanda and filho != _fala:
				return filho
		await get_tree().process_frame
	return null
