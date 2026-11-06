extends Node

var exploradores: Array[DadosExplorador] = []

var ponto_entrada := ""
## Matéria -> caminho do PNG da medalha. Sobrevive à troca de sala.
var medalhas := {}


func guardar_medalha(materia: String, caminho_textura: String) -> void:
	medalhas[materia] = caminho_textura


func tem_medalha(materia: String) -> bool:
	return medalhas.has(materia)


func textura_da_medalha(materia: String) -> Texture2D:
	if not tem_medalha(materia):
		return null
	return load(medalhas[materia])
