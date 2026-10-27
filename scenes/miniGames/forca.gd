extends Node2D
## Forca: uma palavra por vez. A letra só gruda no giz da vez.

const PALAVRAS: PackedStringArray = ["amizade", "amor", "respeito", "amigo"]
const CENA_LETRA := preload("res://scenes/miniGames/letra_bloco.tscn")
const TEXTURA_GIZ := preload("res://assets/elementos dos mini games/portugues/Quadrado Branco Pontilhado em Pixel Art.png")
const PASTA_LETRA := "res://assets/elementos dos mini games/alfabeto/%s.png"
## O tracejado fica no meio do PNG, com muita margem vazia em volta.
const REGIAO_GIZ := Rect2(404, 384, 446, 438)
const FOLGA := 8.0
## Última linha opaca da lousa no centro do PNG (a base da madeira, sem o vazio).
const BORDA_INFERIOR_LOUSA := 572.0 / 866.0
const TEMPO_PALAVRA := 60

var _indice_palavra := 0
var _proxima := 0
var _tamanho_bloco := 40.0
var _alcance_y := 60.0
var _segundos := TEMPO_PALAVRA
var _espacos: Array[Node2D] = []
var _letras: Array[Node] = []

@onready var _tempo: Label = $Cronometro/Moldura/Tempo
@onready var _relogio: Timer = $Cronometro/Relogio


func _ready() -> void:
	add_to_group("forca")
	_tamanho_bloco = _medir_bloco()
	_alcance_y = _medir_alcance_y()
	_relogio.timeout.connect(_passar_segundo)
	_comecar_contagem()
	_montar_palavra()


func _medir_bloco() -> float:
	var amostra: Node = CENA_LETRA.instantiate()
	var visual := amostra.get_node("Visual") as Sprite2D
	var tamanho: Vector2 = visual.texture.get_size() * visual.scale
	amostra.free()
	return maxf(tamanho.x, tamanho.y)


func _medir_alcance_y() -> float:
	var lousa := $Lousa as Sprite2D
	var altura := lousa.texture.get_height() * absf(lousa.scale.y)
	var topo := lousa.global_position.y - altura * 0.5
	var base := topo + altura * BORDA_INFERIOR_LOUSA
	return (base - $Linha.global_position.y) + _tamanho_bloco * 0.35


func destino_da_letra(letra: String, bloco: Node2D) -> Node2D:
	var palavra := PALAVRAS[_indice_palavra]
	if _proxima >= palavra.length():
		return null
	if letra.to_upper() != palavra[_proxima].to_upper():
		return null
	var giz := _espacos[_proxima]
	var delta := bloco.global_position - giz.global_position
	# Só gruda quando o bloco chega na base da lousa, alinhado com o giz.
	if absf(delta.x) > _tamanho_bloco or delta.y < -_tamanho_bloco * 0.5 or delta.y > _alcance_y:
		return null
	return giz


func prender(bloco: Node2D) -> void:
	var giz := _espacos[_proxima]
	bloco.reparent($Linha)
	bloco.position = giz.position
	bloco.z_index = 1
	_proxima += 1
	if _proxima < PALAVRAS[_indice_palavra].length():
		return
	_relogio.stop()
	_indice_palavra += 1
	if _indice_palavra >= PALAVRAS.size():
		return
	await get_tree().create_timer(0.8).timeout
	_limpar()
	_montar_palavra()
	_comecar_contagem()


func _montar_palavra() -> void:
	var palavra := PALAVRAS[_indice_palavra].to_upper()
	_proxima = 0
	var espaco := _tamanho_bloco + FOLGA
	var inicio := -espaco * (palavra.length() - 1) / 2.0
	var escala_giz := Vector2(
		_tamanho_bloco / REGIAO_GIZ.size.x,
		_tamanho_bloco / REGIAO_GIZ.size.y
	)
	for i in palavra.length():
		var giz := Sprite2D.new()
		giz.texture = TEXTURA_GIZ
		giz.region_enabled = true
		giz.region_rect = REGIAO_GIZ
		giz.centered = true
		giz.scale = escala_giz
		giz.position = Vector2(inicio + espaco * i, 0)
		$Linha.add_child(giz)
		_espacos.append(giz)
	var ordem: Array[String] = []
	for i in palavra.length():
		ordem.append(palavra[i])
	ordem.shuffle()
	for i in ordem.size():
		var bloco: StaticBody2D = CENA_LETRA.instantiate()
		var caminho := PASTA_LETRA % ordem[i]
		bloco.definir(ordem[i], load(caminho))
		bloco.position = $SaidaLetras.position + Vector2(inicio + espaco * i, 0)
		add_child(bloco)
		_letras.append(bloco)


func _limpar() -> void:
	for espaco in _espacos:
		espaco.queue_free()
	_espacos.clear()
	for bloco in _letras:
		if is_instance_valid(bloco):
			bloco.soltar_se()
			bloco.queue_free()
	_letras.clear()


func _comecar_contagem() -> void:
	_segundos = TEMPO_PALAVRA
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


func _reiniciar() -> void:
	_relogio.stop()
	_indice_palavra = 0
	_limpar()
	_montar_palavra()
	_comecar_contagem()
