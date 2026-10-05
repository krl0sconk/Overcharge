extends Node

const ROOM_DEFINITION: RoomDefinition = preload("res://resources/maps/test_room_definition.tres")

func _ready() -> void:
	assert(ROOM_DEFINITION.room_id == &"test_room")
	assert(ROOM_DEFINITION.room_role == "start")
	assert(is_equal_approx(ROOM_DEFINITION.base_weight, 1.0))
	assert(ROOM_DEFINITION.base_difficulty == 0)
	assert(ROOM_DEFINITION.room_scene != null)
	print("RoomDefinition funciona correctamente.")
	print("room_id: ", ROOM_DEFINITION.room_id)
	print("room_role: ", ROOM_DEFINITION.room_role)
	print("base_weight: ", ROOM_DEFINITION.base_weight)
	print("base_difficulty: ", ROOM_DEFINITION.base_difficulty)
	print("room_scene: ", ROOM_DEFINITION.room_scene)
