class_name GraphGenerator
extends RefCounted

func generate(
	graph_definition: GraphDefinition,context: GenerationContext) -> GeneratedGraph:
	var generated_graph := GeneratedGraph.new(
		context.seed,
		graph_definition.start_room_id,
		graph_definition.exit_room_id
	)

	var start_definition := _find_room_definition(
		graph_definition,
		graph_definition.start_room_id
	)

	var exit_definition := _find_room_definition(
		graph_definition,
		graph_definition.exit_room_id
	)

	if start_definition == null or exit_definition == null:
		return generated_graph

	var start_room := GeneratedRoom.new(start_definition,Vector2i(0, 0),start_definition.base_difficulty)

	generated_graph.add_room(start_room)

	var random_generator := RandomNumberGenerator.new()
	random_generator.seed = context.seed

	var candidates: Array[RoomDefinition] = (graph_definition.candidate_room_definitions.duplicate())

	var middle_room_count: int = graph_definition.target_room_count - 2
	middle_room_count = clampi(middle_room_count,0,candidates.size())

	var previous_room_id: StringName = start_definition.room_id
	var middle_position: int = 1

	for index in middle_room_count:
		var selected_definition: RoomDefinition = _select_candidate(candidates, context, random_generator)

		candidates.erase(selected_definition)

		var middle_room := GeneratedRoom.new(selected_definition,Vector2i(middle_position, 0),_get_adjusted_difficulty(selected_definition,context))

		generated_graph.add_room(middle_room)
		_add_connection(generated_graph,previous_room_id,selected_definition.room_id)

		previous_room_id = selected_definition.room_id
		middle_position += 1

	var exit_room := GeneratedRoom.new(exit_definition, Vector2i(middle_position, 0),exit_definition.base_difficulty)

	generated_graph.add_room(exit_room)

	_add_connection(generated_graph,previous_room_id,exit_definition.room_id)

	return generated_graph

func _find_room_definition(graph_definition: GraphDefinition,room_id: StringName) -> RoomDefinition:
	if room_id == graph_definition.start_room_id:
		for definition in graph_definition.room_definitions:
			if definition.room_id == room_id:
				return definition

	if room_id == graph_definition.exit_room_id:
		for definition in graph_definition.room_definitions:
			if definition.room_id == room_id:
				return definition

	return null

func _add_connection(generated_graph: GeneratedGraph,from_room_id: StringName,to_room_id: StringName) -> void:
	var connection := RoomConnection.new()
	connection.from_room_id = from_room_id
	connection.to_room_id = to_room_id
	connection.bidirectional = true
	generated_graph.connections.append(connection)

func _select_candidate( candidates: Array[RoomDefinition], context: GenerationContext, random_generator: RandomNumberGenerator) -> RoomDefinition:
	var weights: Array[float] = []
	var total_weight: float = 0.0

	for definition in candidates:
		var weight: float = _get_adjusted_weight(definition,context)

		weights.append(weight)
		total_weight += weight

	if total_weight <= 0.0:
		return candidates[0]

	var selected_value: float = random_generator.randf_range(0.0,total_weight)

	var accumulated_weight: float = 0.0

	for index in candidates.size():
		accumulated_weight += weights[index]

		if selected_value <= accumulated_weight:
			return candidates[index]

	return candidates.back()

func _get_adjusted_weight(definition: RoomDefinition, context: GenerationContext) -> float:
	var weight: float = definition.base_weight

	if definition.room_role == "reward":
		if context.health_ratio < 0.5:
			weight *= 2.0

	if definition.room_role == "combat":
		if context.average_damage >= 20.0:
			weight *= 1.5

	return weight

func _get_adjusted_difficulty(definition: RoomDefinition,context: GenerationContext) -> int:
	var difficulty: int = definition.base_difficulty

	if definition.room_role == "combat":
		if context.average_damage >= 20.0:
			difficulty += 1

	if context.health_ratio < 0.5:
		difficulty = maxi(difficulty - 1, 0)

	return difficulty