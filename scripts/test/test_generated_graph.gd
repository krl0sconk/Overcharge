extends Node
const START_DEFINITION: RoomDefinition = preload("res://resources/maps/test/definitions/test_room_definition.tres")

const EXIT_DEFINITION: RoomDefinition = preload("res://resources/maps/test/definitions/test_exit_room_definition.tres")

const CONNECTION: RoomConnection = preload("res://resources/maps/test/connections/test_start_to_exit_connection.tres")

func _ready() -> void:
	var generated_graph := GeneratedGraph.new(12345, &"test_room", &"test_exit")
	
	var start_room := GeneratedRoom.new(START_DEFINITION, Vector2i(0,0), 0)

	var exit_room := GeneratedRoom.new(EXIT_DEFINITION, Vector2i(1,0),1)

	generated_graph.add_room(start_room)
	generated_graph.add_room(exit_room)
	generated_graph.connections.append(CONNECTION)

	assert(generated_graph.seed == 12345)
	assert(generated_graph.start_room_id == &"test_room")
	assert(generated_graph.exit_room_id == &"test_exit")
	assert(generated_graph.has_room(&"test_room"))
	assert(generated_graph.has_room(&"test_exit"))
	assert(not generated_graph.has_room(&"missing_room"))
	assert(generated_graph.get_room(&"test_room") == start_room)
	assert(generated_graph.get_room(&"missing_room") == null)
	assert(generated_graph.connections.size() == 1)

	print("GeneratedGraph funciona correctamente.")
	print("seed: ", generated_graph.seed)
	print("salas generadas: ", generated_graph.rooms.size())
	print("conexiones: ", generated_graph.connections.size())
