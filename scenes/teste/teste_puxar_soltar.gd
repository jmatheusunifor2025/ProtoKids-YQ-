extends TesteBase
## Teste de agarrar (E), puxar, empurrar segurando e soltar (Q) para P1 e P2.

const DISTANCIA_AGARRAR := 30.0

@onready var _p1: Player = $P1
@onready var _p2: Player = $P2
@onready var _caixa1: Node2D = $Caixa1
@onready var _caixa2: Node2D = $Caixa2


func _rodar_testes() -> void:
	var inicio := {_p1: _p1.position, _p2: _p2.position, _caixa1: _caixa1.position, _caixa2: _caixa2.position}
	await _testar_jogador(_p1, _caixa1)
	await _testar_jogador(_p2, _caixa2)
	for no in inicio:
		no.position = inicio[no]


func _testar_jogador(jogador: Player, caixa: Node2D) -> void:
	var p := "P%d" % jogador.id_jogador
	var botao1 := "%s_botao1" % p.to_lower()
	var botao2 := "%s_botao2" % p.to_lower()
	print("[TESTE] --- %s puxar e soltar ---" % p)
	await posicionar(jogador, caixa.position + Vector2(-DISTANCIA_AGARRAR, 0), Vector2.RIGHT)

	await apertar(botao1)
	checar(jogador.objeto_carregado == caixa, "%s agarra a caixa com E" % p)

	var velocidade := await andar(jogador, "esquerda", 30)
	checar(absf(velocidade - Player.VELOCIDADE) < 1.0, "%s puxando anda a %.1f px/s (mesma velocidade)" % [p, velocidade])
	checar(absf(caixa.position.x - jogador.position.x - DISTANCIA_AGARRAR) < 3.0, "%s: caixa vem junto ao puxar" % p)
	checar(eventos.has("%s:empurrou" % p), "%s: arrastar emite empurrou (som de peça pesada)" % p)

	velocidade = await andar(jogador, "direita", 30)
	checar(absf(velocidade - Player.VELOCIDADE) < 1.0, "%s empurrando segurando anda a %.1f px/s" % [p, velocidade])
	checar(absf(caixa.position.x - jogador.position.x - DISTANCIA_AGARRAR) < 3.0, "%s: caixa vai junto ao empurrar" % p)

	await apertar(botao2)
	checar(jogador.objeto_carregado == null and eventos.has("%s:largou" % p), "%s solta a caixa com Q" % p)
	var caixa_parada := caixa.position
	await andar(jogador, "esquerda", 20)
	checar(caixa.position == caixa_parada, "%s: caixa solta fica parada" % p)

	# Empurra segurando até a parede: a caixa trava e se solta sozinha.
	await posicionar(jogador, caixa.position + Vector2(-DISTANCIA_AGARRAR, 0), Vector2.RIGHT)
	await apertar(botao1)
	await andar(jogador, "direita", 90)
	checar(jogador.objeto_carregado == null and eventos.has("%s:largou" % p), "%s: caixa travada na parede se solta sozinha" % p)
	checar(jogador.position.x < caixa.position.x - 16.0, "%s não atravessa a caixa depois que ela solta" % p)
