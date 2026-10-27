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
  npc/                      SpriteFrames dos NPCs (yolanda_frames.tres)
                            + elenco.tres (quem aparece no menu de seleção, em ordem)
scripts/
  partida.gd                autoload "Partida": escolhas feitas nos menus
  exploradores/             Resources de dados (dados_explorador.gd, elenco_exploradores.gd)
  player/                   player.gd, audio_explorador.gd
  cenario/                  cenas das salas (HUB = sala_principal) + cena_cenario.gd
  ui/                       componentes de interface reutilizáveis (audio_por_sinal.gd,
                            caixa_dialogo.gd)
scenes/
  menus/                    telas de menu (selecao_explorador, card_explorador)
  player/                   player.tscn (a ÚNICA cena de jogador)
  npc/                      yolanda.tscn + .gd
  objetos/                  objetos do jogo: bloco, alvo_bloco, estante, porta
  ui/                       caixa_dialogo.tscn (autoload "Dialogo")
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
                                 ▲   │    ▲                  interagir/largar
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
O objeto implementa **só** os métodos que fazem sentido para ele. A estante
de empurrar só tem `interagir`; o bloco tem `interagir` e `largar`. O Player testa com `has_method()`.

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
| `empurrou(alvo)` | O objeto chamou `jogador.registrar_empurrao(self)` |

**Métodos que os objetos podem chamar:** `segurar(objeto)`,
`liberar(objeto)`, `registrar_empurrao(objeto)`.
**Propriedades que os objetos podem ler:** `direcao_olhar`, `objeto_carregado`.

**Botões:**
- **E (botão 1):** se não estiver segurando nada, chama `interagir(self)` no
  objeto mais próximo que tenha esse método **e esteja na frente** (até 45° da
  direção do olhar; `ANGULO_FRENTE`). De costas ou de lado, não pega.
- **Carregando** (bloco: `jogador.segurar(self)`): o explorador continua
  virando e animando normalmente; o bloco cai na frente, para onde ele olha.
- **Arrastando** (estante, caixa: `jogador.segurar(self, true)`): o explorador
  vira de frente para o objeto e **não muda mais a direção do olhar** — anda de
  frente (empurrar) ou de costas (puxar), parado na pose `idle_<direção>`. Ao
  soltar, volta ao normal. `jogador.esta_arrastando()` diz se está assim.
- **Q (botão 2):** se estiver segurando algo, chama `largar(self)` nele. De mãos
  vazias, não faz nada (não há chute).

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
   `frase_de_selecao` e, opcionalmente, `som_movimento`.
   Se o sheet foi desenhado em outra resolução, ajuste `escala_sprite`; se os
   frames de "lado" olham para a esquerda, marque `sprite_lado_para_esquerda`
   (grupo "Exibição do sprite" — só aparência, não muda colisão nem velocidade).
4. **Menu de seleção** — se o personagem for novo (não é Maya, Theo ou Leo),
   adicione o `.tres` dele na lista de `data/exploradores/elenco.tres`. A ordem
   da lista é a ordem dos cards.
5. **Usar numa cena** — instancie `scenes/player/player.tscn`, defina
   `id_jogador` e arraste o `.tres` em `dados`. Ou escolha pelo menu de
   seleção: o HUB e a cena de interações recebem quem foi escolhido.

Pronto: nenhum script foi editado. Se você precisou editar um, algo saiu do padrão.

Um explorador **sem `sprite_frames`** é tratado como *em construção*
(`DadosExplorador.jogavel()` devolve `false`): aparece no menu como
"EM BREVE · To Be Done" e não pode ser escolhido.

> Os sheets atuais têm frames de ~70x126 px (não 32x32 como o SGDD). O
> `AnimatedSprite2D` do Player usa `scale = 0.45` e `offset = (0, -60)` para os
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
(o HUB, `scripts/cenario/sala_principal.tscn`).

