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
		12345,
		100,
		120
	)

	var second_context := GenerationContext.new(
		80,
		60,
		10,
		15,
		2,
		12345,
		100,
		120
	)

	var alternate_context := GenerationContext.new(
		80,
		60,
		10,
		15,
		2,
		54321,
		100,
		120
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
	
	print("Roles seleccionados:")
	for room_id in first_graph.rooms.keys():
		var room: GeneratedRoom = first_graph.get_room(room_id)
		print(room.room_id, " -> ", room.room_role)
	
	var low_health_context := GenerationContext.new(20, 20, 10, 15, 2, 12345, 100, 120)

	var low_health_graph: GeneratedGraph = generator.generate(GRAPH_DEFINITION,low_health_context)

	print("Roles con poca vida:")
	for room_id in low_health_graph.rooms.keys():
		var room: GeneratedRoom = low_health_graph.get_room(room_id)
		print(room.room_id, " -> ", room.room_role)
	
	var normal_reward_count: int = 0
	var low_health_reward_count: int = 0

	for generation_seed in range(1000, 1100):
		var normal_context := GenerationContext.new( 80, 60, 10, 15, 2, generation_seed, 100, 120)

		var low_health_context_batch := GenerationContext.new( 20, 20, 10, 15, 2, generation_seed, 100, 120)

		var normal_graph: GeneratedGraph = generator.generate(GRAPH_DEFINITION, normal_context)

		var low_health_graph_batch: GeneratedGraph = generator.generate(GRAPH_DEFINITION, low_health_context_batch)

		normal_reward_count += _count_role(normal_graph,"reward")

		low_health_reward_count += _count_role(low_health_graph_batch,"reward")

	print("Recompensas con vida normal: ", normal_reward_count)
	print("Recompensas con poca vida: ", low_health_reward_count)

	var normal_difficulty_total: int = 0
	var high_damage_difficulty_total: int = 0
	var low_health_difficulty_total: int = 0
	var normal_combat_count: int = 0
	var high_damage_combat_count: int = 0

	for generation_seed in range(1000, 1100):
		var normal_context_batch := GenerationContext.new(80, 60, 10, 15, 2, generation_seed, 100, 120)

		var high_damage_context := GenerationContext.new(80, 60, 30, 30, 2, generation_seed, 100, 120)

		var low_health_difficulty_context := GenerationContext.new(20, 20, 10, 15, 2, generation_seed, 100, 120)

		var normal_graph_batch: GeneratedGraph = generator.generate(GRAPH_DEFINITION,normal_context_batch)

		var high_damage_graph: GeneratedGraph = generator.generate(GRAPH_DEFINITION,high_damage_context)

		var low_health_difficulty_graph: GeneratedGraph = generator.generate(GRAPH_DEFINITION,low_health_difficulty_context)

		normal_combat_count += _count_role(normal_graph_batch,"combat")
		
		high_damage_combat_count += _count_role(high_damage_graph,"combat")

		normal_difficulty_total += _sum_middle_difficulty(normal_graph_batch)

		high_damage_difficulty_total += _sum_middle_difficulty(high_damage_graph)

		low_health_difficulty_total += _sum_middle_difficulty(low_health_difficulty_graph)

	print("Dificultad normal: ", normal_difficulty_total)
	print("Dificultad con daño alto: ", high_damage_difficulty_total)
	print("Dificultad con vida baja: ", low_health_difficulty_total)
	print("Combates normal: ", normal_combat_count)
	print("Combates daño alto: ", high_damage_combat_count)

func _count_role(graph: GeneratedGraph, role: String ) -> int:
	var count: int = 0

	for room_id in graph.rooms.keys():
		var room: GeneratedRoom = graph.get_room(room_id)

		if room.room_role == role:
			count += 1

	return count


func _sum_middle_difficulty(graph: GeneratedGraph) -> int:
	var total_difficulty: int = 0

	for room_id in graph.rooms.keys():
		if room_id == graph.start_room_id:
			continue

		if room_id == graph.exit_room_id:
			continue

		var room: GeneratedRoom = graph.get_room(room_id)
		total_difficulty += room.difficulty

	return total_difficulty
