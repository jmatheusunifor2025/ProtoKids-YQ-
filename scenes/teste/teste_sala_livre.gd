extends TesteBase
## Sala livre: cria os Players com os exploradores escolhidos no menu de
## seleção (autoload Partida) e deixa todos os objetos de teste à mão.
## Aberta direto (sem passar pelo menu), usa a Sofia como P1.

const CENA_PLAYER := preload("res://scenes/player/player.tscn")
const EXPLORADOR_PADRAO := preload("res://data/exploradores/sofia.tres")
const POSICOES := [Vector2(400, 420), Vector2(880, 420)]


func _ready() -> void:
	teste_automatico = false
	var escolhidos: Array[DadosExplorador] = Partida.exploradores
	if escolhidos.is_empty():
		escolhidos = [EXPLORADOR_PADRAO]
	for i in escolhidos.size():
		var jogador: Player = CENA_PLAYER.instantiate()
		jogador.id_jogador = i + 1
		jogador.dados = escolhidos[i]
		jogador.position = POSICOES[i]
		add_child(jogador)
	super._ready()
