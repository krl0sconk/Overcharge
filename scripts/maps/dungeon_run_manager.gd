class_name DungeonRunManager
extends RefCounted

func get_or_create_level(level_id: StringName, graph_definition: GraphDefinition, context: GenerationContext) -> Dictionary:
	if SessionRegistry.has_level(level_id):
		return SessionRegistry.get_level(level_id)
	
	var generator := GraphGenerator.new()

	var generated_graph: GeneratedGraph = generator.generate(graph_definition, context)

	return SessionRegistry.register_level(level_id, generated_graph)
