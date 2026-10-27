# Comentários removidos do código

Os comentários dos scripts `.gd` foram tirados do código por enquanto e
guardados aqui, arquivo por arquivo. Cada item mostra a linha de código a que
o comentário pertence (o comentário vinha **antes** dela, ou **no fim** dela),
para poder recolocar depois.

## `scenes/menus/card_explorador.gd`

- Antes de `const COR_P1 := Color("#FFE066")`:
  ```gdscript
  ## Card de um explorador no menu de seleção. Só exibe: quem decide o que
  ## está destacado ou escolhido é o menu (selecao_explorador.gd).
  ```
- Antes de `func atualizar(cursores: Array[int], escolhido_por: int) -> void:`:
  ```gdscript
  ## cursores: ids dos jogadores com o cursor neste card. escolhido_por: id ou 0.
  ```

## `scenes/menus/selecao_explorador.gd`

- Antes de `signal cursor_movido(jogador: int)`:
  ```gdscript
  ## Menu "Escolha seu explorador" (SGDD, cena 03).
  ## Single-player: P1 escolhe 1. Co-op: P2 entra com o botão 1 e escolhe um
  ## explorador DIFERENTE. Exploradores sem sprite_frames aparecem como
  ## "Em breve · To Be Done" e não podem ser escolhidos.
  ## Não toca som: emite signals (o filho AudioPorSinal escuta).
  ```
- Antes de `@export_file("*.tscn") var proxima_cena := "res://scripts/cenario/sala_principal.tscn"`:
  ```gdscript
  ## Cena aberta depois da escolha. Vazio = fica no menu (usado nos testes).
  ```
- Antes de `func cursor_de(id: int) -> int:`:
  ```gdscript
  # --- Consultas (usadas pela tela e pelos testes) ---
  ```
- Antes de `func _mover(id: int, passo: int) -> void:`:
  ```gdscript
  # --- Ações dos jogadores ---
  ```
- Antes de `func _dados_no_cursor(id: int) -> DadosExplorador:`:
  ```gdscript
  # --- Auxiliares ---
  ```
- Antes de `func _primeiro_livre(id: int) -> int:`:
  ```gdscript
  ## Primeiro card jogável e livre; se não houver, o primeiro card.
  ```

## `scenes/npc/yolanda.gd`

- Antes de `signal conversa_iniciada`:
  ```gdscript
  ## Yolanda, a coruja bibliotecária (NPC). E perto dela abre a caixa de
  ## diálogo (autoload Dialogo) com as falas do Inspector.
  ## Faz a animação "hoot" a cada INTERVALO_HOOT segundos (SGDD).
  ## Não toca som: emite signals (o filho AudioPorSinal escuta).
  ```

## `scenes/objetos/alvo_bloco.gd`

- Antes de `signal acertou(bloco: Bloco)`:
  ```gdscript
  ## Quadrado onde um Bloco é entregue (ex.: os quadrados dos animais de Ciências).
  ## Escuta o `entregue` dos blocos que caem nele, encaixa o bloco no centro e
  ## confere se o `valor` dele é o `esperado`.
  ## Não toca som nem conta erros: emite signals (a sala e o AudioPorSinal escutam).
  ```
- Antes de `@export var esperado := "":`:
  ```gdscript
  ## Valor do bloco certo para este quadrado (ex.: "GATO").
  ```
- Antes de `var area: Rect2 = _forma.shape.get_rect()`:
  ```gdscript
  # Só o quadrado que tem o centro do bloco confere (quadrados vizinhos não disputam).
  ```

## `scenes/objetos/bloco.gd`

- Antes de `signal entregue(bloco: Bloco)`:
  ```gdscript
  ## Bloco de puzzle: carregado acima da cabeça (E) e largado na frente (Q).
  ## Ao ser largado emite `entregue`; o AlvoBloco embaixo dele (se houver)
  ## escuta e confere o `valor`. O bloco não sabe se acertou.
  ## É AnimatableBody2D porque o Area2D do alvo não percebe um StaticBody2D
  ## teleportado por código.
  ```
- Antes de `@export var valor := "":`:
  ```gdscript
  ## O que o bloco representa (ex.: "GATO"). É o que o AlvoBloco confere.
  ```
