extends Control

@onready var inv: Inv = preload("res://Inventory/playerinv.tres")
@onready var slots: Array = $NinePatchRect.get_children()


# Reference to the InventoryUI node
@onready var inventory_ui = self

# Variable to track if the inventory is open
var is_inventory_open = false

func update_Slots():
	for i in range(min(inv.slots.size(), slots.size())):
		slots[i].update(inv.slots[i])

func _ready():
	# Hide the inventory UI initially
	inv.update.connect(update_Slots)
	inventory_ui.visible = false
	
	update_Slots()

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
