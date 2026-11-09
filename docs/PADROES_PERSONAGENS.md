# Padrões de código e cenas — Personagens e objetos interativos

Guia de como os exploradores (Maya, Theo, Sofia, Leo) e os objetos com que eles
interagem são construídos em **Yolanda e o Labirinto das Matérias**. Leia antes
de criar um personagem, um objeto interativo ou uma cena de teste.

Godot 4.3+ (desenvolvido no 4.7.2) · GDScript · 2D topdown · 1280x720.
A janela usa `stretch/mode = canvas_items` e `stretch/aspect = keep`: qualquer
tamanho de janela mostra sempre a mesma área de 1280x720 (com faixas nas
bordas, se precisar). Posicione tudo dentro de (0, 0)–(1280, 720).

---

## 1. Regras que não se negociam

1. **Regra de ouro do SGDD.** Nenhuma fala, mecânica ou som pode sugerir que um
   corpo ou identidade aprende menos ou é mais lento. Na prática: a velocidade
   é **uma constante** (`Player.VELOCIDADE`) e nenhum personagem tem atributo de
   gameplay próprio. Carregar ou puxar algo também não deixa ninguém mais lento.
2. **`assets/` é só leitura.** Código e cenas apenas *carregam* imagens e sons.
   Nada é gerado, editado, redimensionado, convertido ou substituído. Os
   arquivos `.import` que o Godot cria ao lado dos assets são metadados e podem
   ir para o git.
3. **Sons seguem `assets/sounds/sound_guide.md`.** Não edite esse arquivo.

---

## 2. Estrutura de pastas

```
assets/                     só leitura (sprites, sons, fontes)
data/
  exploradores/             um .tres DadosExplorador + um .tres SpriteFrames por personagem
                            + elenco.tres (quem aparece no menu de seleção, em ordem)
scripts/
  partida.gd                autoload "Partida": escolhas feitas nos menus
  exploradores/             Resources de dados (dados_explorador.gd, elenco_exploradores.gd)
  player/                   player.gd, audio_explorador.gd
  ui/                       componentes de interface reutilizáveis (audio_por_sinal.gd)
scenes/
  menus/                    telas de menu (selecao_explorador, card_explorador)
  player/                   player.tscn (a ÚNICA cena de jogador)
  teste/                    cenas de teste + teste_base.gd + menu_testes
    objetos/                objetos de teste sem arte (um .tscn + .gd cada)
docs/                       este guia
```

Onde colocar cada coisa:

| Você está criando...                   | Vai em                                      |
| -------------------------------------- | ------------------------------------------- |
| Um personagem novo                     | `data/exploradores/<id>.tres` + `<id>_frames.tres` |
| Script reutilizável (sistema, componente) | `scripts/<área>/`                        |
| Cena reutilizável do jogo              | `scenes/<área>/`                            |
| Objeto interativo de verdade (com arte) | `scenes/objetos/<nome>.tscn` + `.gd` ao lado |
| Objeto só para teste (sem arte)        | `scenes/teste/objetos/`                     |
| Cena de teste                          | `scenes/teste/teste_<assunto>.tscn` + `.gd` |

Scripts de **teste** e de **objetos** ficam ao lado da cena que os usa. Scripts
**compartilhados** (Player, Resources, componentes) ficam em `scripts/`.

---

## 3. Arquitetura em uma imagem

```
 InputMap (p1_*, p2_*) ──lê──▶ Player (player.gd) ──chama──▶ Objeto interativo
                                 ▲   │    ▲                  interagir/largar/chutar
 DadosExplorador (.tres) ─dados──┘   │    └──avisa── segurar / liberar / registrar_empurrao
                                     │
                                  signals
                                     ▼
                              AudioExplorador ──toca──▶ assets/sounds
```

- **Um único `player.tscn`** serve todos os exploradores e os dois jogadores.
- O que muda entre personagens é **só o `.tres`** que o Player recebe.
- O Player **não conhece** tipos de objeto nem toca som.

---

## 4. SOLID aplicado (com exemplos do projeto)

### S — Responsabilidade única
Cada script faz uma coisa:

| Script                  | Responsabilidade                                   |
| ----------------------- | -------------------------------------------------- |
| `player.gd`             | Ler entrada, mover, animar, delegar, emitir signals |
| `dados_explorador.gd`   | Guardar dados narrativos/visuais                    |
| `audio_explorador.gd`   | Tocar sons ouvindo signals                          |
| `bloco_teste.gd` etc.   | Comportamento daquele objeto                        |

