extends StaticBody2D

signal conversa_iniciada
signal conversa_terminada
signal piou

const INTERVALO_HOOT := 5.0

@export var nome := "Yolanda"
@export var retrato: Texture2D
@export var falas: PackedStringArray = [
	"Olá, exploradores! A Névoa da Bagunça embaralhou todos os livros da biblioteca.",
	"Cada porta leva a uma matéria. Escolham a que quiserem, na ordem que quiserem!",
	"Não importa quem você é, importa como a gente organiza junto.",
]

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_sprite.play("idle")
	_sprite.animation_finished.connect(_sprite.play.bind("idle"))
	var relogio := Timer.new()
	relogio.wait_time = INTERVALO_HOOT
	relogio.autostart = true
	relogio.timeout.connect(_piar)
	add_child(relogio)


func interagir(_jogador: Node2D) -> void:
	if Dialogo.esta_aberta():
		return
	conversa_iniciada.emit()
	await Dialogo.mostrar(falas, nome, retrato)
	conversa_terminada.emit()


func _piar() -> void:
	_sprite.play("hoot")
	piou.emit()
