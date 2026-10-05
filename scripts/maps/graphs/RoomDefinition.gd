class_name RoomDefinition
extends Resource
@export var room_id: StringName= &""
@export_enum("start", "combat", "reward", "event", "elite", "boss","exit")
var room_role: String ="combat"
@export var room_scene: PackedScene
@export_range(0.0, 100.0, 0.1) var base_weight: float = 1.0
@export_range(0, 100, 1) var base_difficulty: int = 1