- Antes de `for i in 3:`:
  ```gdscript
  # Espera a física perceber onde ele caiu: assim o alvo embaixo já está escutando.
  ```

## `scenes/objetos/estante.gd`

- Antes de `const DISTANCIA_POR_SOM := 32.0`:
  ```gdscript
  ## Estante: agarrada com E, acompanha o jogador (empurrar indo para frente,
  ## puxar andando para trás) e é solta com Q. Se travar em algo, solta sozinha.
  ## O jogador mantém a mesma velocidade segurando a estante (regra de ouro do SGDD).
  ```
- Antes de `add_collision_exception_with(jogador)`:
  ```gdscript
  # Jogador e estante não se bloqueiam enquanto estão juntos.
  ```

## `scenes/objetos/porta.gd`

- Antes de `signal abriu`:
  ```gdscript
  ## Porta entre cenas (HUB <-> salas). E perto dela leva os exploradores para
  ## `destino`; eles nascem no Marker2D `chegada` (vazio = Entrada da cena).
  ## Não toca som: emite `abriu` (o filho AudioPorSinal escuta).
  ```
- Antes de `const ESPERA_TROCA := 0.4`:
  ```gdscript
  ## Tempo para o som da porta tocar antes de trocar de cena.
  ```

## `scenes/teste/menu_testes.gd`

- Antes de `const PASTA := "res://scenes/teste/"`:
  ```gdscript
  ## Cena principal provisória: lista as cenas de teste (scenes/teste/teste_*.tscn)
  ## e abre a escolhida. Esc dentro de um teste volta para cá.
  ## Cena de teste nova aparece aqui sozinha, sem editar este script.
  ```
- Antes de `@export var outras_cenas: Array[String] = [`:
  ```gdscript
  ## Cenas fora de scenes/teste que também aparecem no topo do menu.
  ```
- Antes de `arquivo = arquivo.trim_suffix(".remap")`:
  ```gdscript
  # No jogo exportado as cenas aparecem como ".tscn.remap".
  ```

## `scenes/teste/objetos/bloco_teste.gd`

- Antes de `const ALTURA_CARREGADO := Vector2(0, -44)`:
  ```gdscript
  ## Objeto de teste (sem arte): pode ser carregado (E) e largado (Q).
  ```

## `scenes/teste/objetos/caixa_puxavel_teste.gd`

- Antes de `const DISTANCIA_POR_SOM := 32.0`:
  ```gdscript
  ## Objeto de teste (sem arte): agarrado com E, acompanha o jogador
  ## (puxar e empurrar) e é solto com Q. Se travar em algo, solta sozinho.
  ## O jogador mantém a mesma velocidade enquanto puxa (regra de ouro do SGDD).
  ```
- Antes de `add_collision_exception_with(jogador)`:
  ```gdscript
  # Jogador e caixa não se bloqueiam enquanto estão juntos.
  ```

## `scenes/teste/objetos/estante_teste.gd`

- Antes de `const PASSO := 32.0`:
  ```gdscript
  ## Objeto de teste (sem arte): empurrado (E) um tile na direção em que o jogador olha.
  ```

## `scenes/teste/teste_base.gd`

- Antes de `const MENU := "res://scenes/teste/menu_testes.tscn"`:
  ```gdscript
  ## Base das cenas de teste: simula o InputMap, registra os signals dos
  ## jogadores e imprime "[TESTE] OK / FALHOU". Cada cena de teste herda daqui
  ## e implementa _rodar_testes(). Depois do teste, o controle volta aos jogadores.
  ## Esc volta para o menu de testes.
  ```
- Antes de `var eventos: Array[String] = []`:
  ```gdscript
  ## Signals emitidos desde o último _apertar(), no formato "P1:carregou".
  ```
- Antes de `func _rodar_testes() -> void:`:
  ```gdscript
  ## Sobrescrever: os testes da cena (pode usar await).
  ```
- Antes de `for i in 3:`:
  ```gdscript
  # Espera a Area2D atualizar as sobreposições.
  ```
- Antes de `func apertar(acao: String) -> void:`:
  ```gdscript
  ## Aperta e solta uma ação (ex.: "p1_botao1").
  ```
- Antes de `func andar(jogador: Player, direcao: String, quadros: int) -> float:`:
  ```gdscript
  ## Segura uma direção (ex.: "esquerda") por N passos de física e devolve a velocidade medida.
  ```

