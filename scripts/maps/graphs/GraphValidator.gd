class_name GraphValidator
extends RefCounted

static func validate(graph: GraphDefinition) -> Dictionary:
	var errors: Array[String]=[]
	var room_ids: Dictionary ={}
	var adjacency: Dictionary ={}
	var connection_keys: Dictionary = {}

	for room_definition in graph.room_definitions:
		if room_definition == null:
			errors.append("existe una definicion de sala nula")
			continue

		var room_id: StringName = room_definition.room_id

		if room_id == &"":
			errors.append("existe una sala sin identificador")
			continue
		if room_ids.has(room_id):
			errors.append("el identificador esta repetido %s" % room_id)
			continue
		room_ids[room_id] = true
		adjacency[room_id] = []
	
	if not room_ids.has(graph.start_room_id):
		errors.append("la sala inicial no existe %s" % graph.start_room_id)
	
	if not room_ids.has(graph.exit_room_id):
		errors.append("la sala final no existe %s" % graph.exit_room_id)

	for connection in graph.connections:
		if connection == null:
			errors.append("existe una conexion nula")
			continue
		
		if not room_ids.has(connection.from_room_id):
			errors.append("origen inexistente %s" % connection.from_room_id)
			continue
		
		if not room_ids.has(connection.to_room_id):
			errors.append("destino inexistente %s" % connection.to_room_id)
			continue
		
		var first_room_id: String = str(connection.from_room_id)
		var second_room_id: String = str(connection.to_room_id)
		var connection_key: String

		if connection.bidirectional:
			if first_room_id < second_room_id:
				connection_key = "%s<->%s" % [first_room_id, second_room_id]
			else:
				connection_key = "%s<->%s" % [second_room_id, first_room_id]
		else:
			connection_key = "%s->%s" % [first_room_id, second_room_id]

		if connection_keys.has(connection_key):
			errors.append("Conexion duplicada: %s" % connection_key)
			continue

		connection_keys[connection_key] = true
		
		adjacency[connection.from_room_id].append(connection.to_room_id)

		if connection.bidirectional:
			adjacency[connection.to_room_id].append(connection.from_room_id)
	
	var visited: Dictionary = {}
	var queue: Array = []

	if room_ids.has(graph.start_room_id):
		queue.append(graph.start_room_id)
		visited[graph.start_room_id] = true
	
	var queue_index: int = 0

	while queue_index < queue.size():
		var current_room_id: StringName = queue[queue_index]
		queue_index += 1

		for neighbor_room_id in adjacency[current_room_id]:
			if visited.has(neighbor_room_id):
				continue
			
			visited[neighbor_room_id] = true
			queue.append(neighbor_room_id)
	
	if room_ids.has(graph.exit_room_id):
		if not visited.has(graph.exit_room_id):
			errors.append("la sala final no es alcanzable desde la sala inicial")
	
	if visited.size() != room_ids.size():
		errors.append("hay salas que no son alcanzables desde la sala inicial")
	
	return{
		"valid": errors.is_empty(),
		"errors": errors,
		"visited_count": visited.size()
	}

static func validate_generated(graph: GeneratedGraph) -> Dictionary:
	var errors: Array[String] = []
	var adjacency: Dictionary = {}

	for room_id in graph.rooms.keys():
		adjacency[room_id] = []

	if not graph.rooms.has(graph.start_room_id):
		errors.append("La sala inicial generada no existe.")

	if not graph.rooms.has(graph.exit_room_id):
		errors.append("La sala final generada no existe.")

	for connection in graph.connections:
		if connection == null:
			errors.append("Existe una conexion generada nula.")
			continue

		if not graph.rooms.has(connection.from_room_id):
			errors.append("Origen generado inexistente.")
			continue

		if not graph.rooms.has(connection.to_room_id):
			errors.append("Destino generado inexistente.")
			continue

		adjacency[connection.from_room_id].append(
			connection.to_room_id
		)

		if connection.bidirectional:
			adjacency[connection.to_room_id].append(
				connection.from_room_id
			)

	var visited: Dictionary = {}
	var queue: Array[StringName] = []

	if graph.rooms.has(graph.start_room_id):
		queue.append(graph.start_room_id)
		visited[graph.start_room_id] = true

	var queue_index: int = 0

	while queue_index < queue.size():
		var current_room_id: StringName = queue[queue_index]
		queue_index += 1

		for neighbor_room_id in adjacency[current_room_id]:
			if visited.has(neighbor_room_id):
				continue

			visited[neighbor_room_id] = true
			queue.append(neighbor_room_id)

	if graph.rooms.has(graph.exit_room_id):
		if not visited.has(graph.exit_room_id):
			errors.append(
                "La sala final generada no es alcanzable."
			)

	if visited.size() != graph.rooms.size():
		errors.append(
            "Existen salas generadas desconectadas."
		)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"visited_count": visited.size()
	}
