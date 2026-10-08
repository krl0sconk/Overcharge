extends Node

const GRAPH_DEFINITION: GraphDefinition = preload(
    "res://resources/maps/test/test_graph_definition.tres"
)

func _ready() -> void:
	var manager := DungeonRunManager.new()

	var first_context := GenerationContext.new(
		80,
		60,
		10,
		15,
		2,
		12345,
		100,
		120
	)

	var second_context := GenerationContext.new(
		80,
		60,
		30,
		30,
		2,
		54321,
		100,
		120
	)

	var first_state: Dictionary = manager.get_or_create_level(
		&"test_level",
		GRAPH_DEFINITION,
		first_context
	)

	var second_state: Dictionary = manager.get_or_create_level(
		&"test_level",
		GRAPH_DEFINITION,
		second_context
	)

	assert(first_state["seed"] == 12345)
	assert(second_state["seed"] == 12345)
	assert(
		first_state["generated_graph"]
		== second_state["generated_graph"]
	)
	assert(
		first_state["current_room_id"]
		== &"test_room"
	)
	assert(
		first_state["visited_rooms"].has(&"test_room")
	)
	
	SessionRegistry.mark_room_visited(
		&"test_level",
		&"test_event"
	)

	SessionRegistry.mark_room_completed(&"test_level",&"test_event")

	var updated_state: Dictionary = SessionRegistry.get_level(
		&"test_level"
	)

	assert(updated_state["current_room_id"]== &"test_event"    )

	assert(updated_state["visited_rooms"].has(&"test_event"))

	assert(updated_state["completed_rooms"].has(&"test_event"))


	print("DungeonRunManager funciona correctamente.")
	print("Semilla conservada: ", second_state["seed"])
	print("El mismo grafo fue reutilizado.")
	print("Estado de sala conservado correctamente.")
	print("Sala actual: ", updated_state["current_room_id"])
