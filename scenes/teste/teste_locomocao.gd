extends TesteBase
## Teste de locomoção: mede a velocidade de P1 e P2 nas 8 direções
## (simulando as ações do InputMap) e confere o som de movimento.

const QUADROS_POR_DIRECAO := 20
const DIRECOES := {
	"direita": ["direita"], "esquerda": ["esquerda"], "cima": ["cima"], "baixo": ["baixo"],
	"cima-direita": ["cima", "direita"], "cima-esquerda": ["cima", "esquerda"],
	"baixo-direita": ["baixo", "direita"], "baixo-esquerda": ["baixo", "esquerda"],
}


func _rodar_testes() -> void:
	var jogadores := _jogadores()
	var inicio := {}
	for jogador in jogadores:
		inicio[jogador] = jogador.global_position
	for nome in DIRECOES:
		for jogador in jogadores:
			jogador.global_position = inicio[jogador]
			for eixo in DIRECOES[nome]:
				Input.action_press("p%d_%s" % [jogador.id_jogador, eixo])
		# Mede entre dois instantes com a tecla já pressionada: exatamente N passos de física.
		await get_tree().physics_frame
		var antes := {}
		for jogador in jogadores:
			antes[jogador] = jogador.global_position
		for i in QUADROS_POR_DIRECAO:
			await get_tree().physics_frame
		_checar_som_movimento(jogadores)
		for jogador in jogadores:
			for eixo in DIRECOES[nome]:
				Input.action_release("p%d_%s" % [jogador.id_jogador, eixo])
		for jogador in jogadores:
			var segundos := float(QUADROS_POR_DIRECAO) / Engine.physics_ticks_per_second
			var velocidade: float = (jogador.global_position - antes[jogador]).length() / segundos
			checar(absf(velocidade - Player.VELOCIDADE) < 1.0, "P%d (%s) %-14s %.1f px/s" % [
				jogador.id_jogador, _nome(jogador), nome, velocidade])
	await get_tree().physics_frame
	for jogador in jogadores:
		jogador.global_position = inicio[jogador]


## Enquanto anda, o som de movimento tocando deve ser o definido no DadosExplorador.
func _checar_som_movimento(jogadores: Array[Player]) -> void:
	for jogador in jogadores:
		if not jogador.dados or not jogador.dados.som_movimento or not jogador.has_node("AudioExplorador"):
			continue
		var tocando := false
		for filho in jogador.get_node("AudioExplorador").get_children():
			if filho is AudioStreamPlayer2D and filho.playing and filho.stream == jogador.dados.som_movimento:
				tocando = true
		checar(tocando, "P%d toca o som de movimento" % jogador.id_jogador)


func _nome(jogador: Player) -> String:
	return jogador.dados.nome if jogador.dados else "sem dados"
