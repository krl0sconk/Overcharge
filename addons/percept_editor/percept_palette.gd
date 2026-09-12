@tool
extends ItemList
class_name PerceptPalette

func set_types(types: Array) -> void:
	clear()
	for type_info in types:
		var class_name_text: String = str(type_info.get("class_name", "PerceptNode"))
		var script_path: String = str(type_info.get("script_path", ""))
		add_item(class_name_text)
		set_item_metadata(item_count - 1, script_path)
		set_item_tooltip(item_count - 1, script_path)

func _get_drag_data(at_position: Vector2) -> Variant:
	var index: int = get_item_at_position(at_position, true)
	if index < 0:
		return null

	var preview := Label.new()
	preview.text = get_item_text(index)
	preview.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	set_drag_preview(preview)
	return {
		"percept_script": str(get_item_metadata(index)),
		"percept_name": get_item_text(index),
	}
