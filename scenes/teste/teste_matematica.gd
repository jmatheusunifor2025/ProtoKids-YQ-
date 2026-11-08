extends TesteBase
## Teste da Sala de Matemática: abre a sala de verdade e joga a balança
## simulando as teclas (E agarra, andar arrasta, E no prato tira o número).

const SALA := preload("res://scripts/cenario/sala_matematica.tscn")
const SOFIA := preload("res://data/exploradores/sofia.tres")
const MAYA := preload("res://data/exploradores/maya.tres")

var _sala: Node = null
var _balanca: Node2D = null


func _ready() -> void:
	Partida.exploradores = []
	_abrir_sala()
	super()


func _jogadores() -> Array[Player]:
	var lista: Array[Player] = []
	if _sala:
		for filho in _sala.get_children():
			if filho is Player:
				lista.append(filho)
	return lista


func _rodar_testes() -> void:
	await get_tree().physics_frame
	var p1: Player = _jogadores()[0]

	print("[TESTE] --- início ---")
	checar(_blocos(1).size() == 3 and _blocos(2).size() == 3, "3 números de cada lado no chão")
	checar(_balanca.get_node("Cronometro/Faixa/Conta").text == "? + ? = 10", "conta inicial '? + ? = 10'")
	checar(_balanca.get_node("Cronometro/Moldura/Tempo").text == "1:00", "cronômetro começa em 1:00")

	print("[TESTE] --- carregar ---")
	var tres := _bloco(3)
	await _preparar(p1, tres, _prato(1) + Vector2(-140, 0))
	await apertar("p1_botao1")
	checar(p1.objeto_carregado == tres and eventos.has("P1:carregou"), "E pega o número 3")
	await get_tree().physics_frame
	checar(tres.global_position.y < p1.global_position.y - 30, "o número fica acima da cabeça (carregado, não arrastado)")
	checar(tres.get_node("CollisionShape2D").disabled, "carregado, o número não colide com nada")
	var antes := tres.global_position
	await andar(p1, "direita", 10)
	checar(tres.global_position.x > antes.x + 10, "o número acompanha o jogador")
	await apertar("p1_botao2")
	checar(p1.objeto_carregado == null and tres.global_position.distance_to(p1.global_position + p1.direcao_olhar * 34.0) < 2.0, "Q larga o número na frente do jogador")
	await get_tree().physics_frame
	checar(not tres.get_node("CollisionShape2D").disabled, "no chão, o número volta a colidir")
	for i in 3:
		await get_tree().physics_frame
	await apertar("p1_botao1")
	checar(p1.objeto_carregado == tres, "E pega de novo")

	print("[TESTE] --- lado errado ---")
	var cinco := _bloco(5)
	var antes_cinco := cinco.global_position
	await apertar("p1_botao2")
	await _preparar(p1, tres, _prato(2) + Vector2(130, 0))
	await apertar("p1_botao1")
	await _levar(p1, tres, _prato(2))
	checar(not tres.no_prato, "número da esquerda NÃO entra no prato da direita (mesmo a 55 px dele)")
	await apertar("p1_botao2")
	checar(p1.objeto_carregado == null, "Q solta o número")

	print("[TESTE] --- conta errada: 3 + 5 ---")
	await _colocar(p1, tres, 1)
	checar(tres.no_prato and _balanca.bloco_no_lado(1) == tres, "3 entra no prato esquerdo sozinho")
	checar(p1.objeto_carregado == null, "jogador larga o número ao encaixar")
	checar(_balanca.get_node("Cronometro/Faixa/Conta").text == "3 + ? = 10", "conta mostra '3 + ? = 10'")
	await _colocar(p1, cinco, 2)
	checar(_balanca.bloco_no_lado(2) == cinco, "5 entra no prato direito")
	checar(_balanca._estado == "direita", "3 + 5 errado: balança inclina para a direita (lado maior)")
	checar(_balanca._indice == 0, "conta errada não avança")

	print("[TESTE] --- tirar do prato ---")
	await _preparar_no_prato(p1, 2)
	await apertar("p1_botao1")
	checar(_balanca.bloco_no_lado(2) == null and p1.objeto_carregado == cinco, "E no prato tira o 5 e o jogador já sai segurando")
	await get_tree().physics_frame
	checar(not cinco.no_prato, "o 5 não volta sozinho enquanto o jogador está perto")
	await andar(p1, "direita", 60)
	await apertar("p1_botao2")
	cinco.global_position = antes_cinco
	await _tirar(p1, 1)

	print("[TESTE] --- conta certa: 8 + 2 ---")
	await _colocar(p1, _bloco(8), 1)
	await _colocar(p1, _bloco(2), 2)
	checar(_balanca._estado == "equilibrada", "8 + 2 = 10: balança equilibra")
	checar(_balanca.get_node("Cronometro/Faixa/Conta").text == "8 + 2 = 10", "conta mostra '8 + 2 = 10'")
	await get_tree().create_timer(1.0).timeout
	checar(_balanca._indice == 1 and _balanca.get_node("Cronometro/Faixa/Conta").text == "? - ? = 3", "depois de 0,8 s vem a 2ª conta (? - ? = 3)")
	checar(_blocos(1).size() == 3 and _blocos(2).size() == 3, "números novos: 3 de cada lado")

	print("[TESTE] --- subtração: 5 - 2 ---")
	await _colocar(p1, _bloco(5), 1)
	await _colocar(p1, _bloco(2), 2)
	checar(_balanca._estado == "equilibrada" and _balanca._correto(), "5 - 2 = 3: equilibra")
	await get_tree().create_timer(1.0).timeout
	checar(_balanca._indice == 2 and _balanca.get_node("Cronometro/Faixa/Conta").text == "? + ? = 9", "vem a 3ª conta (? + ? = 9)")

	print("[TESTE] --- tempo esgotado ---")
	for i in 59:
		_balanca._passar_segundo()
	checar(_balanca.get_node("Cronometro/Moldura/Tempo").text == "0:01", "cronômetro desce até 0:01")
	_balanca._passar_segundo()
	await get_tree().physics_frame
	checar(_balanca._indice == 0 and _balanca.get_node("Cronometro/Faixa/Conta").text == "? + ? = 10", "tempo acabou: volta para a 1ª conta")
	checar(_balanca.get_node("Cronometro/Moldura/Tempo").text == "1:00", "cronômetro volta para 1:00")

	print("[TESTE] --- co-op: cada um no seu lado ---")
	Partida.exploradores = [SOFIA, MAYA]
	_sala.queue_free()
	await get_tree().process_frame
	_abrir_sala()
	await get_tree().physics_frame
	var jogadores := _jogadores()
	checar(jogadores.size() == 2, "co-op cria 2 jogadores")
	var j1: Player = jogadores[0]
	var j2: Player = jogadores[1]
	var oito := _bloco(8)
	await _preparar(j2, oito, Vector2(300, 330))
	await apertar("p2_botao1")
	checar(j2.objeto_carregado == null, "P2 NÃO agarra número do lado esquerdo")
	await _preparar(j1, oito, Vector2(300, 330))
	await apertar("p1_botao1")
	checar(j1.objeto_carregado == oito, "P1 agarra número do lado esquerdo")
	await apertar("p1_botao2")
	var dois := _bloco(2)
	await _preparar(j2, dois, Vector2(980, 330))
	await apertar("p2_botao1")
	checar(j2.objeto_carregado == dois, "P2 agarra número do lado direito")
	await apertar("p2_botao2")
	Partida.exploradores = []


