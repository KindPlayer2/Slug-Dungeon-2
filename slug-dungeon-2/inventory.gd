extends Control

# Reference to the InventoryUI node
@onready var inventory_ui = self

# Variable to track if the inventory is open
var is_inventory_open = false

func _ready():
	# Hide the inventory UI initially
	inventory_ui.visible = false

	# Set the process mode to always process (even when the scene tree is paused)
	process_mode = PROCESS_MODE_ALWAYS

func _process(delta):
	# Check if the "E" key is pressed
	if Input.is_action_just_pressed("Inventory"):
		# Toggle the inventory visibility
		is_inventory_open = !is_inventory_open
		inventory_ui.visible = is_inventory_open

		# Pause or unpause the game
		get_tree().paused = is_inventory_open
