class_name Player
extends CharacterBody2D

signal andou
signal parou
signal interagiu(alvo: Node)
signal carregou(alvo: Node)
signal largou(alvo: Node)
signal empurrou(alvo: Node)

const VELOCIDADE := 120.0
const ESCALA_SPRITE := Vector2(0.45, 0.45)
const ANGULO_FRENTE := PI / 4

@export_range(1, 2) var id_jogador := 1
@export var dados: DadosExplorador:
	set(valor):
		dados = valor
		if is_node_ready():
			_aplicar_dados()

var direcao_olhar := Vector2.DOWN
var objeto_carregado: Node = null

var _andando := false
var _arrastando := false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _area_interacao: Area2D = $AreaInteracao


func _ready() -> void:
	_aplicar_dados()


func _physics_process(_delta: float) -> void:
	var direcao := Input.get_vector(_acao("esquerda"), _acao("direita"), _acao("cima"), _acao("baixo"))
	velocity = direcao.normalized() * VELOCIDADE
	move_and_slide()

	var andando_agora := direcao != Vector2.ZERO
	if andando_agora and not esta_arrastando():
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


func segurar(objeto: Node, arrastado := false) -> void:
	objeto_carregado = objeto
	_arrastando = arrastado
	if arrastado:
		direcao_olhar = _direcao_principal(objeto.global_position - global_position)
	carregou.emit(objeto)


func esta_arrastando() -> bool:
	return objeto_carregado != null and _arrastando


func liberar(objeto: Node) -> void:
	if objeto_carregado == objeto:
		objeto_carregado = null
		largou.emit(objeto)


func registrar_empurrao(objeto: Node) -> void:
	empurrou.emit(objeto)


func _usar_botao1() -> void:
	if objeto_carregado:
		return
	var alvo := _alvo_na_frente("interagir")
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


func _alvo_na_frente(metodo: String) -> Node:
	var candidatos: Array[Node] = []
	candidatos.append_array(_area_interacao.get_overlapping_bodies())
	candidatos.append_array(_area_interacao.get_overlapping_areas())
	var melhor: Node = null
	var menor_distancia := INF
	for candidato in candidatos:
		if candidato == self or candidato == objeto_carregado or not candidato.has_method(metodo):
			continue
		if not _esta_na_frente(candidato):
			continue
		var distancia := global_position.distance_squared_to(candidato.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			melhor = candidato
	return melhor


func _esta_na_frente(alvo: Node2D) -> bool:
	var para_alvo := alvo.global_position - global_position
	return para_alvo.is_zero_approx() or absf(direcao_olhar.angle_to(para_alvo)) <= ANGULO_FRENTE


func _direcao_principal(vetor: Vector2) -> Vector2:
	if vetor.is_zero_approx():
		return direcao_olhar
	if absf(vetor.x) > absf(vetor.y):
		return Vector2(signf(vetor.x), 0)
	return Vector2(0, signf(vetor.y))


func _aplicar_dados() -> void:
	_sprite.sprite_frames = dados.sprite_frames if dados else null
	_sprite.scale = ESCALA_SPRITE * (dados.escala_sprite if dados else 1.0)
	_atualizar_animacao()


func _atualizar_animacao() -> void:
	if _sprite.sprite_frames == null:
		return
	var sufixo := "baixo"
	var horizontal := absf(direcao_olhar.x) > absf(direcao_olhar.y)
	var lado_para_esquerda := dados != null and dados.sprite_lado_para_esquerda
	_sprite.flip_h = horizontal and (direcao_olhar.x < 0.0) != lado_para_esquerda
	if horizontal:
		sufixo = "lado"
	elif direcao_olhar.y < 0.0:
		sufixo = "cima"
	var arrastando := esta_arrastando()
	var nome := ("andar_" if _andando and not arrastando else "idle_") + sufixo
	if not _sprite.sprite_frames.has_animation(nome):
		return
	if arrastando:
		_sprite.animation = nome
		_sprite.stop()
	elif _sprite.animation != nome or not _sprite.is_playing():
		_sprite.play(nome)


func _acao(nome: String) -> String:
	return "p%d_%s" % [id_jogador, nome]