O menu **não toca som**: ele emite `cursor_movido`, `escolha_confirmada`,
`escolha_recusada`, `escolha_cancelada` e `partida_iniciada`, e o filho
`AudioPorSinal` toca `ui_button_hover` (navegar) e `ui_button_select`
(confirmar), conforme o `sound_guide.md`.

---

## 6.2 Elenco atual

Os quatro exploradores estão jogáveis:

| Explorador | Sheet (`assets/personagens/`) | Retrato (`menuDeEscolhaDePersonagens/`) | Ajustes de exibição |
| ---------- | ----------------------------- | --------------------------------------- | ------------------- |
| Sofia      | `sofia/`                      | `sofia.png`                             | —                   |
| Maya       | `lisa/`                       | `lisa.png`                              | —                   |
| Theo       | `caio/`                       | `caio.png`                              | —                   |
| Leo        | `lucas/`                      | `lucas.png`                             | `escala_sprite = 0.6`, `sprite_lado_para_esquerda` |

As pastas de arte usam os nomes antigos (lisa, caio, lucas); os nomes do SGDD
ficam só no `.tres`. Maya, Theo e Leo usam `sfx_footstep.wav` como som de passos.

## 7. Como criar um objeto interativo

1. Crie uma cena com corpo físico (`StaticBody2D`, `RigidBody2D`...) +
   `CollisionShape2D` + visual, e um script ao lado.
2. Implemente **só** o que faz sentido:

   | Método               | Chamado quando                   |
   | -------------------- | -------------------------------- |
   | `interagir(jogador)` | Jogador aperta E perto           |
   | `largar(jogador)`    | Jogador aperta Q segurando ele   |

3. Avise o Player quando precisar:
   - vai ficar na mão dele → `jogador.segurar(self)` (carregado) ou
     `jogador.segurar(self, true)` (arrastado pelo chão);
   - se soltou sozinho (travou, quebrou) → `jogador.liberar(self)`;
   - foi empurrado/arrastado → `jogador.registrar_empurrao(self)` (toca o som).
4. Use `jogador.direcao_olhar` para decidir para onde empurrar ou largar.

**Modelos prontos** em `scenes/teste/objetos/`:

| Objeto                    | Mecânica                                          |
| ------------------------- | ------------------------------------------------- |
| `bloco_teste`             | Carregar acima da cabeça (E) e largar na frente (Q) |
| `estante_teste`           | Empurrar 1 tile por toque (E)                     |
| `caixa_puxavel_teste`     | Agarrar (E), puxar/empurrar andando, soltar (Q); trava → solta sozinha |

**Objetos do jogo** em `scenes/objetos/` (use estes nas salas):

| Objeto        | Mecânica                                                        |
| ------------- | --------------------------------------------------------------- |
| `bloco`       | `class_name Bloco`. Carregar (E) e largar (Q). `@export valor` (ex.: `"GATO"`). Ao ser largado emite `entregue(bloco)` |
| `alvo_bloco`  | `class_name AlvoBloco`. Quadrado onde o bloco é entregue. `@export esperado`. Escuta o `entregue` do bloco que cai nele, encaixa no centro e emite `acertou`, `errou` ou `esvaziou` (quando tiram o bloco) |
| `estante`     | Agarrar (E), empurrar andando para frente, puxar andando para trás, soltar (Q); travou → solta sozinha |
| `porta`       | E perto dela troca de cena. `@export destino` (.tscn) e `chegada` (nome do Marker2D onde os exploradores nascem; vazio = `Entrada`) |

- O bloco **não sabe** se acertou: quem confere é o alvo. A sala (ou o
  puzzle) escuta `acertou`/`errou` do `AlvoBloco` para contar acertos e erros
  (Bagunça Máxima = 3 erros, SGDD).
- O bloco é `AnimatableBody2D`, não `StaticBody2D`: um `StaticBody2D`
  teleportado por código não é percebido pelo `Area2D` do alvo.
