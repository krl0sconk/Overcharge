extends Node

const GRAPH_DEFINITION: GraphDefinition = preload(
    "res://resources/maps/test/test_graph_definition.tres"
)

func _ready() -> void:
	var first_context := GenerationContext.new(
		80,
		60,
		10,
		15,
		2,
		12345
	)

	var second_context := GenerationContext.new(
		80,
		60,
		10,
		15,
		2,
		12345
	)

	var alternate_context := GenerationContext.new(
		80,
		60,
		10,
		15,
		2,
		54321
	)

	var generator := GraphGenerator.new()

	var first_graph: GeneratedGraph = generator.generate(
		GRAPH_DEFINITION,
		first_context
	)

	var validation_result: Dictionary = (
		GraphValidator.validate_generated(first_graph)
	)

	assert(validation_result["valid"] == true)
	assert(validation_result["errors"].is_empty())
	assert(validation_result["visited_count"] == 5)

	print("Grafo generado validado correctamente mediante BFS.")

	var second_graph: GeneratedGraph = generator.generate(
		GRAPH_DEFINITION,
		second_context
	)

	var alternate_graph: GeneratedGraph = generator.generate(
		GRAPH_DEFINITION,
		alternate_context
	)

	assert(first_graph.seed == 12345)
	assert(first_graph.rooms.size() == 5)
	assert(first_graph.connections.size() == 4)

	assert(first_graph.start_room_id == &"test_room")
	assert(first_graph.exit_room_id == &"test_exit")
	assert(first_graph.has_room(&"test_room"))
	assert(first_graph.has_room(&"test_exit"))

	var start_room: GeneratedRoom = first_graph.get_room(
		&"test_room"
	)

	var exit_room: GeneratedRoom = first_graph.get_room(
		&"test_exit"
	)

	assert(start_room.position == Vector2i(0, 0))
	assert(exit_room.position == Vector2i(4, 0))

	for room_id in first_graph.rooms.keys():
		var first_room: GeneratedRoom = first_graph.get_room(room_id)
		var second_room: GeneratedRoom = second_graph.get_room(room_id)

		assert(second_room != null)
		assert(first_room.position == second_room.position)
		assert(first_room.difficulty == second_room.difficulty)

	assert(alternate_graph.rooms.size() == 5)
	assert(alternate_graph.connections.size() == 4)
	assert(alternate_graph.start_room_id == &"test_room")
	assert(alternate_graph.exit_room_id == &"test_exit")

	var middle_rooms_are_different: bool = false

	for room_id in first_graph.rooms.keys():
		if room_id == first_graph.start_room_id:
			continue

		if room_id == first_graph.exit_room_id:
			continue

		if not alternate_graph.has_room(room_id):
			middle_rooms_are_different = true
			break

	assert(middle_rooms_are_different)

	print("Las semillas generan salas intermedias diferentes.")

	print("GraphGenerator funciona correctamente.")
	print("Salas con semilla 12345: ", first_graph.rooms.keys())
	print("Salas con semilla 54321: ", alternate_graph.rooms.keys())
	print("Conexiones: ", first_graph.connections.size())
