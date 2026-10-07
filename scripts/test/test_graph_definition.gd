extends Node
const GRAPH_DEFINITION: GraphDefinition = preload("res://resources/maps/test/test_graph_definition.tres")

func _ready() -> void:
	assert(GRAPH_DEFINITION.graph_id == &"test_graph")
	assert(GRAPH_DEFINITION.minimum_rooms == 2)
	assert(GRAPH_DEFINITION.maximum_rooms == 5)
	assert(GRAPH_DEFINITION.target_room_count == 5)
	assert(GRAPH_DEFINITION.start_room_id == &"test_room")
	assert(GRAPH_DEFINITION.exit_room_id == &"test_exit")


	assert(GRAPH_DEFINITION.room_definitions.size() == 2)
	assert(GRAPH_DEFINITION.connections.size() == 1)

	assert(GRAPH_DEFINITION.room_definitions[0].room_id == &"test_room")
	assert(GRAPH_DEFINITION.room_definitions[1].room_id == &"test_exit")

	var connection: RoomConnection = GRAPH_DEFINITION.connections[0]
	assert(connection.from_room_id == &"test_room")
	assert(connection.to_room_id == &"test_exit")
	assert(connection.bidirectional)

	print("GraphDefinition funciona correctamente.")
	print("graph_id: ", GRAPH_DEFINITION.graph_id)
	print("cantidad de salas: ", GRAPH_DEFINITION.room_definitions.size())
	print("cantidad de conexiones: ", GRAPH_DEFINITION.connections.size())
	print("conexion: ", connection.from_room_id, " <-> ", connection.to_room_id)
