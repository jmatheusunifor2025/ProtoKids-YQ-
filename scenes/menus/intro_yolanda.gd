extends Control
## Introdução do Novo Jogo: fundo do menu desfocado + falas da Yolanda (FalaYolanda).
## Depois da última fala (ou Esc), escurece e abre a sala principal.

@export_file("*.tscn") var proxima_cena := "res://scripts/cenario/sala_principal.tscn"

@export var falas: Array[String] = [
	"Bom vê-los aqui, caros alunos!!",
	"Um grande mal tomou a biblioteca: os Espíritos da Bagunça!",
	"Precisam me ajudar, por favor! Juntos, organizem as salas para restaurar a ordem e a paz na biblioteca, antes que isso se espalhe pela escola toda.",
	"Sejam rápidos, pois o tempo é curto.",
	"Ah! Quase me esqueci...",
	"Depois de organizar as salas, medalhões surgirão. Levem-nos para a Sala das Estrelas para derrotarmos esses bagunceiros!!",
	"Ajudarei vocês nesta jornada, meus queridos, e, com a cooperação de todos, iremos vencer!!!",
]
## Rosto da Yolanda em cada fala (chaves de FalaYolanda.ROSTO).
@export var rostos: Array[String] = ["asas", "normal", "normal", "normal", "piscadela", "normal", "asas"]

@onready var _fala: FalaYolanda = %FalaYolanda


func _ready() -> void:
	await _fala.mostrar(falas, rostos)
	var saida := create_tween()
	saida.tween_property(self, "modulate", Color.BLACK, 0.4)
	await saida.finished
	get_tree().change_scene_to_file(proxima_cena)
