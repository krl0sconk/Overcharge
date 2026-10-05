extends Node
const GRAPH_DEFINITION: GraphDefinition = preload("res://resources/maps/test_graph_definition.tres")
const INVALID_GRAPH_DEFINITION: GraphDefinition = preload("res://resources/maps/test_invalid_graph_definition.tres")
const DUPLICATE_CONNECTION_GRAPH: GraphDefinition = preload("res://resources/maps/test_duplicate_connection_graph_definition.tres")
func _ready() -> void:
	var result: Dictionary = GraphValidator.validate(GRAPH_DEFINITION)

	assert(result["valid"] == true)
	assert(result["errors"].is_empty())
	assert(result["visited_count"] == 2)

	print("GraphValidator funciona correctamente.")
	print("grafo valido: ", result["valid"])
	print("salas visitadas por bfs: ", result["visited_count"])
	print("errores encontrados: ", result["errors"])

	print("Validando grafo invalido...")

	var invalid_result: Dictionary = GraphValidator.validate(INVALID_GRAPH_DEFINITION)

	assert(invalid_result["valid"] == false)
	assert(invalid_result["errors"].size() > 0)
	assert(invalid_result["visited_count"] == 1)

	print("Grafo invalido detectado correctamente.")
	print("Grafo valido: ", invalid_result["valid"])
	print("Salas visitadas por BFS: ", invalid_result["visited_count"])
	print("Errores encontrados: ", invalid_result["errors"])
	
	print("Validando conexiones duplicadas...")

	var duplicate_result: Dictionary = GraphValidator.validate(DUPLICATE_CONNECTION_GRAPH)

	assert(duplicate_result["valid"] == false)
	assert(duplicate_result["errors"].size() > 0)

	print("Conexion duplicada detectada correctamente.")
	print("Grafo valido: ", duplicate_result["valid"])
	print("Errores encontrados: ", duplicate_result["errors"])
