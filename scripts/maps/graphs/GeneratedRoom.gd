class_name GeneratedRoom
extends RefCounted

var room_id: StringName
var room_role: String
var position: Vector2i
var difficulty: int
var visited:bool = false
var completed:bool = false
func _init(definition: RoomDefinition, room_position: Vector2i, room_difficulty: int) -> void:
	room_id = definition.room_id
	room_role = definition.room_role
	position = room_position
	difficulty = room_difficulty