## `scenes/teste/teste_interacoes.gd`

- Antes de `const CENA_PLAYER := preload("res://scenes/player/player.tscn")`:
  ```gdscript
  ## Cena de interações (sem teste automático): cria os Players com os
  ## exploradores escolhidos no menu de seleção (autoload Partida) e deixa à mão
  ## todos os objetos com que eles interagem.
  ## Aberta direto (sem passar pelo menu), usa a Sofia como P1.
  ```

## `scenes/teste/teste_selecao.gd`

- Antes de `const SOFIA := preload("res://data/exploradores/sofia.tres")`:
  ```gdscript
  ## Teste do menu de seleção de exploradores: To Be Done bloqueado,
  ## co-op com exploradores diferentes, entrar/sair do P2 e início da partida.
  ## Usa um elenco próprio (definido na cena): [em construção, Sofia, Maya], para
  ## o caso To Be Done continuar coberto mesmo com todo o elenco real jogável.
  ```

## `scripts/cenario/cena_cenario.gd`

- Antes de `const CENA_PLAYER := preload("res://scenes/player/player.tscn")`:
  ```gdscript
  ## Coloca os exploradores da Partida em cima de um Marker2D.
  ```

## `scripts/exploradores/dados_explorador.gd`

- Antes de `@export var id: StringName`:
  ```gdscript
  ## Dados narrativos e visuais de um explorador.
  ## Regra do SGDD: nenhum campo de gameplay aqui (velocidade, força...).
  ## A diferença entre exploradores é só representação.
  ```
- Antes de `@export var sprite_frames: SpriteFrames`:
  ```gdscript
  ## Precisa conter as animações padrão lidas pelo Player:
  ## idle_baixo, idle_cima, idle_lado, andar_baixo, andar_cima, andar_lado
  ## ("_lado" olha para a direita; a esquerda é espelhada pelo Player).
  ```
- Antes de `@export var som_movimento: AudioStream`:
  ```gdscript
  ## Som de deslocamento (apresentação, não gameplay), conforme assets/sounds/sound_guide.md.
  ```
- Antes de `@export var escala_sprite := 1.0`:
  ```gdscript
  ## Ajuste de exibição para sheets desenhados em outra resolução (não é gameplay:
  ## a colisão e a velocidade não mudam).
  ```
- Antes de `@export var sprite_lado_para_esquerda := false`:
  ```gdscript
  ## Marque se os frames de "lado" do sheet olham para a esquerda.
  ```
- Antes de `func jogavel() -> bool:`:
  ```gdscript
  ## Explorador sem sprite_frames ainda está em construção (To Be Done) e não pode ser escolhido.
  ```

## `scripts/exploradores/elenco_exploradores.gd`

- Antes de `@export var exploradores: Array[DadosExplorador] = []`:
  ```gdscript
  ## Lista dos exploradores que aparecem no menu de seleção, na ordem dos cards.
  ## Novo explorador = novo DadosExplorador adicionado aqui (data/exploradores/elenco.tres).
  ```

## `scripts/partida.gd`

- Antes de `var exploradores: Array[DadosExplorador] = []`:
  ```gdscript
  ## Autoload "Partida": guarda as escolhas feitas nos menus para as cenas seguintes.
  ## Explorador de cada jogador: índice 0 = P1, índice 1 = P2 (só no co-op).
  ```
- Antes de `var ponto_entrada := ""`:
  ```gdscript
  ## Nome do Marker2D onde os exploradores nascem na próxima sala. Vazio = Entrada.
  ```

## `scripts/player/audio_explorador.gd`

- Antes de `@export var som_carregar: AudioStream = preload("res://assets/sounds/sfx/sfx_block_pickup.wav")`:
  ```gdscript
  ## Componente de som do Player. Só escuta os signals do pai;
  ## o Player não sabe que este nó existe. Removê-lo não quebra nenhuma mecânica.
  ## Sons conforme assets/sounds/sound_guide.md.
  ```

## `scripts/player/player.gd`

- Antes de `signal andou`:
  ```gdscript
  ## Player único para todos os exploradores e para P1/P2.
  ## Lê a entrada, move, anima e delega interações aos objetos.
  ## Não toca som: só emite signals (quem quiser, escuta).
  ```
