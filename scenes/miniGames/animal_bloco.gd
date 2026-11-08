@tool
class_name AnimalBloco
extends StaticBody2D
## Animal do desafio de Ciências: E agarra, andar arrasta (empurrar e puxar), Q solta;
## se travar em algo, solta sozinho. Ao chegar no alvo, o DesafioAnimais confere.
## Sem `imagem`, mostra um bloco com o nome (provisório até a arte chegar).

const DISTANCIA_POR_SOM := 32.0
## Tamanho da imagem no jogo (lado maior, em pixels), qualquer que seja o PNG.
const TAMANHO_IMAGEM := 48.0

## Nome mostrado no bloco provisório (ex.: "PATO").
@export var nome := "ANIMAL":
	set(valor):
		nome = valor
		if is_node_ready():
			_atualizar_visual()
## Como a Yolanda fala dele ao acertar (ex.: "o pato", "a abelha").
@export var nome_falado := "o animal"
## Pistas da Yolanda, na ordem em que ela fala.
@export var pistas: Array[String] = []
## Sprite do animal. Vazio = bloco provisório com o nome.
@export var imagem: Texture2D:
	set(valor):
		imagem = valor
		if is_node_ready():
			_atualizar_visual()

var entregue := false

var _jogador: Node2D = null
var _ultima_posicao_jogador := Vector2.ZERO
var _distancia_acumulada := 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _provisorio: Control = $Provisorio
@onready var _rotulo: Label = $Provisorio/Nome
@onready var _forma: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_atualizar_visual()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _jogador == null:
		return
	var deslocamento := _jogador.global_position - _ultima_posicao_jogador
	_ultima_posicao_jogador = _jogador.global_position
	if deslocamento == Vector2.ZERO:
		return
	if move_and_collide(deslocamento):
		soltar_se()
		return
	_distancia_acumulada += deslocamento.length()
	if _distancia_acumulada >= DISTANCIA_POR_SOM:
		_distancia_acumulada = 0.0
		_jogador.registrar_empurrao(self)
	var desafio := get_tree().get_first_node_in_group("desafio_animais")
	if desafio:
		desafio.animal_movido(self)


func interagir(jogador: Node2D) -> void:
	if entregue or _jogador != null:
		return
	_jogador = jogador
	_ultima_posicao_jogador = jogador.global_position
	_distancia_acumulada = 0.0
	add_collision_exception_with(jogador)
	jogador.add_collision_exception_with(self)
	jogador.segurar(self, true)


func largar(_jogador_que_solta: Node2D) -> void:
	_soltar()


## Solta o animal de quem estiver segurando e avisa o jogador.
func soltar_se() -> void:
	if _jogador == null:
		return
	var jogador := _jogador
	_soltar()
	jogador.liberar(self)


## Acertou: fica parado no alvo e para de colidir.
func marcar_entregue(onde: Vector2) -> void:
	soltar_se()
	entregue = true
	global_position = onde
	_forma.set_deferred("disabled", true)


## Volta ao começo da rodada (posição original, sem estar entregue).
func restaurar(onde: Vector2) -> void:
	soltar_se()
	entregue = false
	visible = true
	global_position = onde
	_forma.set_deferred("disabled", false)


func piscar(cor: Color) -> void:
	modulate = cor
	var volta := create_tween()
	volta.tween_property(self, "modulate", Color.WHITE, 0.5)


func _soltar() -> void:
	if _jogador == null:
		return
	remove_collision_exception_with(_jogador)
	_jogador.remove_collision_exception_with(self)
	_jogador = null


func _atualizar_visual() -> void:
	_sprite.texture = imagem
	_sprite.visible = imagem != null
	if imagem:
		var lado := maxf(imagem.get_width(), imagem.get_height())
		_sprite.scale = Vector2.ONE * (TAMANHO_IMAGEM / lado)
	_provisorio.visible = imagem == null
	_rotulo.text = nome
