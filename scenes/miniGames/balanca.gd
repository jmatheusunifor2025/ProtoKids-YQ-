extends Node2D
## Balança: um número por prato. A conta certa equilibra; a errada inclina para o maior.
## Cada conta tem um minuto. Se o tempo acaba, o desafio volta para o começo.

const CENA_BLOCO := preload("res://scenes/miniGames/numero_bloco.tscn")
const PASTA := "res://assets/elementos dos mini games/matematica/"
const TEXTURA_ESTADO := {
	"equilibrada": preload("res://assets/elementos dos mini games/matematica/balanca_equilibrada_01.png"),
	"esquerda": preload("res://assets/elementos dos mini games/matematica/balanca_esquerda_06.png"),
	"direita": preload("res://assets/elementos dos mini games/matematica/balanca_direita_05.png"),
}
## Centro de cada prato no sprite, com a origem no meio da imagem.
const PRATOS := {
	"equilibrada": [Vector2(-107.5, 26), Vector2(105.5, 26)],
	"esquerda": [Vector2(-100.5, 56.5), Vector2(106.5, -15.5)],
	"direita": [Vector2(-107, -15.5), Vector2(106, 36.5)],
}
const DESAFIOS: Array[Dictionary] = [
	{"operacao": "adicao", "alvo": 10, "esquerda": [8, 3, 6], "direita": [2, 5, 4]},
	{"operacao": "subtracao", "alvo": 3, "esquerda": [9, 8, 5], "direita": [6, 2, 1]},
	{"operacao": "adicao", "alvo": 9, "esquerda": [7, 4, 1], "direita": [2, 5, 3]},
]
const DISTANCIA_PRATO := 70.0
const FOLGA_BLOCO := 50.0
const TEMPO_DESAFIO := 60
## Raio da área do prato no mundo. A escala da sala não encolhe o alcance.
const ALCANCE_PRATO := 40.0
## Chão da sala, longe da balança e entre as paredes.
## Coordenadas do mundo: a escala da balança não puxa os blocos para o centro.
const PONTOS_ESQUERDA: Array[Vector2] = [
	Vector2(236, 286),
	Vector2(252, 318),
	Vector2(236, 350),
	Vector2(380, 286),
	Vector2(428, 302),
	Vector2(396, 334),
	Vector2(316, 398),
	Vector2(364, 390),
	Vector2(252, 270),
	Vector2(444, 318),
]
const PONTOS_DIREITA: Array[Vector2] = [
	Vector2(876, 286),
	Vector2(908, 334),
	Vector2(876, 350),
	Vector2(1044, 286),
	Vector2(900, 270),
	Vector2(932, 398),
	Vector2(988, 390),
	Vector2(1060, 294),
	Vector2(860, 302),
]

var _indice := 0
var _operacao := "adicao"
var _alvo := 10
var _esquerdo: Node = null
var _direito: Node = null
var _estado := "equilibrada"
var _geracao := 0
var _avancando := false
var _segundos := TEMPO_DESAFIO
var _blocos: Array[Node] = []

@onready var _visual: Sprite2D = $Visual
## No CanvasLayer: a escala 0,4 da sala não encolhe a conta.
@onready var _conta: Label = $Cronometro/Faixa/Conta
@onready var _tempo: Label = $Cronometro/Moldura/Tempo
@onready var _relogio: Timer = $Cronometro/Relogio


func _ready() -> void:
	add_to_group("balanca")
	_abrir_pratos()
	_relogio.wait_time = 1.0
	_relogio.timeout.connect(_passar_segundo)
	_comecar_contagem()
	_montar()


## Os dois pratos usam o mesmo CircleShape2D. Um raio vale para os dois.
func _abrir_pratos() -> void:
	var escala := absf(global_scale.x)
	if escala == 0.0:
		escala = 1.0
	var forma := $PratoEsquerdo/CollisionShape2D.shape as CircleShape2D
	forma.radius = ALCANCE_PRATO / escala


func destino_do_numero(bloco: Node2D) -> Node2D:
	if bloco.no_prato or _ocupado(bloco.lado):
		return null
	var prato := _prato_do_lado(bloco.lado)
	var ponto: Vector2 = bloco.posicao_de_referencia() if bloco.has_method("posicao_de_referencia") else bloco.global_position
	if ponto.distance_to(prato.global_position) > DISTANCIA_PRATO:
		return null
	return prato


func bloco_no_lado(lado: int) -> Node:
	return _esquerdo if lado == 1 else _direito


func prender(bloco: Node2D) -> void:
	bloco.top_level = false
	bloco.reparent(_visual)
	bloco.z_index = 2
	bloco.marcar_no_prato(true)
	if bloco.lado == 1:
		_esquerdo = bloco
	else:
		_direito = bloco
	_atualizar()


func retirar(bloco: Node2D) -> void:
	_geracao += 1
	if _esquerdo == bloco:
		_esquerdo = null
	if _direito == bloco:
		_direito = null
	var onde := bloco.global_position
	bloco.top_level = false
	bloco.reparent(self)
	bloco.z_index = 0
	bloco.scale = Vector2.ONE
	bloco.global_position = onde
	bloco.marcar_no_prato(false)
	bloco.manter_tamanho()
	_atualizar()


