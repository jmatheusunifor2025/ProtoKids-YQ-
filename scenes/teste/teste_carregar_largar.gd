extends TesteBase
## Teste de carregar (E) e largar (Q) para P1 e P2.

const ALTURA_CARREGADO := Vector2(0, -44)
const DISTANCIA_LARGAR := 30.0

@onready var _p1: Player = $P1
@onready var _p2: Player = $P2
@onready var _bloco1: Node2D = $Bloco1
@onready var _bloco2: Node2D = $Bloco2


func _rodar_testes() -> void:
	var inicio := {_p1: _p1.position, _p2: _p2.position, _bloco1: _bloco1.position, _bloco2: _bloco2.position}
	await _testar_jogador(_p1, _bloco1)
	await _testar_jogador(_p2, _bloco2)
	await _testar_coop()
	for no in inicio:
		no.position = inicio[no]


func _testar_jogador(jogador: Player, bloco: Node2D) -> void:
	var p := "P%d" % jogador.id_jogador
	print("[TESTE] --- %s carregar e largar ---" % p)
	await posicionar(jogador, bloco.position + Vector2(-26, 0), Vector2.RIGHT)

	await apertar("%s_botao1" % p.to_lower())
	checar(jogador.objeto_carregado == bloco, "%s carrega o bloco com E" % p)
	checar(eventos.has("%s:carregou" % p), "%s emite carregou" % p)

	var velocidade := await andar(jogador, "baixo", 20)
	checar(absf(velocidade - Player.VELOCIDADE) < 1.0, "%s carregando anda a %.1f px/s (mesma velocidade)" % [p, velocidade])
	checar(bloco.global_position.distance_to(jogador.global_position + ALTURA_CARREGADO) < 1.0, "%s: bloco acompanha acima da cabeça" % p)

	await apertar("%s_botao1" % p.to_lower())
	checar(jogador.objeto_carregado == bloco and not eventos.has("%s:interagiu" % p), "%s: E carregando não pega outra coisa" % p)

	await apertar("%s_botao2" % p.to_lower())
	checar(jogador.objeto_carregado == null and eventos.has("%s:largou" % p), "%s larga o bloco com Q" % p)
	var esperado := jogador.global_position + jogador.direcao_olhar * DISTANCIA_LARGAR
	checar(bloco.global_position.distance_to(esperado) < 1.0, "%s: bloco cai na frente, para onde olha" % p)

	await posicionar(jogador, bloco.position + Vector2(-26, 0), Vector2.RIGHT)
	await apertar("%s_botao1" % p.to_lower())
	checar(jogador.objeto_carregado == bloco, "%s pega o bloco de novo depois de largar" % p)
	await apertar("%s_botao2" % p.to_lower())


func _testar_coop() -> void:
	print("[TESTE] --- co-op ---")
	await posicionar(_p1, _bloco1.position + Vector2(-26, 0), Vector2.RIGHT)
	await posicionar(_p2, _bloco2.position + Vector2(-26, 0), Vector2.RIGHT)
	await apertar("p1_botao1")
	await apertar("p2_botao1")
	checar(_p1.objeto_carregado == _bloco1 and _p2.objeto_carregado == _bloco2, "P1 e P2 carregam ao mesmo tempo, cada um o seu")

	# P2 larga o dele e tenta pegar o bloco que está na mão do P1.
	await apertar("p2_botao2")
	await posicionar(_p2, _bloco1.global_position + Vector2(-26, 0), Vector2.RIGHT)
	await apertar("p2_botao1")
	checar(_p1.objeto_carregado == _bloco1 and _p2.objeto_carregado != _bloco1, "P2 não tira o bloco da mão do P1")
	await apertar("p1_botao2")
