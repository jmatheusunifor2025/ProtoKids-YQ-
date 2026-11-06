extends Area2D
## Medalha do pedestal. O giro só aparece com E, perto da frente do pedestal,
## e somente se a Partida já guardou a medalha desta matéria.
## Com as três colocadas, abre a cena de vitória.

@export var materia := ""
@export var folha: Texture2D
@export var colunas := 4
@export var linhas := 2
@export var velocidade := 6.0

const CENA_VITORIA := "res://scripts/cenario/vitoria.tscn"

var _colocada := false

@onready var _visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	_montar_giro()


func esta_colocada() -> bool:
	return _colocada


func interagir(_jogador: Node2D) -> void:
	if _colocada or folha == null or not Partida.tem_medalha(materia):
		return
	_colocada = true
	_visual.visible = true
	_visual.play("giro")
	# Solta o E para o pedestal ao lado. A medalha colocada não precisa mais dele.
	$Colisao.set_deferred("disabled", true)
	if _todas_colocadas():
		await get_tree().create_timer(0.8).timeout
		get_tree().change_scene_to_file(CENA_VITORIA)


func _todas_colocadas() -> bool:
	var colocadas := 0
	for irmao in get_parent().get_children():
		if not irmao.has_method("esta_colocada"):
			continue
		if not irmao.esta_colocada():
			return false
		colocadas += 1
	return colocadas == 3


func _montar_giro() -> void:
	_visual.visible = false
	if folha == null:
		return
	var quadros := SpriteFrames.new()
	quadros.remove_animation("default")
	quadros.add_animation("giro")
	quadros.set_animation_loop("giro", true)
	quadros.set_animation_speed("giro", velocidade)
	var largura := int(folha.get_width() / colunas)
	var altura := int(folha.get_height() / linhas)
	for linha in linhas:
		for coluna in colunas:
			var recorte := AtlasTexture.new()
			recorte.atlas = folha
			recorte.region = Rect2(coluna * largura, linha * altura, largura, altura)
			quadros.add_frame("giro", recorte)
	_visual.sprite_frames = quadros