- Deixe espaço entre dois `AlvoBloco`: só confere o quadrado que contém o
  centro do bloco.
- Quadrados e blocos de Ciências ainda são **sem arte** (texto). Para trocar o
  animal, mude `esperado`/`valor` no Inspector.

### 7.1 Portas (HUB ↔ salas)

O HUB (`scripts/cenario/sala_principal.tscn`) tem `PortaPortugues`,
`PortaMatematica`, `PortaFinal` e `PortaCiencias` sobre as portas desenhadas, e
um Marker2D `Chegada<Sala>` na frente de cada uma. Cada sala tem uma
`PortaHub` que volta para o HUB com `chegada = "Chegada<Sala>"`. A porta grava
`Partida.ponto_entrada`, e o `CenaCenario` da cena seguinte põe os
exploradores nesse Marker2D.

Sala nova: instancie `scenes/objetos/porta.tscn` no HUB (destino = sala nova),
crie o Marker2D `Chegada<Sala>` no HUB e uma `PortaHub` na sala.

### 7.2 Yolanda e a caixa de diálogo

- **`Dialogo`** (autoload, `scenes/ui/caixa_dialogo.tscn`): caixa reutilizável
  para qualquer fala. `await Dialogo.mostrar(falas, nome, retrato)` — nome e
  retrato são opcionais. Enquanto está aberta o jogo **pausa** (a fala é para
  todos). E de **qualquer** jogador mostra o texto inteiro / passa a fala; Q
  pula a conversa. Signals: `aberta`, `fala_mostrada(indice)`, `fechada`.
- **Yolanda** (`scenes/npc/yolanda.tscn`): NPC com o sheet `mentorCoruja`
  recortado em `data/npc/yolanda_frames.tres` (`idle` piscando, `hoot` a cada
  5 s, SGDD). E perto dela abre o `Dialogo` com as `falas` do Inspector.
  Signals: `conversa_iniciada`, `conversa_terminada`, `piou`.
- Nó com som que precisa tocar durante o diálogo (jogo pausado) usa
  `process_mode = Always` (ex.: o `AudioPorSinal` da Yolanda).
- As fontes bitmap não têm aspas curvas: use aspas retas nas falas.

---

## 8. Som

- O Player **nunca** toca som. Quem toca é o `AudioExplorador` (filho do
  Player), que escuta os signals.
- Mapeamento atual, conforme `sound_guide.md`:

  | Signal     | Som                    |
  | ---------- | ---------------------- |
  | `carregou` | `sfx_block_pickup.wav` |
  | `largou`   | `sfx_block_place.wav`  |
  | `empurrou` | `sfx_push_heavy.wav`   |
  | `andou`    | `som_movimento` do `.tres` (vazio = sem som) |

- Som novo para uma ação nova: crie um signal no Player **se** for uma ação do
  jogador, e conecte no `AudioExplorador`. Som de objeto (porta abrindo,
  selo) fica no próprio objeto ou num componente dele.
- Sons de objeto atuais (filho `AudioPorSinal`): `porta.abriu` →
  `sfx_door_open`, `alvo_bloco.acertou` → `sfx_puzzle_correct`,
  `yolanda.conversa_iniciada` → `sfx_yolanda_hoot`. Erro não tem som (sem punição).

---

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
| `teste_selecao.tscn`         | Teste automático do menu de seleção: To Be Done bloqueado, co-op com exploradores diferentes, entrar/sair do P2, início |
| `teste_interacoes.tscn`      | Sem teste automático: joga com quem foi escolhido no menu, com todos os objetos (Yolanda, blocos e quadrados, estante de arrastar, estante de empurrar, porta para o HUB) |

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
- [ ] O `teste_selecao` termina em `TUDO OK`, e as interações funcionam à mão em `teste_interacoes`.
- [ ] Personagem novo foi adicionado ao `elenco.tres`.
- [ ] Nenhuma fala/som nova fere a regra de ouro.
