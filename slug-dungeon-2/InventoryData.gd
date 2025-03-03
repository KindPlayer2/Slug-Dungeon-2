extends Resource
class_name InventoryData

# Array to store items in the inventory
var items: Array = []

# Initialize the inventory with 39 empty slots
func _init():
	items.resize(39)
	items.fill(null)  # Fill with null to represent empty slots

# Add an item to the first available slot
func add_item(item: Resource) -> bool:
	for i in range(items.size()):
		if items[i] == null:
			items[i] = item
			return true  # Item added successfully
	return false  # Inventory is full

# Remove an item from a specific slot
func remove_item(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < items.size():
		items[slot_index] = null

# Get the item in a specific slot
func get_item(slot_index: int) -> Resource:
	if slot_index >= 0 and slot_index < items.size():
		return items[slot_index]
	return null
