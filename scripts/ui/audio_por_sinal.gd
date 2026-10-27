class_name AudioPorSinal
extends AudioStreamPlayer

@export var sons: Dictionary = {}


func _ready() -> void:
	var alvo := get_parent()
	for sinal in sons:
		if alvo.has_signal(sinal):
			var tocar := _tocar.bind(sons[sinal])
			var argumentos := _quantidade_de_argumentos(alvo, sinal)
			alvo.connect(sinal, tocar.unbind(argumentos) if argumentos > 0 else tocar)


func _tocar(som: AudioStream) -> void:
	stream = som
	play()


func _quantidade_de_argumentos(alvo: Object, sinal: StringName) -> int:
	for info in alvo.get_signal_list():
		if info.name == sinal:
			return info.args.size()
	return 0
