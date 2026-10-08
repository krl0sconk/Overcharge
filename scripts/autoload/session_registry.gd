extends Node

var level_runs: Dictionary ={}

func has_level(level_id: StringName) -> bool:
	return level_runs.has(level_id)

func register_level(level_id: StringName, generated_graph: GeneratedGraph) -> Dictionary:
	if level_runs.has(level_id):
		return level_runs[level_id]
	
	var level_state: Dictionary ={
		"seed": generated_graph.seed,
		"generated_graph": generated_graph,
		"current_room_id": generated_graph.start_room_id,
		"visited_rooms": {
			generated_graph.start_room_id: true
		},
		"completed_rooms":{},
		"room_states":{}
	}
	level_runs[level_id] = level_state
	return level_state

func get_level(level_id: StringName) -> Dictionary:
	return level_runs.get(level_id, {})

func mark_room_visited(level_id: StringName, room_id: StringName) -> void:
	if not level_runs.has(level_id):
		return

	level_runs[level_id]["visited_rooms"][room_id] = true
	level_runs[level_id]["current_room_id"] = room_id

func mark_room_completed(level_id: StringName, room_id: StringName) -> void:
	if not level_runs.has(level_id):
		return
	level_runs[level_id]["completed_rooms"][room_id] = true
