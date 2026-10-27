class_name TesteBase
extends Node2D

const MENU := "res://scenes/teste/menu_testes.tscn"

@export var teste_automatico := true

var falhas := 0
var eventos: Array[String] = []


func _ready() -> void:
	for jogador in _jogadores():
		for sinal in ["interagiu", "carregou", "largou", "empurrou"]:
			jogador.connect(sinal, func(_alvo): eventos.append("P%d:%s" % [jogador.id_jogador, sinal]))
	if teste_automatico:
		await _rodar_testes()
		print("[TESTE] %s: %s" % [name, "TUDO OK" if falhas == 0 else "%d FALHA(S)" % falhas])


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and ResourceLoader.exists(MENU):
		get_tree().change_scene_to_file(MENU)


func _rodar_testes() -> void:
	await get_tree().process_frame


func _jogadores() -> Array[Player]:
	var lista: Array[Player] = []
	for filho in get_children():
		if filho is Player:
			lista.append(filho)
	return lista


func posicionar(jogador: Player, posicao: Vector2, olhar: Vector2) -> void:
	jogador.position = posicao
	jogador.direcao_olhar = olhar
	for i in 3:
		await get_tree().physics_frame


func apertar(acao: String) -> void:
	eventos.clear()
	for pressionado in [true, false]:
		var evento := InputEventAction.new()
		evento.action = acao
		evento.pressed = pressionado
		Input.parse_input_event(evento)
		await get_tree().process_frame


func andar(jogador: Player, direcao: String, quadros: int) -> float:
	var acao := "p%d_%s" % [jogador.id_jogador, direcao]
	Input.action_press(acao)
	await get_tree().physics_frame
	var inicio := jogador.global_position
	for i in quadros:
		await get_tree().physics_frame
	Input.action_release(acao)
	await get_tree().physics_frame
	return (jogador.global_position - inicio).length() * Engine.physics_ticks_per_second / quadros


func checar(condicao: bool, descricao: String) -> void:
	falhas += 0 if condicao else 1
	print("[TESTE] %s %s" % ["OK    " if condicao else "FALHOU", descricao])
