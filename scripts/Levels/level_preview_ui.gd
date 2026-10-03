extends CanvasLayer

@onready var panel: Control = $Panel
@onready var preview_texture: TextureRect = $Panel/PreviewTexture
@onready var level_name_label: Label = $Panel/LevelNameLabel

func _ready() -> void:
	add_to_group("level_preview_ui")
	panel.visible = false

func show_preview(texture: Texture2D, level_name: String) -> void:
	preview_texture.texture = texture
	level_name_label.text = level_name
	panel.visible = true

func hide_preview() -> void:
	panel.visible = false
