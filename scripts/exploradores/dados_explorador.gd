class_name DadosExplorador
extends Resource
## Dados narrativos e visuais de um explorador.
## Regra do SGDD: nenhum campo de gameplay aqui (velocidade, força...).
## A diferença entre exploradores é só representação.

@export var id: StringName
@export var nome: String
@export var retrato: Texture2D
## Precisa conter as animações padrão lidas pelo Player:
## idle_baixo, idle_cima, idle_lado, andar_baixo, andar_cima, andar_lado
## ("_lado" olha para a direita; a esquerda é espelhada pelo Player).
@export var sprite_frames: SpriteFrames
@export_multiline var frase_de_selecao: String
## Som de deslocamento (apresentação, não gameplay), conforme assets/sounds/sound_guide.md.
@export var som_movimento: AudioStream


## Explorador sem sprite_frames ainda está em construção (To Be Done) e não pode ser escolhido.
func jogavel() -> bool:
	return sprite_frames != null
