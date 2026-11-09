extends Node
## Autoload "Musica": toca a trilha de cada cena (FAIXA_DA_CENA), com transição suave.
## Se a cena nova usa a mesma faixa da anterior, a música continua sem reiniciar.
## Cena fora da lista: a música para (cenas de teste ficam em silêncio).
## Continua tocando com o jogo pausado (ex.: falas da Yolanda).

const PASTA := "res://assets/sounds/bgm/"
const INTRO := PASTA + "Intro-Music.mp3"
const FALA_CORUJA := PASTA + "FalaCoruja-Music.mp3"
const DESAFIOS := PASTA + "Desafios-Music.mp3"
const VITORIA := PASTA + "Victory-Music.mp3"
const HUB := PASTA + "bgm_library_hub.wav"

## Cena -> faixa.
const FAIXA_DA_CENA := {
	"res://scenes/menus/menu_principal.tscn": DESAFIOS,
	"res://scenes/menus/selecao_explorador.tscn": DESAFIOS,
	"res://scenes/menus/selecao_explorador_moderna.tscn": DESAFIOS,
	"res://scenes/menus/intro_yolanda.tscn": FALA_CORUJA,
	"res://scripts/cenario/sala_principal.tscn": FALA_CORUJA,
	"res://scripts/cenario/sala_portugues.tscn": INTRO,
	"res://scripts/cenario/sala_matematica.tscn": INTRO,
	"res://scripts/cenario/sala_ciencia.tscn": INTRO,
	"res://scripts/cenario/sala_final.tscn": HUB,
	"res://scripts/cenario/vitoria.tscn": VITORIA,
}
## Ajuste por faixa (dB). Os MP3 vêm masterizados bem mais altos (~-14 LUFS)
## que os WAV do sound_guide (~-20 LUFS); sem isto a música cobre falas e efeitos.
const GANHO_DA_FAIXA := {
	INTRO: -10.0,
	FALA_CORUJA: -9.0,
	DESAFIOS: -8.0,
	VITORIA: -6.0,
	HUB: -2.0,
}
const SILENCIO_DB := -60.0
const DURACAO_TRANSICAO := 0.8

var faixa_atual := ""

var _tocando: AudioStreamPlayer
var _saindo: AudioStreamPlayer
var _transicao: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tocando = _novo_player()
	_saindo = _novo_player()
	get_tree().scene_changed.connect(_ao_trocar_cena)
	_ao_trocar_cena.call_deferred()


## Toca uma faixa (caminho do arquivo). Vazio = silêncio.
func tocar(faixa: String) -> void:
	if faixa == faixa_atual:
		return
	faixa_atual = faixa
	if _transicao:
		_transicao.kill()
	var anterior := _saindo
	_saindo = _tocando
	_tocando = anterior
	_tocando.stop()
	# As duas mudam juntas (crossfade); a que sai é parada no fim.
	_transicao = create_tween().set_parallel()
	if not faixa.is_empty():
		_tocando.stream = load(faixa)
		_tocando.volume_db = SILENCIO_DB
		_tocando.play()
		_transicao.tween_property(_tocando, "volume_db", GANHO_DA_FAIXA.get(faixa, 0.0), DURACAO_TRANSICAO)
	if _saindo.playing:
		_transicao.tween_property(_saindo, "volume_db", SILENCIO_DB, DURACAO_TRANSICAO)
		_transicao.chain().tween_callback(_saindo.stop)
	else:
		_transicao.tween_interval(0.0)


func _ao_trocar_cena() -> void:
	var cena := get_tree().current_scene
	tocar(FAIXA_DA_CENA.get(cena.scene_file_path, "") if cena else "")


func _novo_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = SILENCIO_DB
	add_child(player)
	return player
