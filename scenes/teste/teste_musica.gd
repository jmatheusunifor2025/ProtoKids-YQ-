extends TesteBase
## Teste da autoload Musica (scripts/audio/musica.gd): faixas existem e repetem,
## transição entre faixas, mesma faixa não reinicia, toca com o jogo pausado.

const MUSICA := preload("res://scripts/audio/musica.gd")


func _rodar_testes() -> void:
	await get_tree().process_frame
	print("[TESTE] --- faixas ---")
	for cena in MUSICA.FAIXA_DA_CENA:
		checar(ResourceLoader.exists(cena), "cena existe: %s" % cena.get_file())
	for faixa in MUSICA.GANHO_DA_FAIXA:
		var stream: AudioStream = load(faixa)
		checar(stream != null, "faixa carrega: %s" % faixa.get_file())
		var repete: bool = stream.loop if stream is AudioStreamMP3 else stream.loop_mode != AudioStreamWAV.LOOP_DISABLED
		checar(repete == (faixa != MUSICA.VITORIA), "%s %s" % [faixa.get_file(), "repete" if faixa != MUSICA.VITORIA else "toca uma vez (vitória)"])
	checar(Musica.faixa_atual == "", "cena de teste fica em silêncio")

	print("[TESTE] --- tocar e trocar ---")
	Musica.tocar(MUSICA.INTRO)
	await _esperar(1.0)
	var player := _player_tocando()
	checar(player != null and player.stream.resource_path == MUSICA.INTRO, "toca a Intro")
	checar(player != null and is_equal_approx(player.volume_db, MUSICA.GANHO_DA_FAIXA[MUSICA.INTRO]), "chega no volume da faixa (%s dB)" % MUSICA.GANHO_DA_FAIXA[MUSICA.INTRO])
	var posicao := player.get_playback_position()
	Musica.tocar(MUSICA.INTRO)
	await _esperar(0.3)
	checar(player.playing and player.get_playback_position() > posicao, "mesma faixa de novo: continua, não reinicia")

	Musica.tocar(MUSICA.DESAFIOS)
	await _esperar(0.3)
	checar(_tocando_count() == 2, "na troca, as duas tocam juntas (transição)")
	await _esperar(1.0)
	player = _player_tocando()
	checar(_tocando_count() == 1 and player.stream.resource_path == MUSICA.DESAFIOS, "depois da transição, só a Desafios toca")

	print("[TESTE] --- pausa ---")
	get_tree().paused = true
	var antes := player.get_playback_position()
	await _esperar(0.3)
	checar(player.get_playback_position() > antes, "continua tocando com o jogo pausado")
	get_tree().paused = false

	Musica.tocar("")
	await _esperar(1.0)
	checar(_tocando_count() == 0, "tocar(\"\") para a música")


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, true, false, true).timeout


func _players() -> Array[AudioStreamPlayer]:
	var lista: Array[AudioStreamPlayer] = []
	for filho in Musica.get_children():
		if filho is AudioStreamPlayer:
			lista.append(filho)
	return lista


func _player_tocando() -> AudioStreamPlayer:
	for p in _players():
		if p.playing and p.stream and p.stream.resource_path == Musica.faixa_atual:
			return p
	return null


func _tocando_count() -> int:
	return _players().filter(func(p): return p.playing).size()
