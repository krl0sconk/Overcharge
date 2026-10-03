extends Area3D

@export var level_index: int = 0
@export var level_name: String = "Nivel 1"
@export var preview_image: Texture2D

@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var prompt_label: Label3D = get_node_or_null("PromptLabel")

var _player_nearby: bool = false
var _preview_ui: Node = null

const COLOR_UNLOCKED := Color(1, 1, 1)
const COLOR_LOCKED := Color(0.2, 0.2, 0.2)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()
	if prompt_label:
		prompt_label.visible = false
	call_deferred("_find_preview_ui")

func _find_preview_ui() -> void:
	_preview_ui = get_tree().get_first_node_in_group("level_preview_ui")

func _process(_delta: float) -> void:
	if _player_nearby and LevelManager.is_unlocked(level_index):
		if Input.is_action_just_pressed("interact"):
			LevelManager.select_level(level_index)

func _on_body_entered(body: Node3D) -> void:
	print("DEBUG: algo entró al área -> ", body.name, " grupos: ", body.get_groups())
	if not body.is_in_group("players"):
		return
	_player_nearby = true

	if not LevelManager.is_unlocked(level_index):
		return

	if prompt_label:
		prompt_label.visible = true

	if _preview_ui != null:
		print("DEBUG preview_image: ", preview_image)
	_preview_ui.show_preview(preview_image, level_name, global_position)

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("players"):
		return
	_player_nearby = false

	if prompt_label:
		prompt_label.visible = false

	if _preview_ui != null:
		_preview_ui.hide_preview()

func _update_visual() -> void:
	if mesh == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_UNLOCKED if LevelManager.is_unlocked(level_index) else COLOR_LOCKED
	mesh.material_override = material
