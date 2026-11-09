class_name DicaYolanda
extends CanvasLayer

signal dica_pedida
signal yolanda_falou
signal recarga_concluida

const TEMPO_RECARGA := 20.0

const DICAS_PORTUGUES := {
	"amizade": "É o carinho que une bons amigos! Começa com A e termina com E.",
	"amor": "É um sentimento muito forte do coração! Tem 4 letras: A-M-O-R.",
	"respeito": "É saber ouvir e cuidar do colega! Começa com R e termina com O.",
	"amigo": "É quem brinca e aprende junto com você! Começa com A e termina com O."
}

const DICAS_MATEMATICA := [
	"Queremos somar 10! Tentem juntar 8 + 2 ou 6 + 4 nos pratos da balança!",
	"A diferença precisa dar 3! Tentem colocar 9 e 6 ou 5 e 2 na balança!",
	"Queremos somar 9! Tentem juntar 7 + 2 ou 4 + 5 nos pratos da balança!"
]

const DICAS_CIENCIAS := {
	"PATO": "Essa charada é sobre o PATO! Procurem o nome dele atrás das estantes no canto superior esquerdo!",
	"PEIXE": "Essa charada é sobre o PEIXE! Procurem o nome dele atrás das estantes do lado esquerdo!",
	"SAPO": "Essa charada é sobre o SAPO! Procurem o nome dele atrás das estantes na parte de baixo!",
	"ABELHA": "Essa charada é sobre a ABELHA! Procurem o nome dela atrás das estantes do lado direito!",
	"TARTARUGA": "Essa charada é sobre a TARTARUGA! Procurem o nome dela atrás das estantes do meio da sala!"
}

@export_multiline var texto_dica := "Observem os símbolos da sala e trabalhem juntos!"

@onready var _balao_dica: Node2D = $BalaoDica
@onready var _texto_dica: Label = $BalaoDica/TextoDica
@onready var _status_recarga: Label = $StatusRecarga
@onready var _timer_recarga: Timer = $TimerRecarga
@onready var _timer_exibicao: Timer = $TimerExibicao


func _ready() -> void:
	_balao_dica.visible = false
	_atualizar_status()


func _process(_delta: float) -> void:
	if not _timer_recarga.is_stopped():
		_atualizar_status()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pedir_dica"):
		pedir_dica()


func pedir_dica() -> bool:
	if not _timer_recarga.is_stopped():
		return false
	_texto_dica.text = "Yolanda: “%s”" % _obter_texto_dica()
	_balao_dica.visible = true
	_timer_recarga.start(TEMPO_RECARGA)
	_timer_exibicao.start()
	_atualizar_status()
	dica_pedida.emit()
	yolanda_falou.emit()
	return true


func _obter_texto_dica() -> String:
	var forca := get_tree().get_first_node_in_group("forca")
	if forca != null and "_indice_palavra" in forca:
		var palavra: String = forca.PALAVRAS[forca._indice_palavra]
		var dica_palavra: String = DICAS_PORTUGUES.get(palavra, texto_dica)
		if forca._proxima < palavra.length():
			var proxima_letra := palavra[forca._proxima].to_upper()
			return "%s (Próxima letra: %s)" % [dica_palavra, proxima_letra]
		return dica_palavra

	var balanca := get_tree().get_first_node_in_group("balanca")
	if balanca != null and "_indice" in balanca:
		var indice: int = balanca._indice
		if indice >= 0 and indice < DICAS_MATEMATICA.size():
			return DICAS_MATEMATICA[indice]

	var desafio_animais := get_tree().get_first_node_in_group("desafio_animais")
	if desafio_animais != null and desafio_animais.get("animal_da_vez") != null:
		var nome_animal: String = desafio_animais.animal_da_vez.nome
		if DICAS_CIENCIAS.has(nome_animal):
			return DICAS_CIENCIAS[nome_animal]

	return texto_dica


func _on_timer_exibicao_timeout() -> void:
	_balao_dica.visible = false


func _on_timer_recarga_timeout() -> void:
	_atualizar_status()
	recarga_concluida.emit()


func _atualizar_status() -> void:
	if _timer_recarga.is_stopped():
		_status_recarga.text = "[TAB / R / H] Pedir dica para Yolanda"
	else:
		_status_recarga.text = "Yolanda pensando... (%ds)" % ceili(_timer_recarga.time_left)