❌ Não coloque som, diálogo ou regra de puzzle dentro do `player.gd`.

### O — Aberto para extensão, fechado para modificação
Personagem novo = **arquivo de dados novo**, não código novo. Objeto novo =
**script novo** com os métodos do contrato. O `player.gd` não é editado.

❌ `if dados.id == "sofia": ...` — proibido em qualquer script.

### L — Substituição de Liskov
Qualquer objeto que implemente `interagir(jogador)` funciona onde um bloco
funciona. Qualquer `DadosExplorador` funciona onde a Sofia funciona.

### I — Segregação de interface
O objeto implementa **só** os métodos que fazem sentido para ele. A bolinha só
tem `chutar`; a estante só tem `interagir`. O Player testa com `has_method()`.

### D — Inversão de dependência
O Player depende de **contratos** (nomes de métodos e signals), não de classes
concretas. O áudio depende dos **signals** do Player, e o Player nem sabe que o
áudio existe — por isso dá para remover o `AudioExplorador` sem quebrar nada.

---

## 5. O Player (`scripts/player/player.gd`)

**Exports:** `id_jogador` (1 ou 2) e `dados` (um `DadosExplorador`).
**Constante:** `VELOCIDADE := 120.0` — a única velocidade do jogo.

A direção é sempre normalizada: diagonal tem a mesma velocidade que reto, e não
há aceleração.

**Signals** (no passado, sem som embutido):

| Signal           | Quando                                         |
| ---------------- | ---------------------------------------------- |
| `andou`          | Começou a andar                                |
| `parou`          | Parou de andar                                 |
| `interagiu(alvo)`| Apertou E perto de algo com `interagir`        |
| `carregou(alvo)` | O objeto chamou `jogador.segurar(self)`        |
| `largou(alvo)`   | Soltou com Q, ou o objeto chamou `liberar`     |
| `chutou(alvo)`   | Apertou Q perto de algo com `chutar`           |
| `empurrou(alvo)` | O objeto chamou `jogador.registrar_empurrao(self)` |

**Métodos que os objetos podem chamar:** `segurar(objeto, arrastado := false)`,
`liberar(objeto)`, `registrar_empurrao(objeto)`.
**Propriedades que os objetos podem ler:** `direcao_olhar`, `objeto_carregado`.

**Botões:**
- **E (botão 1):** se não estiver segurando nada, chama `interagir(self)` no
  objeto mais próximo que tenha esse método **e esteja à frente** (até 45° para
  cada lado de `direcao_olhar`). De costas ou de lado, nada acontece.
- **Q (botão 2):** se estiver segurando algo, chama `largar(self)` nele; senão,
  chama `chutar(self)` no objeto mais próximo que tenha esse método.

---

## 6. Como criar um personagem

1. **SpriteFrames** — crie `data/exploradores/<id>_frames.tres` com
   `AtlasTexture` recortando o spritesheet em `assets/personagens/<pasta>/`.
   Não edite o PNG.
2. **Nomes de animação obrigatórios** (iguais para todos):

   | Animação      | Conteúdo                                  |
   | ------------- | ----------------------------------------- |
   | `idle_baixo`  | Parado, de frente                         |
   | `idle_cima`   | Parado, de costas                         |
   | `idle_lado`   | Parado, olhando para a **direita**        |
   | `andar_baixo` | Andando de frente                         |
   | `andar_cima`  | Andando de costas                         |
   | `andar_lado`  | Andando para a **direita**                |

   A esquerda é espelhada pelo Player (`flip_h`). Na diagonal vale o eixo
   dominante.
3. **DadosExplorador** — crie `data/exploradores/<id>.tres` e preencha:
   `id` (ex.: `&"maya"`), `nome`, `retrato`, `sprite_frames`,
   `frase_de_selecao` e, opcionalmente, `som_movimento` e `escala_sprite`
   (só exibição, para sheets em outra resolução — veja 6.2).
4. **Menu de seleção** — se o personagem for novo (não é Maya, Theo ou Leo),
   adicione o `.tres` dele na lista de `data/exploradores/elenco.tres`. A ordem
   da lista é a ordem dos cards.
5. **Usar numa cena** — instancie `scenes/player/player.tscn`, defina
   `id_jogador` e arraste o `.tres` em `dados`. Ou escolha pelo menu de
   seleção: a sala livre já recebe quem foi escolhido.

