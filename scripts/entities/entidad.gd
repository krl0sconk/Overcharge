class_name Entidad
extends CharacterBody3D

## Clase base delgada: solo cablea componentes y expone acceso a ellos, cero
## comportamiento propio. Ninguna entidad tiene todos los componentes (el
## Centinela no se mueve, los enemigos no tienen Input/Ability, el Virus no
## ataca), así que la búsqueda es opcional -- get_node_or_null en vez de $ --
## y cada campo puede quedar en null sin romper _ready().

@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")
@onready var hurtbox_component: HurtboxComponent = get_node_or_null("HurtboxComponent")
@onready var hitbox_component: HitboxComponent = get_node_or_null("HitboxComponent")
@onready var movement_component: MovementComponent = get_node_or_null("MovementComponent")
@onready var input_component: InputComponent = get_node_or_null("InputComponent")
@onready var ability_component: AbilityComponent = get_node_or_null("AbilityComponent")
@onready var hit_feedback_component: HitFeedbackComponent = get_node_or_null("HitFeedbackComponent")
