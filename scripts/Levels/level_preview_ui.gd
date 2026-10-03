extends CanvasLayer

@onready var panel: Control = $Panel
@onready var preview_texture: TextureRect = $Panel/PreviewTexture
@onready var level_name_label: Label = $Panel/LevelNameLabel

@export var card_size: Vector2 = Vector2(260, 200)
@export var offset_above: float = 1.5
@export var max_tilt_degrees: float = 6.0
@export var pop_duration: float = 0.2

var _camera: Camera3D = null
var _target_world_position: Vector3 = Vector3.ZERO
var _following: bool = false
var _tween: Tween = null

func _ready() -> void:
	add_to_group("level_preview_ui")
	panel.pivot_offset = card_size / 2.0
	panel.custom_minimum_size = card_size
	panel.size = card_size
	panel.modulate.a = 0.0
	panel.visible = false
	panel.scale = Vector2(0.85, 0.85)

func show_preview(texture: Texture2D, level_name: String, world_position: Vector3) -> void:
	_camera = get_viewport().get_camera_3d()
	print("DEBUG camera: ", _camera)
	_target_world_position = world_position
	_following = true

	preview_texture.texture = texture
	level_name_label.text = level_name

	panel.visible = true
	_update_panel_position()

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_parallel(true)
	_tween.tween_property(panel, "scale", Vector2(1, 1), pop_duration)
	_tween.tween_property(panel, "modulate:a", 1.0, pop_duration)

func hide_preview() -> void:
	_following = false

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_parallel(true)
	_tween.tween_property(panel, "scale", Vector2(0.85, 0.85), pop_duration)
	_tween.tween_property(panel, "modulate:a", 0.0, pop_duration)
	_tween.chain().tween_callback(func(): panel.visible = false)

func _process(_delta: float) -> void:
	if _following:
		_update_panel_position()

func _update_panel_position() -> void:
	if _camera == null:
		return

	if _camera.is_position_behind(_target_world_position):
		return

	var screen_pos: Vector2 = _camera.unproject_position(_target_world_position)

	# Desplaza la tarjeta hacia arriba en PÍXELES de pantalla, no en unidades 3D
	var pixel_offset_above: float = 40.0
	panel.position = screen_pos - Vector2(card_size.x / 2.0, card_size.y + pixel_offset_above)

	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var normalized_offset: float = (screen_pos.x - viewport_width / 2.0) / (viewport_width / 2.0)
	normalized_offset = clamp(normalized_offset, -1.0, 1.0)
	panel.rotation = deg_to_rad(normalized_offset * max_tilt_degrees)
