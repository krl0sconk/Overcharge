class_name Entidad
extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var input_component: InputComponent = $InputComponent
@onready var ability_component: AbilityComponent = $AbilityComponent
@onready var hit_feedback_component: HitFeedbackComponent = $HitFeedbackComponent
