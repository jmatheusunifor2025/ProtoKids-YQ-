extends StaticBody2D
## Bloco numérico: E carrega acima da cabeça, Q larga na frente, e entra sozinho
## quando quem carrega chega perto do prato do seu lado.
## No prato, o E tira o bloco e ele não volta enquanto o jogador não se afastar.

const ALTURA_CARREGADO := Vector2(0, -44)
const DISTANCIA_LARGAR := 34.0
const TAMANHO := 40.0
## No prato o bloco fica 25% menor que no chão. A escala da balança não entra nisso.
const FATOR_NO_PRATO := 0.75
const REGIAO_OITO := Rect2(156, 156, 942, 909)

var numero := 1
var lado := 1
var no_prato := false
var _jogador: Node2D = null
var _escala_chao := Vector2(0.23, 0.23)
var _saindo := false


func definir(novo_numero: int, textura: Texture2D, novo_lado: int) -> void:
	numero = novo_numero
	lado = novo_lado
	$Visual.texture = textura
	var visual := $Visual as Sprite2D
	if numero == 8:
		visual.region_enabled = true
		visual.region_rect = REGIAO_OITO
	else:
		visual.region_enabled = false
	var medida: Vector2 = visual.region_rect.size if visual.region_enabled else textura.get_size()
	var fator := TAMANHO / maxf(medida.x, medida.y)
	_escala_chao = Vector2(fator, fator)
	$Visual.scale = _escala_chao


func pode_usar(jogador: Node) -> bool:
	if _quantidade_jogadores() < 2:
		return true
	var pessoa := jogador as Player
	return pessoa != null and pessoa.id_jogador == lado


func _physics_process(_delta: float) -> void:
	if no_prato or _jogador == null:
		return
	global_position = _jogador.global_position + ALTURA_CARREGADO
	if _saindo and _perto_do_prato():
		return
	_saindo = false
	_tentar_fixar()


func interagir(jogador: Node2D) -> void:
	if not pode_usar(jogador):
		return
	if no_prato:
		var balanca := get_tree().get_first_node_in_group("balanca")
		if balanca == null:
			return
		balanca.retirar(self)
		marcar_saida()
	_jogador = jogador
	z_index = 2
	$CollisionShape2D.set_deferred("disabled", true)
	global_position = jogador.global_position + ALTURA_CARREGADO
	jogador.segurar(self)


## Carregado, o que conta para chegar no prato é onde o explorador está (não o bloco
## acima da cabeça dele). No chão, é o próprio bloco.
func posicao_de_referencia() -> Vector2:
	return _jogador.global_position if _jogador else global_position


func marcar_saida() -> void:
	_saindo = true


func largar(jogador_que_solta: Node2D) -> void:
	_saindo = false
	_soltar()
	global_position = jogador_que_solta.global_position + jogador_que_solta.direcao_olhar * DISTANCIA_LARGAR
	_tentar_fixar()


func soltar_se() -> void:
	if _jogador == null:
		return
	var jogador := _jogador
	_soltar()
	jogador.liberar(self)


## No chão, o tamanho é o da letra. No prato, 25% menor. A balança não escala o bloco.
func manter_tamanho() -> void:
	var onde: Vector2 = global_position
	top_level = true
	scale = Vector2.ONE
	global_position = onde
	($Visual as Sprite2D).scale = _escala_visual()


func marcar_no_prato(na_balanca: bool) -> void:
	no_prato = na_balanca
	($Visual as Sprite2D).scale = _escala_visual()


func _escala_visual() -> Vector2:
	if no_prato:
		return _escala_chao * FATOR_NO_PRATO
	return _escala_chao


func _perto_do_prato() -> bool:
	var balanca := get_tree().get_first_node_in_group("balanca")
	return balanca != null and balanca.destino_do_numero(self) != null


func _tentar_fixar() -> void:
	if _perto_do_prato():
		_colocar_na_balanca()


func _colocar_na_balanca() -> void:
	no_prato = true
	var jogador := _jogador
	_soltar()
	$CollisionShape2D.set_deferred("disabled", true)
	if jogador:
		jogador.liberar(self)
	var balanca := get_tree().get_first_node_in_group("balanca")
	if balanca:
		balanca.prender(self)


func _soltar() -> void:
	_jogador = null
	if not no_prato:
		z_index = 0
		$CollisionShape2D.set_deferred("disabled", false)


func _quantidade_jogadores() -> int:
	var cena := get_tree().current_scene
	if cena == null:
		return 1
	return cena.find_children("", "Player", true, false).size()
