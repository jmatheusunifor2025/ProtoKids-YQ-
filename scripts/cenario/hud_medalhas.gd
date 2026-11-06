extends CanvasLayer
## Mostra o visto da matéria que já está na Partida. Vale para qualquer explorador.


func _ready() -> void:
	$Painel/CheckPortugues.visible = Partida.tem_medalha("portugues")
	$Painel/CheckMatematica.visible = Partida.tem_medalha("matematica")
	$Painel/CheckCiencias.visible = Partida.tem_medalha("ciencias")
