extends CharacterBody2D

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

# Gravity variable
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var isDead:bool = false

func _ready():
	# Ensure the death sprite is invisible at the start
	death_sprite.visible = false
	

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	# Check for collisions with the Player group
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("Player"):
			on_player_collision()

func on_player_collision():
	
	death_particle.emitting = true
	
	# Make the animated sprite invisible
	animated_sprite.visible = false
	
	# Make the death sprite visible
	death_sprite.visible = true
	
	# Stop the looping sound
	if looping_sound.playing:
		looping_sound.stop()
	
	# Play the death sound (if not already playing)
	if not death_sound.playing:
		death_sound.play()
	
	# Disable further collisions (optional)
	set_collision_mask_value(1, false)  # Disable collision with layer 1 (Player)


func _on_area_2d_area_entered(area: Area2D) -> void:
	print("collided") # Replace with function body.
	if !isDead:
		isDead = true
		death_particle.emitting = true
		
		# Make the animated sprite invisible
		animated_sprite.visible = false
		
		# Make the death sprite visible
		death_sprite.visible = true
		
		# Stop the looping sound
		if looping_sound.playing:
			looping_sound.stop()
		
		# Play the death sound (if not already playing)
		if not death_sound.playing:
			death_sound.play()
		
		# Disable further collisions (optional)
		set_collision_mask_value(1, false)  # Disable collision with layer 1 (Player)
