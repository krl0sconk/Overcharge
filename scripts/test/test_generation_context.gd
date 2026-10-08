extends Node
func _ready() -> void:
	var context = GenerationContext.new(80, 60, 10, 15, 2, 12345, 100, 120)
	assert(context.player_1_current_health == 80)
	assert(context.player_2_current_health == 60)
	assert(is_equal_approx(context.average_damage, 12.5))
	assert(context.player_count == 2)
	assert(context.seed == 12345)
	assert(context.player_1_max_health == 100)
	assert(context.player_2_max_health == 120)
	assert(is_equal_approx(context.health_ratio, 140.0 / 220.0))

	print("GenerationContext funciona correctamente.")
	print("player_1_current_health: ", context.player_1_current_health)
	print("player_2_current_health: ", context.player_2_current_health)
	print("average_damage: ", context.average_damage)
	print("seed: ", context.seed)
	print("health_ratio: ", context.health_ratio)
	
