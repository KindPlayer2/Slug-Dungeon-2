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

# Track whether the player is in the air
var is_in_air := false

@export var inv: Inv

@export var isAttacking:bool = false

# Sounds
@export var jump_sound: AudioStreamPlayer2D
@export var charge_sound: AudioStreamPlayer2D
@export var walk_sound: AudioStreamPlayer2D
@export var splat_sound: AudioStreamPlayer2D
@export var dead_sound: AudioStreamPlayer2D
@export var hurt_sound: AudioStreamPlayer2D

@export var AttackArea:Area2D

# Reference to the head RigidBody2D nodes
@export var head_nodes_right: Array[RigidBody2D]
var head_right_original_positions: Array[Vector2]

# Left head nodes
@export var head_nodes_left: Array[RigidBody2D]
var head_left_original_positions: Array[Vector2]

# Reference to the body RigidBody2D
@export var bodyRight: RigidBody2D
@export var bodyLeft: RigidBody2D

# The softbodies for determining the direction of the sprite
@export var right_facing_softbody: Polygon2D
@export var left_facing_softbody: Polygon2D

# Pins used for movement, change positions when on wall for natural movement
# Right pins
@export var PinRightOne: PinJoint2D
@export var PinRightTwo: PinJoint2D

# Left pins
@export var PinLeftOne: PinJoint2D
@export var PinLeftTwo: PinJoint2D

@export var death_particle: GPUParticles2D
@export var splat_particle: GPUParticles2D

@export var attackTimer: Timer

@onready var health_bar: ProgressBar = $HealthBar

@export var camera:Camera2D

# Track whether the player was on the wall in the previous frame
var was_on_wall := false

# Store the last wall tangent for smooth momentum transition
var _last_wall_tangent: Vector2

# Track whether the player is alive
var is_alive := true

func _input(event: InputEvent) -> void:
	if not is_alive:
		return  # Ignore input if the player is dead

	if event.is_action_pressed("Rotate") and health > 0:
		dead_sound.play()
		
	if event.is_action_pressed("Attack"):
		attack()
		
var initial_body_right_position: Vector2
var initial_body_right_velocity: Vector2
var initial_body_left_position: Vector2
var initial_body_left_velocity: Vector2
var initial_pin_right_one_node_b: NodePath
var initial_pin_right_two_node_b: NodePath
var initial_pin_left_one_node_b: NodePath
var initial_pin_left_two_node_b: NodePath

var health = 6

func _ready():
	health_bar.init_health(health)
	set_player_visible(true)
	
	# Connect the attackTimer's timeout signal to a function
	attackTimer.connect("timeout", Callable(self, "_on_attackTimer_timeout"))

	# Assign the heads' original positions
	head_right_original_positions = []
	head_left_original_positions = []

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

	# Connect the area_entered signal using Callable
	connect("area_entered", Callable(self, "_on_area_entered"))

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
	
func died():
	if not is_alive:
		return  # Exit if the player is already dead

	is_alive = false  # Mark the player as dead
	walk_sound.stop()
	dead_sound.play()  # Play the death sound
	death_particle.emitting = true
	velocity = Vector2.ZERO  # Stop all movement
	move_and_slide()

	# Set the break distance of both softbodies to 1
	right_facing_softbody.break_distance_ratio = 0.8
	left_facing_softbody.break_distance_ratio = 0.8

	# Start the gradual head expansion
	gradually_expand_head()

func gradually_expand_head():
	# Create a new Tween node
	var tween = create_tween()
	tween.set_parallel(true)  # Animate all head nodes in parallel

	# How strong should head expansion be? 4~ change for intensity of expansion
	var expansion = 20.0

	# Duration of the expansion animation (in seconds)
	var duration = 4 # Adjust this value to control the speed of the expansion

	# Animate the right head nodes
	for i in head_nodes_right.size():
		var dir = (head_right_original_positions[i] - bodyRight.position).normalized()
		var target_position = head_right_original_positions[i] + dir * expansion
		tween.tween_property(head_nodes_right[i], "position", target_position, duration)

	# Animate the left head nodes
	for i in head_nodes_left.size():
		var dir = (head_left_original_positions[i] - bodyLeft.position).normalized()
		var target_position = head_left_original_positions[i] + dir * expansion
		tween.tween_property(head_nodes_left[i], "position", target_position, duration)
		