func _montar() -> void:
	var desafio: Dictionary = DESAFIOS[_indice]
	_operacao = desafio.operacao
	_alvo = int(desafio.alvo)
	_criar_lado(1, desafio.esquerda)
	_criar_lado(2, desafio.direita)
	_atualizar()


## A ordem muda a cada leva, e os blocos nascem soltos no chão do próprio lado.
func _criar_lado(lado: int, numeros: Array) -> void:
	var valores: Array[int] = []
	for item in numeros:
		valores.append(int(item))
	valores.shuffle()
	var lugares := _lugares_do_lado(lado)
	for i in valores.size():
		var bloco: StaticBody2D = CENA_BLOCO.instantiate()
		bloco.definir(valores[i], load(_caminho_numero(valores[i])), lado)
		add_child(bloco)
		bloco.global_position = lugares[i]
		bloco.manter_tamanho()
		_blocos.append(bloco)


func _lugares_do_lado(lado: int) -> Array[Vector2]:
	var fonte: Array[Vector2] = PONTOS_ESQUERDA if lado == 1 else PONTOS_DIREITA
	var ordem: Array[int] = []
	for i in fonte.size():
		ordem.append(i)
	ordem.shuffle()
	var escolhidos: Array[Vector2] = []
	for indice in ordem:
		var ponto: Vector2 = fonte[indice]
		var cabe := true
		for outro in escolhidos:
			if ponto.distance_to(outro) < FOLGA_BLOCO:
				cabe = false
				break
		if not cabe:
			continue
		escolhidos.append(ponto)
		if escolhidos.size() == 3:
			break
	return escolhidos


func _caminho_numero(valor: int) -> String:
	if valor == 8:
		return PASTA + "Bloco Pixelado Dourado com Número 8.png"
	var nome := "Puzzle Matematica Numeros %d.png" % valor
	if valor == 2 or valor == 4:
		nome = "Puzzle Matematica Numeros %d .png" % valor
	return PASTA + nome


func _atualizar() -> void:
	_estado = _calcular_estado()
	_visual.texture = TEXTURA_ESTADO[_estado]
	_posicionar_miniaturas()
	_conta.text = _texto_conta()
	if _correto() and not _avancando:
		_avancar()


func _calcular_estado() -> String:
	if _correto():
		return "equilibrada"
	var esquerda := _valor(_esquerdo)
	var direita := _valor(_direito)
	if esquerda == direita:
		return "equilibrada"
	return "esquerda" if esquerda > direita else "direita"


func _correto() -> bool:
	return _esquerdo != null and _direito != null and _resultado() == _alvo


func _resultado() -> int:
	var esquerda := _valor(_esquerdo)
	var direita := _valor(_direito)
	if _operacao == "subtracao":
		return esquerda - direita
	return esquerda + direita


func _valor(bloco: Node) -> int:
	if bloco == null:
		return 0
	return bloco.numero


func _texto_conta() -> String:
	var sinal := "-" if _operacao == "subtracao" else "+"
	return "%s %s %s = %d" % [_texto_lado(_esquerdo), sinal, _texto_lado(_direito), _alvo]


func _texto_lado(bloco: Node) -> String:
	if bloco == null:
		return "?"
	return str(bloco.numero)


func _posicionar_miniaturas() -> void:
	var pontos: Array = PRATOS[_estado]
	_prato_do_lado(1).position = pontos[0]
	_prato_do_lado(2).position = pontos[1]
	if _esquerdo:
		_apoiar(_esquerdo, pontos[0])
	if _direito:
		_apoiar(_direito, pontos[1])


func _apoiar(bloco: Node2D, ponto: Vector2) -> void:
	bloco.top_level = false
	bloco.scale = Vector2.ONE
	bloco.position = ponto
	bloco.manter_tamanho()


func _avancar() -> void:
	_avancando = true
	_relogio.stop()
	var geracao: int = _geracao
	_indice += 1
	if _indice >= DESAFIOS.size():
		_entregar_medalha()
		return
	await get_tree().create_timer(0.8).timeout
	if geracao != _geracao or not is_inside_tree():
		if _avancando:
			_indice -= 1
			_avancando = false
		return
	_limpar()
	_avancando = false
	_montar()
	_comecar_contagem()


func _entregar_medalha() -> void:
	$Medalha.visible = true
	$Medalha.monitoring = true


func _comecar_contagem() -> void:
	_segundos = TEMPO_DESAFIO
	_mostrar_tempo()
	_relogio.start()


func _passar_segundo() -> void:
	_segundos -= 1
	if _segundos <= 0:
		_reiniciar()
		return
	_mostrar_tempo()


func _mostrar_tempo() -> void:
	_tempo.text = "%d:%02d" % [_segundos / 60, _segundos % 60]


## O minuto acabou: tira os números e recomeça na primeira conta.
func _reiniciar() -> void:
	_relogio.stop()
	_geracao += 1
	_indice = 0
	_avancando = false
	_limpar()
	_montar()
	_comecar_contagem()


func _limpar() -> void:
	_esquerdo = null
	_direito = null
	for bloco in _blocos:
		if is_instance_valid(bloco):
			bloco.soltar_se()
			bloco.queue_free()
	_blocos.clear()


func _ocupado(lado: int) -> bool:
	return bloco_no_lado(lado) != null


func _prato_do_lado(lado: int) -> Node2D:
	return $PratoEsquerdo if lado == 1 else $PratoDireito
