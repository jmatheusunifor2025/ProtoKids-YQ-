extends TesteBase

const SOFIA := preload("res://data/exploradores/sofia.tres")

var _sinais: Array[String] = []

@onready var _menu: SelecaoExplorador = $SelecaoExplorador


func _rodar_testes() -> void:
	for sinal in ["escolha_confirmada", "escolha_recusada", "partida_iniciada"]:
		_menu.connect(sinal, func(_a = null, _b = null): _sinais.append(sinal))
	await get_tree().process_frame
	var sofia := _menu.elenco.exploradores.find(SOFIA)

	print("[TESTE] --- single-player ---")
	checar(_menu.cursor_de(1) == sofia, "P1 começa no primeiro explorador jogável (Sofia)")
	await apertar("p1_esquerda")
	await apertar("p1_botao1")
	checar(not _menu.confirmou(1) and _sinais.has("escolha_recusada"), "P1 não escolhe explorador To Be Done")
	await apertar("p1_direita")
	await apertar("p1_botao1")
	checar(_menu.confirmou(1) and _menu.cursor_de(1) == sofia, "P1 escolhe a Sofia com E")

	print("[TESTE] --- co-op ---")
	await apertar("p2_botao1")
	checar(_menu.esta_ativo(2), "P2 entra no co-op com Enter")
	checar(not _menu.pode_comecar(), "não começa com P2 sem escolher")
	for i in 4:
		if _menu.cursor_de(2) == sofia:
			break
		await apertar("p2_direita")
	_sinais.clear()
	await apertar("p2_botao1")
	checar(not _menu.confirmou(2) and _sinais.has("escolha_recusada"), "P2 não pega a Sofia já escolhida pelo P1")

	await apertar("p1_botao2")
	checar(not _menu.confirmou(1), "P1 desfaz a escolha com Q")
	await apertar("p2_botao1")
	checar(_menu.confirmou(2), "P2 escolhe a Sofia depois que o P1 soltou")
	_sinais.clear()
	await apertar("p1_botao1")
	checar(not _menu.confirmou(1) and _sinais.has("escolha_recusada"), "P1 agora não pode pegar a Sofia")

	await apertar("p2_botao2")
	await apertar("p2_botao2")
	checar(not _menu.esta_ativo(2), "P2 desfaz e sai do co-op com Shift direito")

	print("[TESTE] --- começar ---")
	await apertar("p1_botao1")
	checar(_menu.pode_comecar(), "P1 escolhe e pode começar sozinho")
	_sinais.clear()
	await apertar("p1_botao1")
	checar(_sinais.has("partida_iniciada"), "E de novo inicia a partida")
	checar(Partida.exploradores.size() == 1 and Partida.exploradores[0] == SOFIA, "Partida guarda só a Sofia, como P1")
	Partida.exploradores = []
