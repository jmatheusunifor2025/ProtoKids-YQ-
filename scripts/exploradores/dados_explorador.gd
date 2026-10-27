class_name DadosExplorador
extends Resource

@export var id: StringName
@export var nome: String
@export var retrato: Texture2D
@export var sprite_frames: SpriteFrames
@export_multiline var frase_de_selecao: String
@export var som_movimento: AudioStream

@export_group("Exibição do sprite")
@export var escala_sprite := 1.0
@export var sprite_lado_para_esquerda := false


func jogavel() -> bool:
	return sprite_frames != null
