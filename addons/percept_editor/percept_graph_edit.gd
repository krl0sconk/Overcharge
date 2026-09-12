@tool
extends GraphEdit
class_name PerceptGraphEdit

signal palette_node_dropped(script_path: String, graph_position: Vector2)

func _ready() -> void:
	show_menu = false
	show_arrange_button = false
	show_minimap_button = false
	show_zoom_label = true
	show_grid = true
	grid_pattern = GraphEdit.GRID_PATTERN_DOTS
	connection_lines_curvature = 0.35
	connection_lines_thickness = 4.0
	minimap_enabled = false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("percept_script")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	var graph_position: Vector2 = (at_position + scroll_offset) / zoom
	palette_node_dropped.emit(str(data["percept_script"]), graph_position)
