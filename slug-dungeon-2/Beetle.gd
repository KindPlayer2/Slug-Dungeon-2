extends CharacterBody2D

# Reference to the AnimatedSprite2D node
@export var animated_sprite: AnimatedSprite2D

# Reference to the death sound player (e.g., AudioStreamPlayer)
@export var death_particle: GPUParticles2D

# Reference to the death sprite (make sure it's initially invisible in the editor)
@export var death_sprite: Sprite2D

# Gravity variable
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var isDead:bool = false

func _ready() -> void:
	# Ensure the death sprite is invisible at the start
	death_sprite.visible = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	

func _on_attack_area_entered(area: Area2D) -> void:
	death_sprite.visible = true
	animated_sprite.visible = false
