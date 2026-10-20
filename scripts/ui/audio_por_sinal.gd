class_name AudioPorSinal
extends AudioStreamPlayer
## Componente de som genérico: toca um som quando o nó pai emite um signal.
## Configure no Inspector: nome do signal -> AudioStream (conforme
## assets/sounds/sound_guide.md). O pai não sabe que este nó existe;
## removê-lo não quebra nada.

@export var sons: Dictionary = {}


func _ready() -> void:
	var alvo := get_parent()
	for sinal in sons:
		if alvo.has_signal(sinal):
			alvo.connect(sinal, _tocar.bind(sons[sinal]).unbind(_quantidade_de_argumentos(alvo, sinal)))


func _tocar(som: AudioStream) -> void:
	stream = som
	play()


func _quantidade_de_argumentos(alvo: Object, sinal: StringName) -> int:
	for info in alvo.get_signal_list():
		if info.name == sinal:
			return info.args.size()
	return 0
