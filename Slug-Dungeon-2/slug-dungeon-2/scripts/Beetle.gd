extends StaticBody2D

var beetleItem = preload("res://beetleItem.tscn")

# Reference to the AnimatedSprite2D node
@export var animated_sprite: AnimatedSprite2D

@export var audio_stream_player_2d: AudioStreamPlayer2D

# Reference to the death sound player (e.g., AudioStreamPlayer)
@export var death_particle: GPUParticles2D

# Reference to the death sprite (make sure it's initially invisible in the editor)
@export var death_sprite: Sprite2D
@export var behind_sprite: Sprite2D

@export var attackArea: Area2D
@export var weakArea: Area2D

@export var deadtimer:Timer

# Gravity variable
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var isDead: bool = false

func _ready() -> void:
	# Ensure the death sprite is invisible at the start
	death_sprite.visible = false
	animated_sprite.play("idle")
	
	# Connect the animation_finished signal to a callback function
	animated_sprite.connect("animation_finished", Callable(self, "_on_animated_sprite_animation_finished"))

func _on_attack_area_entered(area: Area2D) -> void:
	# Play the "attack" animation
	animated_sprite.play("attack")
	audio_stream_player_2d.play()

func _on_animated_sprite_animation_finished() -> void:
	# Check if the current animation was "attack"
	if animated_sprite.animation == "attack":
		# Switch back to the "idle" animation
		animated_sprite.play("idle")
		

func _on_weakness_area_entered(area: Area2D) -> void:
	print("collided") # Replace with function body.
	if area.is_in_group("Player"):
		animated_sprite.visible = false
		behind_sprite.visible = true

	if !isDead and area.is_in_group("Attack"):
		isDead = true
		behind_sprite.visible = false
		death_particle.emitting = true
		
		var instance = beetleItem.instantiate() # Replace with function body.
			
		# Make the animated sprite invisible
		animated_sprite.visible = false
			
		# Make the death sprite visible
		#death_sprite.visible = true
		
		weakArea.monitoring = false
		weakArea.monitorable = false
		weakArea.visible = false
		attackArea.monitoring = false
		attackArea.monitorable = false
		attackArea.visible = false
		
		# Disable further collisions (optional)
		set_collision_mask_value(1, false)  # Disable collision with layer 1 (Player)
		
		deadtimer.start()
		
		# Reparent the beetleItem to the beetle's parent
		if get_parent():
			get_parent().add_child(instance)
			instance.global_position = global_position
		
		# Remove the creature from the scene
		#queue_free()


func _on_weakness_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player") and !isDead:
		animated_sprite.visible = true
		behind_sprite.visible = false


func _on_timer_timeout() -> void:
	queue_free()
