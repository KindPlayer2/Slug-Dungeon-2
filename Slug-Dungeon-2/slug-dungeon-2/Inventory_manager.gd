extends Resource

class_name Inv

signal update

@export var slots: Array[InvSlot]

# Function to insert an item into the inventory
func insert(item: InvItem):
	var itemslots = slots.filter(func(slot): return slot.item == item)
	if !itemslots.is_empty():
		itemslots[0].amount += 1
	else:
		var emptyslots = slots.filter(func(slot): return slot.item == null)
		if !emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount = 1
	update.emit()

# Function to check if the inventory has a specific item
func has_item(item_name: String) -> bool:
	for slot in slots:
		if slot.item != null and slot.item.name == item_name:
			return true
	return false

# Function to remove one instance of a specific item from the inventory
func remove(item_name: String):
	for slot in slots:
		if slot.item != null and slot.item.name == item_name:
			slot.amount -= 1
			if slot.amount <= 0:
				slot.item = null
				slot.amount = 0
			update.emit()
			break
