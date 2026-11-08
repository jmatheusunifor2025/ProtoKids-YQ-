extends CardExplorador
## Visual "biblioteca" do card de explorador (seleção moderna): pergaminho com
## moldura de madeira; o cursor do P1 brilha em dourado e o do P2 em azul.
## A lógica é a mesma do CardExplorador; só o desenho muda.

const COR_PERGAMINHO := Color("#F3DDA8")
const COR_PERGAMINHO_ESCOLHIDO := Color("#FFEFC2")
const COR_MADEIRA := Color("#6B3A1C")
const COR_DOURADO := Color("#FFC83D")
const COR_AZUL := Color("#4A8BFF")


func atualizar(cursores: Array[int], escolhido_por: int) -> void:
	super(cursores, escolhido_por)
	var cor_cursor := COR_DOURADO if cursores.has(1) else COR_AZUL if cursores.has(2) else Color.TRANSPARENT
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_PERGAMINHO_ESCOLHIDO if escolhido_por else COR_PERGAMINHO
	estilo.set_corner_radius_all(10)
	estilo.set_border_width_all(7 if not cursores.is_empty() else 5)
	estilo.border_color = cor_cursor if not cursores.is_empty() else COR_MADEIRA
	estilo.shadow_color = Color(cor_cursor, 0.55) if not cursores.is_empty() else Color(0, 0, 0, 0.45)
	estilo.shadow_size = 14 if not cursores.is_empty() else 6
	estilo.shadow_offset = Vector2.ZERO if not cursores.is_empty() else Vector2(0, 4)
	add_theme_stylebox_override("panel", estilo)

	_cursores.add_theme_color_override("font_color", COR_MADEIRA if cursores.has(1) else COR_AZUL.darkened(0.3))
	_estado.add_theme_color_override("font_color", COR_MADEIRA if escolhido_por else Color("#7A3E8A"))
	scale = Vector2.ONE * (1.04 if not cursores.is_empty() else 1.0)
	pivot_offset = size / 2.0
