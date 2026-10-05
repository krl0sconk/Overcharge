class_name GeneratedGraph
extends RefCounted

var seed: int
var start_room_id: StringName
var exit_room_id: StringName
var rooms: Dictionary={}
var connections: Array[RoomConnection]=[]

func _init(generation_seed: int, start_id: StringName, exit_id: StringName) -> void:
	seed = generation_seed
	start_room_id = start_id
	exit_room_id = exit_id

func add_room(room: GeneratedRoom) -> void:
	rooms[room.room_id] = room

func has_room(room_id: StringName) -> bool:
	return rooms.has(room_id)

func get_room(room_id: StringName) -> GeneratedRoom:
	return rooms.get(room_id)
	
