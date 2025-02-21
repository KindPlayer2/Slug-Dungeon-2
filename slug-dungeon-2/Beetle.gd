extends StaticBody2D

# Reference to the AnimatedSprite2D node
@export var animated_sprite: AnimatedSprite2D

@export var audio_stream_player_2d: AudioStreamPlayer2D

# Reference to the death sound player (e.g., AudioStreamPlayer)
@export var death_particle: GPUParticles2D

# Reference to the death sprite (make sure it's initially invisible in the editor)
@export var death_sprite: Sprite2D

# Gravity variable
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var isDead: bool = false

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