- Antes de `const VELOCIDADE := 120.0`:
  ```gdscript
  ## Igual para todos os exploradores (SGDD: inclusão não é penalidade).
  ```
- Antes de `const ESCALA_SPRITE := Vector2(0.45, 0.45)`:
  ```gdscript
  ## Escala do AnimatedSprite2D para sheets de ~126 px; DadosExplorador.escala_sprite multiplica.
  ```
- Antes de `const ANGULO_FRENTE := PI / 4`:
  ```gdscript
  ## E só alcança o que estiver até este ângulo da direção do olhar.
  ```
- Antes de `var direcao_olhar := Vector2.DOWN`:
  ```gdscript
  ## Para onde o explorador está olhando; objetos usam para posicionar/empurrar/largar.
  ```
- Antes de `var _arrastando := false`:
  ```gdscript
  ## O objeto segurado é arrastado (estante, caixa): o explorador fica olhando para ele.
  ```
- Antes de `velocity = direcao.normalized() * VELOCIDADE`:
  ```gdscript
  # Normalizado: mesma velocidade em qualquer direção, sem aceleração.
  ```
- Antes de `if andando_agora and not esta_arrastando():`:
  ```gdscript
  # Arrastando, continua olhando para o objeto (anda de frente ou de costas).
  ```
- Antes de `func segurar(objeto: Node, arrastado := false) -> void:`:
  ```gdscript
  ## Chamado pelo objeto quando decide ser carregado. `arrastado = true` para
  ## objetos puxados pelo chão (estante, caixa): o explorador fica parado na pose,
  ## olhando para o objeto. Carregado (bloco): continua virando e animando.
  ```
- Antes de `func liberar(objeto: Node) -> void:`:
  ```gdscript
  ## Chamado pelo objeto quando ele mesmo se solta (ex.: travou numa parede).
  ```
- Antes de `func registrar_empurrao(objeto: Node) -> void:`:
  ```gdscript
  ## Chamado pelo objeto quando foi empurrado.
  ```
- Antes de `func _alvo_na_frente(metodo: String) -> Node:`:
  ```gdscript
  ## O mais próximo com `metodo` que esteja na frente (até ANGULO_FRENTE do olhar).
  ```
- Antes de `func _direcao_principal(vetor: Vector2) -> Vector2:`:
  ```gdscript
  ## Direção reta (cima/baixo/lado) mais parecida com `vetor`.
  ```
- Antes de `_sprite.animation = nome`:
  ```gdscript
  # Arrastando: pose parada olhando para o objeto, mesmo andando.
  ```

## `scripts/ui/audio_por_sinal.gd`

- Antes de `@export var sons: Dictionary = {}`:
  ```gdscript
  ## Componente de som genérico: toca um som quando o nó pai emite um signal.
  ## Configure no Inspector: nome do signal -> AudioStream (conforme
  ## assets/sounds/sound_guide.md). O pai não sabe que este nó existe;
  ## removê-lo não quebra nada.
  ```
- Antes de `alvo.connect(sinal, tocar.unbind(argumentos) if argumentos > 0 else tocar)`:
  ```gdscript
  # unbind(0) é erro: signal sem argumentos conecta direto.
  ```

## `scripts/ui/caixa_dialogo.gd`

- Antes de `signal aberta`:
  ```gdscript
  ## Autoload "Dialogo": caixa de diálogo reutilizável (Yolanda, dicas, placas...).
  ## Uso: await Dialogo.mostrar(["Oi!", "Vamos organizar?"], "Yolanda", retrato)
  ## Enquanto está aberta o jogo fica pausado (a fala é para todos).
  ## E de qualquer jogador mostra o texto inteiro / passa a fala; Q pula a conversa.
  ## Não toca som: emite signals.
  ```
- Antes de `var _quadro_aberta := -1`:
  ```gdscript
  ## Quadro em que abriu: o mesmo E que abriu a caixa não pode passar a fala.
  ```
- Antes de `func mostrar(falas: PackedStringArray, nome := "", retrato: Texture2D = null) -> void:`:
  ```gdscript
  ## Abre a caixa com as falas, uma por vez. Termina quando a caixa fecha.
  ```
- Antes de `func avancar() -> void:`:
  ```gdscript
  ## Se a fala ainda está sendo escrita, mostra inteira; senão, vai para a próxima.
  ```
