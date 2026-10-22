class_name Player
extends CharacterBody2D
## Player único para todos os exploradores e para P1/P2.
## Lê a entrada, move, anima e delega interações aos objetos.
## Não toca som: só emite signals (quem quiser, escuta).

signal andou
signal parou
signal interagiu(alvo: Node)
signal carregou(alvo: Node)
signal largou(alvo: Node)
signal chutou(alvo: Node)
signal empurrou(alvo: Node)

## Igual para todos os exploradores (SGDD: inclusão não é penalidade).
const VELOCIDADE := 120.0

@export_range(1, 2) var id_jogador := 1
@export var dados: DadosExplorador:
	set(valor):
		dados = valor
		if is_node_ready():
			_aplicar_dados()

## Para onde o explorador está olhando; objetos usam para posicionar/empurrar/chutar.
var direcao_olhar := Vector2.DOWN
var objeto_carregado: Node = null

var _andando := false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _area_interacao: Area2D = $AreaInteracao


func _ready() -> void:
	_aplicar_dados()


func _physics_process(_delta: float) -> void:
	var direcao := Input.get_vector(_acao("esquerda"), _acao("direita"), _acao("cima"), _acao("baixo"))
	# Normalizado: mesma velocidade em qualquer direção, sem aceleração.
	velocity = direcao.normalized() * VELOCIDADE
	move_and_slide()

	var andando_agora := direcao != Vector2.ZERO
	if andando_agora:
		direcao_olhar = direcao.normalized()
	if andando_agora != _andando:
		_andando = andando_agora
		if _andando:
			andou.emit()
		else:
			parou.emit()
	_atualizar_animacao()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(_acao("botao1")):
		_usar_botao1()
	elif evento.is_action_pressed(_acao("botao2")):
		_usar_botao2()


## Chamado pelo objeto quando decide ser carregado.
func segurar(objeto: Node) -> void:
	objeto_carregado = objeto
	carregou.emit(objeto)


## Chamado pelo objeto quando ele mesmo se solta (ex.: travou numa parede).
func liberar(objeto: Node) -> void:
	if objeto_carregado == objeto:
		objeto_carregado = null
		largou.emit(objeto)


## Chamado pelo objeto quando foi empurrado.
func registrar_empurrao(objeto: Node) -> void:
	empurrou.emit(objeto)


func _usar_botao1() -> void:
	if objeto_carregado:
		return
	var alvo := _alvo_mais_proximo("interagir")
	if alvo:
		interagiu.emit(alvo)
		alvo.interagir(self)


func _usar_botao2() -> void:
	if objeto_carregado:
		var objeto := objeto_carregado
		objeto_carregado = null
		if objeto.has_method("largar"):
			objeto.largar(self)
		largou.emit(objeto)
		return
	var alvo := _alvo_mais_proximo("chutar")
	if alvo:
		alvo.chutar(self)
		chutou.emit(alvo)


func _alvo_mais_proximo(metodo: String) -> Node:
	var candidatos: Array[Node] = []
	candidatos.append_array(_area_interacao.get_overlapping_bodies())
	candidatos.append_array(_area_interacao.get_overlapping_areas())
	var melhor: Node = null
	var menor_distancia := INF
	for candidato in candidatos:
		if candidato == self or candidato == objeto_carregado or not candidato.has_method(metodo):
			continue
		var distancia := global_position.distance_squared_to(candidato.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			melhor = candidato
	return melhor


func _aplicar_dados() -> void:
	_sprite.sprite_frames = dados.sprite_frames if dados else null
	_atualizar_animacao()


func _atualizar_animacao() -> void:
	if _sprite.sprite_frames == null:
		return
	var sufixo := "baixo"
	var horizontal := absf(direcao_olhar.x) > absf(direcao_olhar.y)
	_sprite.flip_h = horizontal and direcao_olhar.x < 0.0
	if horizontal:
		sufixo = "lado"
	elif direcao_olhar.y < 0.0:
		sufixo = "cima"
	var nome := ("andar_" if _andando else "idle_") + sufixo
	if _sprite.animation != nome and _sprite.sprite_frames.has_animation(nome):
		_sprite.play(nome)


func _acao(nome: String) -> String:
	return "p%d_%s" % [id_jogador, nome]