# --- Auxiliares ---

func _abrir_sala() -> void:
	_sala = SALA.instantiate()
	add_child(_sala)
	_balanca = _sala.get_node("Balanca")


func _blocos(lado: int) -> Array[Node]:
	var lista: Array[Node] = []
	for bloco in _balanca._blocos:
		if is_instance_valid(bloco) and not bloco.is_queued_for_deletion() and bloco.lado == lado:
			lista.append(bloco)
	return lista


func _bloco(numero: int) -> Node2D:
	for bloco in _balanca._blocos:
		if is_instance_valid(bloco) and not bloco.is_queued_for_deletion() and bloco.numero == numero:
			return bloco
	return null


func _prato(lado: int) -> Vector2:
	return _balanca._prato_do_lado(lado).global_position


## Põe o número em `onde` e o jogador logo abaixo, olhando para ele.
func _preparar(jogador: Player, bloco: Node2D, onde: Vector2) -> void:
	_estacionar_outros(bloco)
	bloco.global_position = onde
	await posicionar(jogador, onde + Vector2(0, 36), Vector2.UP)


func _preparar_no_prato(jogador: Player, lado: int) -> void:
	await posicionar(jogador, _prato(lado) + Vector2(0, 30), Vector2.UP)


## Com o número na mão, anda na horizontal até o prato (no máximo 2 s).
func _levar(jogador: Player, bloco: Node2D, alvo: Vector2) -> void:
	var direcao := "direita" if alvo.x > bloco.global_position.x else "esquerda"
	var acao := "p%d_%s" % [jogador.id_jogador, direcao]
	Input.action_press(acao)
	for i in 120:
		await get_tree().physics_frame
		if bloco.no_prato or jogador.objeto_carregado != bloco or absf(bloco.global_position.x - alvo.x) < 20:
			break
	Input.action_release(acao)
	await get_tree().physics_frame
	print("[TESTE]        (número %d parou em %s, distância do prato %.1f, no prato: %s)" % [
		bloco.numero, bloco.global_position, bloco.global_position.distance_to(alvo), bloco.no_prato])


## Tira do caminho os números do chão que não estão sendo usados.
func _estacionar_outros(usado: Node2D) -> void:
	var i := 0
	for bloco in _balanca._blocos:
		if is_instance_valid(bloco) and bloco != usado and not bloco.no_prato:
			bloco.global_position = Vector2(60 + 50 * i, 690)
			i += 1


## Agarra o número longe do prato do lado dele e arrasta até encaixar.
func _colocar(jogador: Player, bloco: Node2D, lado: int) -> void:
	var afastado := _prato(lado) + Vector2(-130 if lado == 1 else 130, 0)
	await _preparar(jogador, bloco, afastado)
	await apertar("p%d_botao1" % jogador.id_jogador)
	await _levar(jogador, bloco, _prato(lado))


func _tirar(jogador: Player, lado: int) -> void:
	var bloco: Node2D = _balanca.bloco_no_lado(lado)
	await _preparar_no_prato(jogador, lado)
	await apertar("p%d_botao1" % jogador.id_jogador)
	await andar(jogador, "esquerda" if lado == 1 else "direita", 60)
	await apertar("p%d_botao2" % jogador.id_jogador)
	if bloco:
		bloco.global_position = _prato(lado) + Vector2(-200 if lado == 1 else 200, 60)
