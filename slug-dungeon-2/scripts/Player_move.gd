extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const MAX_CHARGE_TIME = 1.0
const MAX_CHARGE_JUMP_VELOCITY = -800.0
const WALL_JUMP_HORIZONTAL_MULTIPLIER = 0.8  # Adjust horizontal wall jump strength

var is_charging_jump := false
var charge_time := 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Reference to the head RigidBody2D nodes
@export var head_nodes: Array[RigidBody2D]

# Reference to the body RigidBody2D
@export var body: RigidBody2D

var head_original_positions: Array[Vector2]

# Player sprite references
@export var player_right: Node2D
@export var player_left: Node2D
@export var player_up_left: Node2D
@export var player_up_right: Node2D
@export var player_down_left: Node2D
@export var player_down_right: Node2D

@export var full_player: Node2D

func _ready():
	set_player_visible("right")  # Default to right-facing
	head_original_positions = []
	for node in head_nodes:
		head_original_positions.append(node.position)

func _physics_process(delta: float) -> void:
	# Gravity handling
	var applied_gravity = Vector2.ZERO
	if is_on_wall():
		var wall_normal = get_wall_normal()
		applied_gravity = -wall_normal * gravity
		
		# Set sprite direction based on wall side and movement direction
		var Ydirection = Input.get_axis("ui_down", "ui_up")
		if wall_normal.x < 0:  # Right wall
			if Ydirection > 0:
				set_player_visible("down_right")
			else:
				set_player_visible("up_right")
		else:  # Left wall
			if Ydirection > 0:
				set_player_visible("down_left")
			else:
				set_player_visible("up_left")
	elif not is_on_floor():
		applied_gravity = Vector2.DOWN * gravity
	
	velocity += applied_gravity * delta
	
	# Jump charging
	if Input.is_action_pressed("ui_accept") and (is_on_floor() or is_on_wall()):
		if not is_charging_jump:
			is_charging_jump = true
			head_original_positions = []
			for node in head_nodes:
				head_original_positions.append(node.position)
			velocity = Vector2.ZERO  # Stop all movement when charging
		charge_time = min(charge_time + delta, MAX_CHARGE_TIME)
		contract_head(charge_time / MAX_CHARGE_TIME)

	# Jump release
	if Input.is_action_just_released("ui_accept") and (is_on_floor() or is_on_wall()):
		is_charging_jump = false
		var jump_power = lerp(JUMP_VELOCITY, MAX_CHARGE_JUMP_VELOCITY, charge_time / MAX_CHARGE_TIME)
		
		if is_on_floor():
			velocity.y = jump_power
		elif is_on_wall():
			var wall_normal = get_wall_normal()
			velocity = (-wall_normal * WALL_JUMP_HORIZONTAL_MULTIPLIER + Vector2.UP) * jump_power
		
		charge_time = 0.0
		reset_head()

	# Movement handling
	if not is_charging_jump:
		var direction = Input.get_axis("ui_left", "ui_right")
		var Ydirection = Input.get_axis("ui_down", "ui_up")
		
		if is_on_wall():
			var wall_normal = get_wall_normal()
			var tangent = wall_normal.rotated(PI/2)  # Get vertical movement direction
			velocity += tangent * Ydirection * SPEED
			velocity = velocity.limit_length(SPEED)
			if direction:
				velocity.x = direction * SPEED
				# Set player visibility based on direction and wall normal
				if wall_normal.x < 0:  # Right wall
					set_player_visible("up_right" if direction > 0 else "up_left")
				else:  # Left wall
					set_player_visible("up_left" if direction > 0 else "up_right")
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			if direction:
				velocity.x = direction * SPEED
				set_player_visible("right" if direction > 0 else "left")
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func contract_head(charge_ratio: float):
	var contraction = charge_ratio * 4.0
	for i in head_nodes.size():
		var dir = (body.position - head_original_positions[i]).normalized()
		head_nodes[i].position = head_original_positions[i] + dir * contraction

func reset_head():
	for i in head_nodes.size():
		head_nodes[i].position = head_original_positions[i]

func set_player_visible(direction: String):
	player_right.visible = (direction == "right")
	player_left.visible = (direction == "left")
	player_up_left.visible = (direction == "up_left")
	player_up_right.visible = (direction == "up_right")
	player_down_left.visible = (direction == "down_left")
	player_down_right.visible = (direction == "down_right")
