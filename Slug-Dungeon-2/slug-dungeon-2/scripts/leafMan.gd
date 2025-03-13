extends CharacterBody2D

var leafItem = preload("res://leafItem.tscn")

# Reference to the AnimatedSprite2D node
@export var animated_sprite: AnimatedSprite2D

# Reference to the death sprite (make sure it's initially invisible in the editor)
@export var death_sprite: Sprite2D

# Reference to the looping sound player (e.g., AudioStreamPlayer)
@export var looping_sound: AudioStreamPlayer2D

# Reference to the death sound player (e.g., AudioStreamPlayer)
@export var death_sound: AudioStreamPlayer2D

# Reference to the death sound player (e.g., AudioStreamPlayer)
@export var death_particle: GPUParticles2D

@export var Area: Area2D


# Gravity variable
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var isDead:bool = false
var collisions = []

func _ready():
	# Ensure the death sprite is invisible at the start
	death_sprite.visible = false
	

func _physics_process(delta: float) -> void:
	
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	print("collided") # Replace with function body.

	if !isDead and area.is_in_group("Attack") :#and collisions[i].is_in_group("Attack"):  # Access the element at index i

		isDead = true
		death_particle.emitting = true
		
		var instance = leafItem.instantiate() # Replace with function body.
			
		# Make the animated sprite invisible
		animated_sprite.visible = false
			
		# Make the death sprite visible
		#death_sprite.visible = true
			
		# Stop the looping sound
		if looping_sound.playing:
			looping_sound.stop()
			
		# Play the death sound (if not already playing)
		if not death_sound.playing:
				death_sound.play()
			
		# Disable further collisions (optional)
		set_collision_mask_value(1, false)  # Disable collision with layer 1 (Player)
		
		if get_parent():
			get_parent().add_child(instance)
			instance.global_position = global_position
		
		# Wait for the death particle effect to finish before removing the creature
		await get_tree().create_timer(death_particle.lifetime).timeout
		
		# Remove the creature from the scene
		queue_free()
