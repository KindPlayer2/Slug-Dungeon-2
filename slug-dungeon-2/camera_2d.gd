extends Camera2D

@export var playa: CharacterBody2D

# The minimum Y position the camera can have in global coordinates
const MIN_Y_POSITION: float = 800.0

# The target Y offset when the camera is above MIN_Y_POSITION
const TARGET_OFFSET: float = -100.0

# The speed of the lerp (adjust for smoother or faster transitions)
const LERP_SPEED: float = 2.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Determine the target offset based on the camera's global Y position
	var target_offset_y: float = 0.0
	if global_position.y > MIN_Y_POSITION:
		target_offset_y = TARGET_OFFSET

	# Smoothly lerp the camera's offset towards the target offset
	offset.y = lerp(offset.y, target_offset_y, LERP_SPEED * delta)