func attack():
	var tween = create_tween()
	tween.set_parallel(true)  # Animate all head nodes in parallel
	
	# How strong should head expansion be? 4~ change for intensity of expansion
	var expansion = 15.0
	# Duration of the expansion animation (in seconds)
	var duration = 0.05 # Adjust this value to control the speed of the expansion
	
	AttackArea.monitoring = true
	AttackArea.monitorable = true
	AttackArea.scale = Vector2(1,1)
	
	attackTimer.start()
	isAttacking = true

	# Animate the right head nodes
	for i in head_nodes_right.size():
		var dir = (head_right_original_positions[i] - bodyRight.position).normalized()
		dir = Vector2(dir.x, 0).normalized()  # Only consider the X component

		# Anticipation: Move in the opposite direction
		var anticipation_position = head_right_original_positions[i] - dir * (expansion / 3.0)
		tween.tween_property(head_nodes_right[i], "position", anticipation_position, duration)

		# Main motion: Move to the target position
		var target_position = head_right_original_positions[i] + dir * expansion
		tween.tween_property(head_nodes_right[i], "position", target_position, duration).set_delay(duration)

		# Animate the left head nodes
	for i in head_nodes_left.size():
		var dir = (head_left_original_positions[i] - bodyLeft.position).normalized()
		dir = Vector2(dir.x, 0).normalized()  # Only consider the X component

		# Anticipation: Move in the opposite direction
		var anticipation_position = head_left_original_positions[i] - dir * (expansion / 3.0)
		tween.tween_property(head_nodes_left[i], "position", anticipation_position, duration)

		# Main motion: Move to the target position
		var target_position = head_left_original_positions[i] + dir * expansion
		tween.tween_property(head_nodes_left[i], "position", target_position, duration).set_delay(duration)
	
func _on_attackTimer_timeout():
	# Code to run after the timer finishes
	AttackArea.monitorable = false
	AttackArea.monitoring = false
	isAttacking = false
	AttackArea.scale = Vector2(0.1,0.1)


func _physics_process(delta: float) -> void:
		
	if health <= 0 and is_alive:
		died()  # Call died() only once when health drops to 0
		return
		
	if health == 6 and is_alive:
		health_bar.visible = false
	elif health <= 5 and is_alive:
		health_bar.visible = true

	# Exit early if the player is dead
	if not is_alive:
		move_and_slide()  # Ensure the player stays in place
		return

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
		# Only when a jump is not being charged
		if not is_charging_jump:
			charge_sound.play()
			# Jump is set to be charging
			is_charging_jump = true

			# Retract the head bones for left and right
			head_right_original_positions = []
			head_left_original_positions = []

			# Retract bones one by one in for loops
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
		charge_sound.stop()
		jump_sound.play()
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
			var rotation_angle = -PI / 2 if is_facing_right else PI / 2
			var tangent = wall_normal.rotated(rotation_angle)

			# Store last wall movement direction
			_last_wall_tangent = tangent

			velocity += tangent * WallDirection * SPEED * delta
			velocity = velocity.limit_length(SPEED) * 1.2
		else:
			if direction:
				velocity.x = direction * SPEED
				set_player_visible(direction > 0)
			else:
				walk_sound.playing = true
				velocity.x = move_toward(velocity.x, 0, SPEED)

	# Check if the player has just landed on the ground
	if is_on_floor():
		if is_in_air:
			# Player was in the air and just landed
			splat_sound.play()
			splat_particle.emitting = true
			is_in_air = false
	else:
		# Player is in the air
		is_in_air = true

	move_and_slide()

func contract_head(charge_ratio: float):
	# How strong should head contraction be? 4~ change for intensity of contraction
	var contraction = charge_ratio * 4.0

	# Move the head bones
	for i in head_nodes_right.size():
		var dir = (bodyRight.position - head_right_original_positions[i]).normalized()
		head_nodes_right[i].position = head_right_original_positions[i] + dir * contraction

	for i in head_nodes_left.size():
		var dir = (bodyLeft.position - head_left_original_positions[i]).normalized()
		head_nodes_left[i].position = head_left_original_positions[i] + dir * contraction

func reset_head():
	# Let's set that head back to normal
	for i in head_nodes_right.size():
		head_nodes_right[i].position = head_right_original_positions[i]

	for i in head_nodes_left.size():
		head_nodes_left[i].position = head_left_original_positions[i]

func set_player_visible(is_facing_right: bool):
	right_facing_softbody.visible = is_facing_right
	left_facing_softbody.visible = not is_facing_right

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and !area.get_parent().isDead:
		# Determine the knockback direction based on the player's facing direction
		var knockback_direction: Vector2
		if right_facing_softbody.visible:
			knockback_direction = Vector2.LEFT  # Player is facing right, so knockback is to the left
		else:
			knockback_direction = Vector2.RIGHT  # Player is facing left, so knockback is to the right

		# Apply knockback force
		var knockback_force = 500.0  # Adjust this value to control the strength of the knockback
		velocity = knockback_direction * knockback_force

		# Reduce health
		health -= 1
		if health != 0:
			hurt_sound.play()
		health_bar.health = health
	elif area.is_in_group("health_item") && health < 6:
		health += 1
		health_bar.health = health
	if area.is_in_group("Death"):
		died()
		
func collect(item):
	inv.insert(item)
