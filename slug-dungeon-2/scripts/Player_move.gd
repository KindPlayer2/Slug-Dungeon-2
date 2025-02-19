extends CharacterBody2D

var mynode = preload("res://player.tscn")

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const MAX_CHARGE_TIME = 1.0
const MAX_CHARGE_JUMP_VELOCITY = -800.0
const WALL_JUMP_HORIZONTAL_MULTIPLIER = 0.8  # Adjust horizontal wall jump strength

var is_charging_jump := false
var charge_time := 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Reference to the head RigidBody2D nodes
@export var head_nodes_right: Array[RigidBody2D]
var head_right_original_positions: Array[Vector2]

#left
@export var head_nodes_left: Array[RigidBody2D]
var head_left_original_positions: Array[Vector2]

# Reference to the body RigidBody2D
@export var bodyRight: RigidBody2D
@export var bodyLeft: RigidBody2D

#the softbodies for determining the direction of sprite
@export var right_facing_softbody: Polygon2D
@export var left_facing_softbody: Polygon2D

#Pins used for movement, change positions when on wall for natural movement
#right pins
@export var PinRightOne: PinJoint2D
@export var PinRightTwo: PinJoint2D

#left pins
@export var PinLeftOne: PinJoint2D
@export var PinLeftTwo: PinJoint2D

# Track whether the player was on the wall in the previous frame
var was_on_wall := false

# Store the last wall tangent for smooth momentum transition
var _last_wall_tangent: Vector2

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Rotate"):
		reset_player()
		
var initial_body_right_position: Vector2
var initial_body_right_velocity: Vector2
var initial_body_left_position: Vector2
var initial_body_left_velocity: Vector2
var initial_pin_right_one_node_b: NodePath
var initial_pin_right_two_node_b: NodePath
var initial_pin_left_one_node_b: NodePath
var initial_pin_left_two_node_b: NodePath

func _ready():
	#make player visible
	set_player_visible(true)
	
	#assign the heads original positions 
	head_right_original_positions = []
	head_left_original_positions = []
	
	#2 for loops to assign head bone positions
	for node in head_nodes_right:
		head_right_original_positions.append(node.position)
		
	for node in head_nodes_left:
		head_left_original_positions.append(node.position)
	
	# Store initial state
	initial_body_right_position = bodyRight.position
	initial_body_right_velocity = bodyRight.linear_velocity
	initial_body_left_position = bodyLeft.position
	initial_body_left_velocity = bodyLeft.linear_velocity
	initial_pin_right_one_node_b = PinRightOne.node_b
	initial_pin_right_two_node_b = PinRightTwo.node_b
	initial_pin_left_one_node_b = PinLeftOne.node_b
	initial_pin_left_two_node_b = PinLeftTwo.node_b
	
func reset_player():
	# Reset body properties
	bodyRight.position = initial_body_right_position
	bodyRight.linear_velocity = initial_body_right_velocity
	
	bodyLeft.position = initial_body_left_position
	bodyLeft.linear_velocity = initial_body_left_velocity
	
	# Reset head positions
	for i in head_nodes_right.size():
		head_nodes_right[i].position = head_right_original_positions[i]
		
	for i in head_nodes_left.size():
		head_nodes_left[i].position = head_left_original_positions[i]
	
	# Reset pin joint configurations
	PinRightOne.node_b = initial_pin_right_one_node_b
	PinRightTwo.node_b = initial_pin_right_two_node_b
	PinLeftOne.node_b = initial_pin_left_one_node_b
	PinLeftTwo.node_b = initial_pin_left_two_node_b
	
	# Reset other properties as needed
	velocity = Vector2.ZERO
	is_charging_jump = false
	charge_time = 0.0

func reset_wall_state():
	# Reset only wall-specific components
	PinRightOne.node_b = initial_pin_right_one_node_b
	PinRightTwo.node_b = initial_pin_right_two_node_b
	PinLeftOne.node_b = initial_pin_left_one_node_b
	PinLeftTwo.node_b = initial_pin_left_two_node_b
	
	# Reset head positions without affecting other state
	for i in head_nodes_right.size():
		head_nodes_right[i].position = head_right_original_positions[i]
	for i in head_nodes_left.size():
		head_nodes_left[i].position = head_left_original_positions[i]
	
	# Keep character visible state consistent
	set_player_visible(right_facing_softbody.visible)

	# Reset charging state
	is_charging_jump = false
	charge_time = 0.0
	
func _physics_process(delta: float) -> void:
	# Check if the player was on the wall in the previous frame but is no longer on the wall
	if was_on_wall and not is_on_wall():
		# Save velocity before resetting
		var preserved_velocity = velocity
		# Reset wall-specific state without affecting velocity
		reset_player()  
		# Restore velocity to maintain momentum
		velocity = preserved_velocity
	
	# Update the was_on_wall variable for the next frame
	was_on_wall = is_on_wall()

	# Gravity handling
	var applied_gravity = Vector2.ZERO
	if is_on_wall():
		var wall_normal = get_wall_normal()
		applied_gravity = -wall_normal * gravity
	elif not is_on_floor():
		applied_gravity = Vector2.DOWN * gravity
	
	velocity += applied_gravity * delta

	# Jump charging
	if Input.is_action_pressed("ui_accept") and (is_on_floor() or is_on_wall()):
		#only when a jump is not being charged
		if not is_charging_jump:
			#jump is set to be charging
			is_charging_jump = true
			
			#retract the head bones for left and right
			head_right_original_positions = []
			head_left_original_positions = []
			
			#retract bones one by one in forloops 
			for node in head_nodes_right:
				head_right_original_positions.append(node.position)
				
			for node in head_nodes_left:
				head_left_original_positions.append(node.position)
			
			# Stop all movement when charging
			velocity = Vector2.ZERO 
		
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
		var WallDirection = Input.get_axis("ui_up", "ui_down")

		if is_on_wall():
			PinRightTwo.node_b = "SoftBodyRight/Bone-22"
			PinLeftTwo.node_b = "SoftBodyLeft/Bone-0"
			var wall_normal = get_wall_normal()
			
			# Determine rotation based on facing direction
			var is_facing_right = right_facing_softbody.visible
			var rotation_angle = -PI/2 if is_facing_right else PI/2
			var tangent = wall_normal.rotated(rotation_angle)
			
			# Store last wall movement direction
			_last_wall_tangent = tangent
			
			velocity += tangent * WallDirection * SPEED * delta
			velocity = velocity.limit_length(SPEED)
		else:
			if direction:
				velocity.x = direction * SPEED
				set_player_visible(direction > 0)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func contract_head(charge_ratio: float):
	#how strong should head contraction be 4~ change for intensity of contraction
	var contraction = charge_ratio * 4.0
	
	#move the head bones
	for i in head_nodes_right.size():
		var dir = (bodyRight.position - head_right_original_positions[i]).normalized()
		head_nodes_right[i].position = head_right_original_positions[i] + dir * contraction
		
	for i in head_nodes_left.size():
		var dir = (bodyLeft.position - head_left_original_positions[i]).normalized()
		head_nodes_left[i].position = head_left_original_positions[i] + dir * contraction

func reset_head():
	#lets set that head back to normal
	for i in head_nodes_right.size():
		head_nodes_right[i].position = head_right_original_positions[i]
		
	for i in head_nodes_left.size():
		head_nodes_left[i].position = head_left_original_positions[i]

func set_player_visible(is_facing_right: bool):
	right_facing_softbody.visible = is_facing_right
	left_facing_softbody.visible = not is_facing_right
