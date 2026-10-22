extends TesteBase
## Teste geral de interação (carregar, largar, empurrar, chutar) e dos sons.
## Roda duas vezes: com o componente de áudio e depois sem ele
## (removê-lo não pode quebrar nenhuma mecânica).

const SONS_ESPERADOS := {
	"carregou": "sfx_block_pickup.wav",
	"largou": "sfx_block_place.wav",
	"chutou": "sfx_kick_paper.wav",
	"empurrou": "sfx_push_heavy.wav",
}

@onready var _p1: Player = $P1
@onready var _p2: Player = $P2
@onready var _bloco: Node2D = $Bloco
@onready var _bloco2: Node2D = $Bloco2
@onready var _estante: Node2D = $Estante
@onready var _bola: RigidBody2D = $Bola


func _rodar_testes() -> void:
	await _rodada("com áudio", true)
	for jogador in [_p1, _p2]:
		jogador.get_node("AudioExplorador").free()
	await _rodada("sem áudio", false)


func _rodada(rotulo: String, checar_som: bool) -> void:
	var inicio := {_p1: _p1.position, _p2: _p2.position, _bloco: _bloco.position,
		_bloco2: _bloco2.position, _estante: _estante.position, _bola: _bola.position}
	print("[TESTE] --- rodada %s ---" % rotulo)

	await posicionar(_p1, _bloco.position + Vector2(-26, 0), Vector2.RIGHT)
	await apertar("p1_botao1")
	checar(_p1.objeto_carregado == _bloco, "P1 carrega o bloco com E")
	_checar_som(checar_som, _p1, "carregou")
	await apertar("p1_botao2")
	checar(_p1.objeto_carregado == null, "P1 larga o bloco com Q")
	_checar_som(checar_som, _p1, "largou")

	var estante_antes := _estante.position
	await posicionar(_p1, _estante.position + Vector2(-34, 0), Vector2.RIGHT)
	await apertar("p1_botao1")
	checar(_estante.position.distance_to(estante_antes + Vector2(32, 0)) < 0.5, "P1 empurra a estante 1 tile com E")
	checar(eventos.has("P1:empurrou"), "signal empurrou emitido")
	_checar_som(checar_som, _p1, "empurrou")

	await posicionar(_p1, _bola.position + Vector2(-24, 0), Vector2.RIGHT)
	await apertar("p1_botao2")
	await get_tree().physics_frame
	checar(_bola.linear_velocity.x > 0.0, "P1 chuta a bolinha com Q")
	_checar_som(checar_som, _p1, "chutou")

	await posicionar(_p2, _bloco2.position + Vector2(-26, 0), Vector2.RIGHT)
	await apertar("p2_botao1")
	checar(_p2.objeto_carregado == _bloco2 and _p1.objeto_carregado == null, "P2 carrega o próprio bloco; P1 não reage")
	checar(not eventos.any(func(e): return e.begins_with("P1:")), "nenhum signal do P1 com teclas do P2")
	await apertar("p2_botao2")

	_bola.linear_velocity = Vector2.ZERO
	for no in inicio:
		no.position = inicio[no]
	await get_tree().physics_frame


func _checar_som(ativo: bool, jogador: Player, sinal: String) -> void:
	if not ativo:
		return
	var tocando := ""
	for filho in jogador.get_node("AudioExplorador").get_children():
		if filho is AudioStreamPlayer2D and filho.playing and filho.stream:
			tocando = filho.stream.resource_path.get_file()
	checar(tocando == SONS_ESPERADOS[sinal], "%s toca %s (tocando: %s)" % [sinal, SONS_ESPERADOS[sinal], tocando])
