class_name CardExplorador
extends PanelContainer
## Card de um explorador no menu de seleção. Só exibe: quem decide o que
## está destacado ou escolhido é o menu (selecao_explorador.gd).

const COR_P1 := Color("#FFE066")
const COR_P2 := Color(0.2, 0.45, 0.9)
const COR_BORDA := Color(0, 0, 0)
const COR_PAPEL := Color("#FFFEF8")
const COR_ESCOLHIDO := Color("#FFF3C4")

var dados: DadosExplorador

@onready var _retrato: TextureRect = $Margem/Coluna/Retrato
@onready var _sem_arte: Label = $Margem/Coluna/SemArte
@onready var _nome: Label = $Margem/Coluna/Nome
@onready var _frase: Label = $Margem/Coluna/Frase
@onready var _estado: Label = $Margem/Coluna/Estado
@onready var _cursores: Label = $Margem/Coluna/Cursores


func configurar(novos_dados: DadosExplorador) -> void:
	dados = novos_dados
	_nome.text = dados.nome
	_frase.text = dados.frase_de_selecao
	_retrato.texture = dados.retrato
	_retrato.visible = dados.retrato != null
	_sem_arte.visible = dados.retrato == null
	modulate.a = 1.0 if dados.jogavel() else 0.55
	atualizar([], 0)


## cursores: ids dos jogadores com o cursor neste card. escolhido_por: id ou 0.
func atualizar(cursores: Array[int], escolhido_por: int) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_ESCOLHIDO if escolhido_por else COR_PAPEL
	estilo.set_corner_radius_all(8)
	estilo.border_color = COR_P1 if cursores.has(1) else COR_P2 if cursores.has(2) else COR_BORDA
	estilo.set_border_width_all(6 if not cursores.is_empty() else 2)
	add_theme_stylebox_override("panel", estilo)

	_cursores.text = "  ".join(PackedStringArray(cursores.map(func(id): return "▼ P%d" % id)))
	if not dados.jogavel():
		_estado.text = "EM BREVE · To Be Done"
	elif escolhido_por:
		_estado.text = "Escolhido por P%d" % escolhido_por
	else:
		_estado.text = ""
