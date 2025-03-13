extends CharacterBody2D

@export var right_facing_softbody: Polygon2D
@export var left_facing_softbody: Polygon2D

@export var voice_line_1: AudioStreamPlayer2D
@export var voice_line_2: AudioStreamPlayer2D
@export var voice_line_3: AudioStreamPlayer2D
@export var voice_line_4: AudioStreamPlayer2D
@export var voice_line_5: AudioStreamPlayer2D
@export var voice_line_6: AudioStreamPlayer2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Movement variables
var move_direction := 1  # 1 for right, -1 for left
var move_distance := 0.0
var max_move_distance := randf_range(100.0, 400.0)  # Random distance
var speed := randf_range(100.0, 200.0)  # Random speed
var is_moving := true

# Stop variables
var stop_time := randf_range(1.0, 3.0)  # Random stop time
var stop_timer := 0.0

# Voice line variables
var voice_timer := 0.0
var voice_interval := randf_range(10.0, 20.0)  # Random interval for voice lines (10-20 seconds)

# Sounds
@export var walk_sound: AudioStreamPlayer2D

func _ready():
	# Initialize the walk sound
	walk_sound.play()
	# Set initial facing direction
	set_facing_direction(move_direction)
	# Initialize the voice timer with a random interval
	voice_timer = randf_range(10.0, 20.0)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_moving:
		# Movement logic
		velocity.x = move_direction * speed
		move_distance += abs(velocity.x) * delta

		# Check if the NPC has moved the maximum distance
		if move_distance >= max_move_distance:
			# Stop moving and start the stop timer
			is_moving = false
			stop_timer = 0.0
			velocity.x = 0  # Stop horizontal movement
			walk_sound.stop()  # Stop the walk sound

		# Move the NPC
		move_and_slide()

		# Play the walk sound if not already playing
		if not walk_sound.playing:
			walk_sound.play()
	else:
		# Stop timer logic
		stop_timer += delta
		if stop_timer >= stop_time:
			# Reset movement variables
			is_moving = true
			move_direction *= -1  # Reverse direction
			move_distance = 0.0
			max_move_distance = randf_range(100.0, 400.0)  # New random distance
			speed = randf_range(100.0, 200.0)  # New random speed
			stop_time = randf_range(1.0, 3.0)  # New random stop time

			# Update facing direction
			set_facing_direction(move_direction)

			# Restart the walk sound
			walk_sound.play()

	# Voice line logic
	voice_timer -= delta
	if voice_timer <= 0.0:
		play_random_voice_line()
		voice_timer = randf_range(10.0, 20.0)  # Reset the timer with a new random interval (10-20 seconds)

func set_facing_direction(direction: int) -> void:
	# Set visibility of the left and right-facing bodies based on direction
	if direction == 1:
		right_facing_softbody.visible = true
		left_facing_softbody.visible = false
	else:
		right_facing_softbody.visible = false
		left_facing_softbody.visible = true

func play_random_voice_line() -> void:
	var voice_lines = [voice_line_1, voice_line_2, voice_line_3, voice_line_4, voice_line_5, voice_line_6]
	var random_voice = voice_lines[randi() % voice_lines.size()]
	random_voice.play()
