extends TesteBase
## Teste do desafio de Ciências (scenes/miniGames/desafio_animais.tscn):
## pistas da Yolanda, estantes cercando os animais, animal errado volta,
## animal certo passa de rodada, tempo esgotado restaura tudo, medalha no fim.

@onready var _p1: Player = $P1
@onready var _desafio: DesafioAnimais = $DesafioAnimais


func _rodar_testes() -> void:
	Partida.medalhas = {}
	var fala := await _fala_aberta()
	checar(fala != null and get_tree().paused, "rodada 1: a Yolanda fala e o jogo pausa")
	var da_vez := _desafio.animal_da_vez
	checar(fala != null and _texto(fala) == da_vez.pistas[0], "1ª pista de %s: \"%s\"" % [da_vez.nome, da_vez.pistas[0]])
	await _fechar(fala)
	checar(not get_tree().paused and _desafio._valendo, "depois das pistas: cronômetro valendo")
	checar(_desafio._tempo.text == "0:25", "rodada 1: cronômetro começa em 0:25")
	var tempos := range(5).map(func(i): return _desafio.tempo_da_rodada(i))
	checar(tempos == [25, 20, 15, 10, 10], "tempos das rodadas: %s" % str(tempos))

	print("[TESTE] --- estantes cercam o animal ---")
	var cima: Estante = _desafio.get_node("Estantes/%sCima" % da_vez.name)
	await posicionar(_p1, cima.global_position + Vector2(0, -40), Vector2.DOWN)
	await apertar("p1_botao1")
	checar(_p1.objeto_carregado == cima, "de fora, E pega a estante (não o animal)")
	await andar(_p1, "cima", 40)
	await apertar("p1_botao2")
	checar(cima.global_position.y < da_vez.global_position.y - 100, "a estante foi puxada e abriu o cercado")

	print("[TESTE] --- animal errado ---")
	var errado: AnimalBloco = _desafio._ordem[1]
	await posicionar(_p1, errado.global_position + Vector2(0, -40), Vector2.DOWN)
	errado.global_position = _desafio._alvo.global_position + Vector2(30, 0)
	_desafio.animal_movido(errado)
	checar(not errado.entregue and errado.global_position.distance_to(_desafio._alvo.global_position) > DesafioAnimais.ALCANCE_ALVO, "animal errado é empurrado para fora do alvo")
	checar(_desafio._aviso.text != "", "aparece o aviso de animal errado")

	print("[TESTE] --- animal certo ---")
	await posicionar(_p1, da_vez.global_position + Vector2(0, -40), Vector2.DOWN)
	await apertar("p1_botao1")
	checar(_p1.objeto_carregado == da_vez, "por cima (cercado aberto), E agarra o %s" % da_vez.nome)
	var antes := da_vez.global_position
	await andar(_p1, "cima", 15)
	checar(da_vez.global_position.y < antes.y - 20, "o animal sai do cercado acompanhando o jogador")
	da_vez.global_position = _desafio._alvo.global_position + Vector2(0, 30)
	await andar(_p1, "cima", 2)
	_desafio.animal_movido(da_vez)
	checar(da_vez.entregue and _p1.objeto_carregado == null, "no alvo: o animal certo é entregue e o jogador solta")
	fala = await _fala_aberta()
	checar(fala != null and _texto(fala) == "Isso mesmo! Era %s!" % da_vez.nome_falado, "a Yolanda confirma: \"Isso mesmo! Era %s!\"" % da_vez.nome_falado)
	await _fechar(fala)
	fala = await _fala_aberta()
	checar(_desafio.rodada == 1 and fala != null and _texto(fala) == _desafio.animal_da_vez.pistas[0], "rodada 2 começa com as pistas do próximo animal")
	await _fechar(fala)
	checar(_desafio._tempo.text == "0:20", "rodada 2: cronômetro começa em 0:20")

	print("[TESTE] --- tempo esgotado ---")
	var estante: Estante = _desafio.get_node("Estantes/%sCima" % _desafio.animal_da_vez.name)
	var lugar := estante.global_position
	estante.global_position += Vector2(0, -60)
	_desafio._segundos = 1
	fala = await _fala_aberta(3.0)
	checar(fala != null and _texto(fala).begins_with("O tempo acabou"), "tempo esgotado: a Yolanda avisa")
	await _fechar(fala)
	checar(estante.global_position == lugar, "as estantes voltam ao lugar")
	fala = await _fala_aberta()
	checar(_desafio.rodada == 1 and fala != null and _texto(fala) == _desafio.animal_da_vez.pistas[0], "a mesma rodada recomeça com as pistas")
	await _fechar(fala)

	print("[TESTE] --- até o fim ---")
	while _desafio.rodada < 5:
		var animal := _desafio.animal_da_vez
		_desafio.animal_movido(_mover_para_alvo(animal))
		fala = await _fala_aberta()
		await _fechar(fala)
		if _desafio.rodada < 5:
			fala = await _fala_aberta()
			await _fechar(fala)
	var medalha: Area2D = _desafio.get_node("Medalha")
	checar(medalha.visible and medalha.monitoring, "depois da 5ª rodada aparece a medalha de Ciências")
	await posicionar(_p1, medalha.global_position, Vector2.DOWN)
	fala = await _fala_aberta()
	checar(Partida.tem_medalha("ciencias"), "pegar a medalha guarda Ciências na Partida")
	checar(fala != null and _texto(fala).begins_with("Qual foi aquele último animal"), "e a Yolanda comenta a medalha")
	await _fechar(fala)
	Partida.medalhas = {}


func _mover_para_alvo(animal: AnimalBloco) -> AnimalBloco:
	animal.global_position = _desafio._alvo.global_position
	return animal


func _texto(fala: FalaYolanda) -> String:
	return fala.get_node("%Texto").text


func _fala_aberta(limite := 2.0) -> FalaYolanda:
	var fim := Time.get_ticks_msec() + int(limite * 1000)
	while Time.get_ticks_msec() < fim:
		for fala in get_tree().root.find_children("", "FalaYolanda", true, false):
			if fala._aceitando:
				return fala
		await get_tree().process_frame
	return null


func _fechar(fala: FalaYolanda) -> void:
	if fala == null:
		return
	await apertar("ui_cancel")
	while is_instance_valid(fala) and fala.esta_ativa():
		await get_tree().process_frame
	await get_tree().process_frame
