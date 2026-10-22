class_name SelecaoExplorador
extends Control
## Menu "Escolha seu explorador" (SGDD, cena 03).
## Single-player: P1 escolhe 1. Co-op: P2 entra com o botão 1 e escolhe um
## explorador DIFERENTE. Exploradores sem sprite_frames aparecem como
## "Em breve · To Be Done" e não podem ser escolhidos.
## Não toca som: emite signals (o filho AudioPorSinal escuta).

signal cursor_movido(jogador: int)
signal escolha_confirmada(jogador: int, dados: DadosExplorador)
signal escolha_recusada(jogador: int)
signal escolha_cancelada(jogador: int)
signal partida_iniciada(exploradores: Array)

const CENA_CARD := preload("res://scenes/menus/card_explorador.tscn")
const MENU_TESTES := "res://scenes/teste/menu_testes.tscn"

@export var elenco: ElencoExploradores
## Cena aberta depois da escolha. Vazio = fica no menu (usado nos testes).
@export_file("*.tscn") var proxima_cena := "res://scenes/teste/teste_sala_livre.tscn"

var _cards: Array[CardExplorador] = []
var _ativo := {1: true, 2: false}
var _cursor := {1: 0, 2: 0}
var _confirmado := {1: false, 2: false}

@onready var _lista_cards: HBoxContainer = $Centro/Coluna/Cards
@onready var _dica: Label = $Centro/Coluna/Dica
@onready var _mensagem: Label = $Centro/Coluna/Mensagem


func _ready() -> void:
	for dados in elenco.exploradores:
		var card: CardExplorador = CENA_CARD.instantiate()
		_lista_cards.add_child(card)
		card.configurar(dados)
		_cards.append(card)
	_cursor[1] = _primeiro_livre(1)
	_atualizar()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and ResourceLoader.exists(MENU_TESTES):
		get_tree().change_scene_to_file(MENU_TESTES)
		return
	for id in [1, 2]:
		if evento.is_action_pressed("p%d_esquerda" % id):
			_mover(id, -1)
		elif evento.is_action_pressed("p%d_direita" % id):
			_mover(id, 1)
		elif evento.is_action_pressed("p%d_botao1" % id):
			_confirmar(id)
		elif evento.is_action_pressed("p%d_botao2" % id):
			_cancelar(id)


# --- Consultas (usadas pela tela e pelos testes) ---

func cursor_de(id: int) -> int:
	return _cursor[id]


func esta_ativo(id: int) -> bool:
	return _ativo[id]


func confirmou(id: int) -> bool:
	return _confirmado[id]


func pode_comecar() -> bool:
	return _confirmado[1] and (not _ativo[2] or _confirmado[2])


# --- Ações dos jogadores ---

func _mover(id: int, passo: int) -> void:
	if not _ativo[id] or _confirmado[id]:
		return
	_cursor[id] = posmod(_cursor[id] + passo, _cards.size())
	_mensagem.text = ""
	cursor_movido.emit(id)
	_atualizar()


func _confirmar(id: int) -> void:
	if not _ativo[id]:
		_ativo[id] = true
		_cursor[id] = _primeiro_livre(id)
		if not _existe_livre(id):
			_mensagem.text = "Ainda não há outro explorador disponível (os demais estão To Be Done)."
		cursor_movido.emit(id)
		_atualizar()
		return
	if _confirmado[id]:
		if id == 1 and pode_comecar():
			_comecar()
		return
	var dados := _dados_no_cursor(id)
	if not dados.jogavel():
		_recusar(id, "%s ainda está em construção (To Be Done)." % dados.nome)
		return
	if _escolhido_pelo_outro(id, _cursor[id]):
		_recusar(id, "%s já está com o outro jogador. No co-op, cada um escolhe um explorador diferente." % dados.nome)
		return
	_confirmado[id] = true
	_mensagem.text = ""
	escolha_confirmada.emit(id, dados)
	_atualizar()


func _cancelar(id: int) -> void:
	if _confirmado[id]:
		_confirmado[id] = false
		escolha_cancelada.emit(id)
	elif id == 2 and _ativo[2]:
		_ativo[2] = false
	_mensagem.text = ""
	_atualizar()


func _recusar(id: int, texto: String) -> void:
	_mensagem.text = texto
	escolha_recusada.emit(id)


func _comecar() -> void:
	var escolhidos: Array[DadosExplorador] = [_dados_no_cursor(1)]
	if _ativo[2]:
		escolhidos.append(_dados_no_cursor(2))
	Partida.exploradores = escolhidos
	partida_iniciada.emit(escolhidos)
	if not proxima_cena.is_empty():
		get_tree().change_scene_to_file(proxima_cena)


# --- Auxiliares ---

func _dados_no_cursor(id: int) -> DadosExplorador:
	return _cards[_cursor[id]].dados


func _escolhido_pelo_outro(id: int, indice: int) -> bool:
	var outro := 2 if id == 1 else 1
	return _ativo[outro] and _confirmado[outro] and _cursor[outro] == indice


func _livre(id: int, indice: int) -> bool:
	return _cards[indice].dados.jogavel() and not _escolhido_pelo_outro(id, indice)


func _existe_livre(id: int) -> bool:
	return range(_cards.size()).any(func(i): return _livre(id, i))


## Primeiro card jogável e livre; se não houver, o primeiro card.
func _primeiro_livre(id: int) -> int:
	for i in _cards.size():
		if _livre(id, i):
			return i
	return 0


func _atualizar() -> void:
	for i in _cards.size():
		var cursores: Array[int] = []
		var escolhido_por := 0
		for id in [1, 2]:
			if _ativo[id] and _cursor[id] == i:
				cursores.append(id)
				if _confirmado[id]:
					escolhido_por = id
		_cards[i].atualizar(cursores, escolhido_por)
	_dica.text = _texto_dica()


func _texto_dica() -> String:
	if pode_comecar():
		return "P1: aperte E de novo para começar!"
	var partes: PackedStringArray = []
	if not _confirmado[1]:
		partes.append("P1: A / D escolhe, E confirma")
	if not _ativo[2]:
		partes.append("P2: Enter para entrar no co-op")
	elif not _confirmado[2]:
		partes.append("P2: ← / → escolhe, Enter confirma, Shift direito sai")
	return "   •   ".join(partes)
