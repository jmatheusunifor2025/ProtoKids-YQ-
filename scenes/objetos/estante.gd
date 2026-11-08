@tool
class_name Estante
extends StaticBody2D
## Estante com livros, pronta para qualquer cena: arraste estante.tscn para a cena
## e escolha a orientação no Inspector. Agarrada com E, acompanha o jogador
## (empurrar e puxar) e é solta com Q; se travar em algo, solta sozinha.
## Com `movel` desmarcado vira obstáculo fixo.

enum Orientacao { HORIZONTAL, VERTICAL }

const DISTANCIA_POR_SOM := 32.0
const TEXTURA_HORIZONTAL := preload("res://assets/objetos/estante_horizontal.png")
const TEXTURA_VERTICAL := preload("res://assets/objetos/estante_vertical.png")

## Muda sprite e colisão (aparece na hora no editor).
@export var orientacao := Orientacao.HORIZONTAL:
	set(valor):
		orientacao = valor
		if is_node_ready():
			_aplicar_orientacao()

## Desmarcado: a estante vira um obstáculo fixo (não pode ser agarrada).
@export var movel := true

var _jogador: Node2D = null
var _ultima_posicao_jogador := Vector2.ZERO
var _distancia_acumulada := 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _forma: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_aplicar_orientacao()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _jogador == null:
		return
	var deslocamento := _jogador.global_position - _ultima_posicao_jogador
	_ultima_posicao_jogador = _jogador.global_position
	if deslocamento == Vector2.ZERO:
		return
	if move_and_collide(deslocamento):
		var jogador := _jogador
		_soltar()
		jogador.liberar(self)
		return
	_distancia_acumulada += deslocamento.length()
	if _distancia_acumulada >= DISTANCIA_POR_SOM:
		_distancia_acumulada = 0.0
		_jogador.registrar_empurrao(self)


func interagir(jogador: Node2D) -> void:
	if not movel:
		return
	_jogador = jogador
	_ultima_posicao_jogador = jogador.global_position
	_distancia_acumulada = 0.0
	add_collision_exception_with(jogador)
	jogador.add_collision_exception_with(self)
	jogador.segurar(self, true)


func largar(_jogador_que_solta: Node2D) -> void:
	_soltar()


## Solta a estante de quem estiver segurando (ex.: um minijogo reiniciando a rodada).
func soltar_se() -> void:
	if _jogador == null:
		return
	var jogador := _jogador
	_soltar()
	jogador.liberar(self)


func _soltar() -> void:
	if _jogador == null:
		return
	remove_collision_exception_with(_jogador)
	_jogador.remove_collision_exception_with(self)
	_jogador = null


func _aplicar_orientacao() -> void:
	var forma := RectangleShape2D.new()
	if orientacao == Orientacao.VERTICAL:
		forma.size = Vector2(28, 56)
		_sprite.texture = TEXTURA_VERTICAL
		_sprite.scale = Vector2(0.5, 0.5)
		_sprite.position = Vector2(0, -7.5)
	else:
		forma.size = Vector2(72, 32)
		_sprite.texture = TEXTURA_HORIZONTAL
		_sprite.scale = Vector2(0.4, 0.4)
		_sprite.position = Vector2(0, 0.4)
	_forma.shape = forma
