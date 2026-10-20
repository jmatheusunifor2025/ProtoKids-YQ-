class_name ElencoExploradores
extends Resource
## Lista dos exploradores que aparecem no menu de seleção, na ordem dos cards.
## Novo explorador = novo DadosExplorador adicionado aqui (data/exploradores/elenco.tres).

@export var exploradores: Array[DadosExplorador] = []