Pronto: nenhum script foi editado. Se você precisou editar um, algo saiu do padrão.

Um explorador **sem `sprite_frames`** é tratado como *em construção*
(`DadosExplorador.jogavel()` devolve `false`): aparece no menu como
"EM BREVE · To Be Done" e não pode ser escolhido.

> Os sheets atuais têm frames de ~70x126 px (não 32x32 como o SGDD). O Player
> exibe o sprite com `scale = 0.45 × escala_sprite` e calcula o `offset` para os
> pés ficarem na origem. Isso é ajuste de exibição, não edição do asset.

**O que NÃO pode ir no `DadosExplorador`:** velocidade, força, alcance, vida,
cooldown ou qualquer outro número de gameplay.

---

## 6.1 Menu de seleção de exploradores

Cena: `scenes/menus/selecao_explorador.tscn` (SGDD, cena 03 "Escolha seu
explorador"). Os cards vêm de `data/exploradores/elenco.tres`, um
`card_explorador.tscn` para cada explorador.

| Regra (SGDD)                                   | Como funciona                                   |
| ---------------------------------------------- | ----------------------------------------------- |
| Single-player escolhe 1                        | P1: A / D move, **E** confirma, **E** de novo começa |
| Co-op: cada jogador escolhe 1 **diferente**    | P2 entra com **Enter**, ← / → move, Enter confirma; um explorador já escolhido é recusado |
| Desfazer                                       | **Q** (P1) / **Shift direito** (P2) desfaz; o P2 aperta de novo para sair do co-op |
| Sem atributos diferentes                       | O card mostra só retrato, nome e a frase do `.tres` |
| Destaque amarelo                               | Cursor do P1 = borda amarela (#FFE066); P2 = azul |

Ao começar, a escolha vai para o autoload **`Partida`**
(`Partida.exploradores[0]` = P1, `[1]` = P2) e o menu abre `proxima_cena`
(hoje, `teste_sala_livre.tscn`; troque pelo HUB quando ele existir).

O menu **não toca som**: ele emite `cursor_movido`, `escolha_confirmada`,
`escolha_recusada`, `escolha_cancelada` e `partida_iniciada`, e o filho
`AudioPorSinal` toca `ui_button_hover` (navegar) e `ui_button_select`
(confirmar), conforme o `sound_guide.md`.

---

## 6.2 Elenco (Maya, Theo, Leo e Sofia)

Os quatro exploradores estão jogáveis. A equipe decidiu manter os nomes do SGDD
e usar a arte de `assets/personagens/` assim:

| Explorador | Pasta da arte | Retrato (`menuDeEscolhaDePersonagens/`) | `escala_sprite` |
| ---------- | ------------- | --------------------------------------- | --------------- |
| Maya       | `lisa/`       | `lisa.png`                              | 1.1             |
| Theo       | `caio/`       | `caio.png`                              | 1.0             |
| Sofia      | `sofia/`      | `sofia.png`                             | 1.0             |
| Leo        | `lucas/`      | `lucas.png`                             | 0.61            |

Detalhes dos sheets (os PNGs não foram editados):

- **`_lado` usa só os frames que olham para a direita.** Os sheets têm frames
  de lado olhando para os dois lados; os que olham para a esquerda ficam de
  fora, porque a esquerda é espelhada pelo Player.
- **Theo de costas** vem de `assets/personagens/caio/theo_costas.png` (3 frames
  de 76x126, gerados no SpriteCook a partir do sheet do `caio/`, porque o sheet
  original não tem costas). É um arquivo novo; o sheet original não foi mexido.
- **Leo** usa um sheet maior (215 px de altura), por isso `escala_sprite = 0.61`.
- Maya, Theo e Leo usam `sfx_footstep.wav` como `som_movimento`, conforme o
  `sound_guide.md`.
- O sheet da Maya tem dois frames extras do caderno mágico (fim do sheet), ainda
  sem uso — combinam com `sfx_magic_sparkle.wav` do `sound_guide.md`.

**`escala_sprite`** é só exibição (a colisão e a velocidade não mudam): serve
para sheets desenhados em outra resolução ficarem do tamanho dos outros. O
Player também calcula sozinho o `offset` do sprite pela última linha opaca do
frame `idle_baixo`, para os pés ficarem na origem em qualquer sheet.

## 7. Como criar um objeto interativo

1. Crie uma cena com corpo físico (`StaticBody2D`, `RigidBody2D`...) +
   `CollisionShape2D` + visual, e um script ao lado.
2. Implemente **só** o que faz sentido:

   | Método               | Chamado quando                   |
   | -------------------- | -------------------------------- |
   | `interagir(jogador)` | Jogador aperta E perto           |
   | `largar(jogador)`    | Jogador aperta Q segurando ele   |
   | `chutar(jogador)`    | Jogador aperta Q perto, de mãos vazias |

3. Avise o Player quando precisar:
   - vai ficar na mão dele (acima da cabeça) → `jogador.segurar(self)`;
   - vai ser puxado/empurrado no chão (estante, caixa) → `jogador.segurar(self, true)`:
     o explorador trava o olhar no objeto e anda de costas ao puxar;
   - se soltou sozinho (travou, quebrou) → `jogador.liberar(self)`;
   - foi empurrado/arrastado → `jogador.registrar_empurrao(self)` (toca o som).
4. Use `jogador.direcao_olhar` para decidir para onde empurrar, largar ou chutar.

**Objetos prontos para qualquer cena** (com arte, em `scenes/objetos/`):

| Objeto          | Como usar                                                        |
| --------------- | ---------------------------------------------------------------- |
| `estante.tscn`  | Arraste para a cena e escolha no Inspector: **Orientacao** (Horizontal 72x32 / Vertical 28x56 — sprite e colisão mudam na hora, no editor) e **Movel** (desmarcado = obstáculo fixo). Móvel: E agarra, andar puxa/empurra sem perder velocidade, Q solta; travou em algo, solta sozinha. Cada instância cria a própria colisão. Teste: `teste_estantes.tscn`. |

**Modelos prontos** em `scenes/teste/objetos/`:

| Objeto                    | Mecânica                                          |
| ------------------------- | ------------------------------------------------- |
| `bloco_teste`             | Carregar acima da cabeça (E) e largar na frente (Q) |
| `estante_teste`           | Empurrar 1 tile por toque (E)                     |
| `caixa_puxavel_teste`     | Agarrar (E), puxar/empurrar andando, soltar (Q); trava → solta sozinha |
| `bola_teste`              | Chutar (Q)                                        |

---

## 8. Som

- O Player **nunca** toca som. Quem toca é o `AudioExplorador` (filho do
  Player), que escuta os signals.
- Mapeamento atual, conforme `sound_guide.md`:

  | Signal     | Som                    |
  | ---------- | ---------------------- |
  | `carregou` | `sfx_block_pickup.wav` |
  | `largou`   | `sfx_block_place.wav`  |
  | `chutou`   | `sfx_kick_paper.wav`   |
  | `empurrou` | `sfx_push_heavy.wav`   |
  | `andou`    | `som_movimento` do `.tres` (vazio = sem som) |

- Som novo para uma ação nova: crie um signal no Player **se** for uma ação do
  jogador, e conecte no `AudioExplorador`. Som de objeto (porta abrindo,
  selo) fica no próprio objeto ou num componente dele.

---

### Música (autoload `Musica`, `scripts/audio/musica.gd`)

A música de fundo não fica em nenhuma cena: a autoload `Musica` escuta a troca
de cena e toca a faixa da tabela `FAIXA_DA_CENA` (cena → arquivo em
`assets/sounds/bgm/`), com transição de 0,8 s. Se a cena nova usa a mesma faixa
(ex.: menu → seleção), a música continua sem reiniciar. Cena fora da tabela
(testes) fica em silêncio. Ela continua tocando com o jogo pausado.

| Cena                                  | Faixa                    |
| ------------------------------------- | ------------------------ |
| Menu principal, seleção               | `Desafios-Music.mp3`     |
| Introdução da Yolanda e HUB (sala principal) | `FalaCoruja-Music.mp3` (continua da intro para o HUB, sem reiniciar) |
| Sala final                            | `bgm_library_hub.wav`    |
| Salas de Português, Matemática, Ciências | `Intro-Music.mp3`     |
| Vitória                               | `Victory-Music.mp3` (sem loop) |

- **Cena nova com música:** adicione uma linha em `FAIXA_DA_CENA`.
- **Volume:** os MP3 vêm bem mais altos que os WAV; `GANHO_DA_FAIXA` abaixa
  cada faixa para não cobrir falas e efeitos.
- **Loop:** configurado na importação (`.import`), sem editar o arquivo:
  `loop = true` e `loop_offset` pulando o silêncio do começo de cada MP3.
- Teste: `teste_musica.tscn`.

## 9. Entrada

Ações no `project.godot`, uma por jogador:

| Ação          | P1 | P2             |
| ------------- | -- | -------------- |
| `pN_cima`     | W  | ↑              |
| `pN_baixo`    | S  | ↓              |
| `pN_esquerda` | A  | ←              |
| `pN_direita`  | D  | →              |
| `pN_botao1`   | E  | Enter          |
| `pN_botao2`   | Q  | Shift direito  |

O Player monta o nome com `"p%d_%s" % [id_jogador, nome]`. Para adicionar o
joystick físico, adicione eventos às **mesmas** ações — nenhum script muda.

---

## 10. Convenções de nome e estilo

- **Idioma:** português, sem acento em identificadores (`direcao_olhar`).
- **Arquivos e pastas:** `snake_case` (`caixa_puxavel_teste.gd`).
- **Nós na cena e `class_name`:** `PascalCase` (`AreaInteracao`, `DadosExplorador`).
- **Privado:** prefixo `_` (`_usar_botao1`, `_sprite`). Sem `_` = API que outros podem usar.
- **Signals:** verbo no passado (`carregou`, `empurrou`).
- **Constantes:** `MAIUSCULAS` (`VELOCIDADE`, `DISTANCIA_LARGAR`).
- **Tipagem:** sempre que possível (`var x: float`, `-> void`).
- **Comentários:** `##` no topo do script explicando o papel dele; comentário
  no meio do código só quando o *porquê* não é óbvio.
- **Nós referenciados no script:** `@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D`.

---

## 11. Cenas de teste

Todas herdam de `scenes/teste/teste_base.gd` (`TesteBase`), que oferece:

| Função                          | Faz                                        |
| ------------------------------- | ------------------------------------------ |
| `posicionar(jogador, pos, olhar)` | Teleporta e espera a física atualizar    |
| `apertar("p1_botao1")`          | Simula apertar e soltar uma ação           |
| `andar(jogador, "esquerda", n)` | Segura a direção por n quadros e devolve a velocidade |
| `checar(condicao, "texto")`     | Imprime `[TESTE] OK` ou `FALHOU`           |
| `eventos`                       | Signals desde o último `apertar` (`"P1:carregou"`) |

**Menu de testes:** enquanto o jogo não tem tela inicial, a cena principal do
projeto é `scenes/teste/menu_testes.tscn`. Aperte **F5** e escolha o teste; **Esc**
volta ao menu. Toda cena `scenes/teste/teste_*.tscn` aparece no menu sozinha.
Quando a Tela Inicial existir, troque a cena principal em
*Projeto → Configurações → Aplicação → Executar*.

**Cenas existentes** (pelo menu, ou abra e aperte F6):

| Cena                         | Testa                                         |
| ---------------------------- | --------------------------------------------- |
| `teste_locomocao.tscn`       | Velocidade nas 8 direções, P1 e P2            |
| `teste_carregar_largar.tscn` | Carregar, andar carregando, largar, co-op     |
| `teste_puxar_soltar.tscn`    | Agarrar, puxar, empurrar segurando, soltar, travar na parede |
| `teste_interacao.tscn`       | Empurrar, chutar, sons; repete sem o áudio    |
| `teste_selecao.tscn`         | Menu de seleção: To Be Done bloqueado, co-op com exploradores diferentes, entrar/sair do P2, início |
| `teste_sala_livre.tscn`      | Sem teste automático: joga com quem foi escolhido no menu, com todos os objetos |

O teste automático roda ao abrir e termina com `TUDO OK`; depois os controles
ficam livres para testar à mão. Para desligar, desmarque `teste_automatico` no
nó raiz.

**Criar um teste novo:** `extends TesteBase`, sobrescreva `_rodar_testes()`
(pode usar `await`), coloque os Players como filhos diretos da raiz.

---

## 12. Checklist antes do commit

- [ ] Nenhum arquivo de `assets/` foi alterado (só `.import` novos).
- [ ] `player.gd` não ganhou `if` por personagem nem por tipo de objeto.
- [ ] Nenhum campo de gameplay entrou no `DadosExplorador`.
- [ ] Personagem novo usa os 6 nomes de animação padrão.
- [ ] As 5 cenas de teste automático terminam em `TUDO OK`.
- [ ] Personagem novo foi adicionado ao `elenco.tres`.
- [ ] Nenhuma fala/som nova fere a regra de ouro.
