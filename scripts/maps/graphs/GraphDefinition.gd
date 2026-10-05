class_name GraphDefinition
extends Resource
@export var graph_id: StringName = &""
@export_range(2, 50, 1) var minimum_rooms: int=2
@export_range(2, 50, 1) var maximum_rooms: int=5
@export_range(2, 50, 1) var target_room_count: int=5
@export var start_room_id: StringName = &""
@export var exit_room_id: StringName = &""
@export var room_definitions: Array[RoomDefinition] = []
@export var connections: Array[RoomConnection] = []
