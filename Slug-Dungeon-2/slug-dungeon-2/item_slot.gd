extends Button

#Variable for the item in inventory and its image in description pop up
@onready var item_visual: Sprite2D = $Item_display
@onready var item_visual_desc: Sprite2D = $Description/ImageHolder/Item_display

#Variable for amount of an item and its amouynt in description pop up
@onready var amount_text: Label = $Amount
@onready var amount_text_desc: Label = $Description/AmountHolder/Amount

#description pop up and its items name and description text
@onready var desc: NinePatchRect = $Description
@onready var item_name: Label = $"Description/Description Holder/Name"
@onready var item_desc: Label = $"Description/Description Holder/Description"


var slotFilled = false

func update(slot: InvSlot):
	if !slot.item:
		item_visual.visible = false
		amount_text.visible = false
		slotFilled = false
	else:
		#allow pop up
		slotFilled = true
		
		#set items textures
		item_visual.visible = true
		item_visual.texture = slot.item.texture
		item_visual_desc.texture = slot.item.texture
		
		#set text for the description and name labels
		item_name.text = slot.item.name
		item_desc.text = slot.item.description
		
		#set the description amount and the item slot amount, only if it is above one for the slot
		amount_text_desc.text = str(slot.amount)
		if slot.amount > 1:
			amount_text.visible = true
			amount_text.text = str(slot.amount)

func _on_mouse_entered() -> void:
	if slotFilled:
		desc.visible = true

func _on_mouse_exited() -> void:
	if slotFilled:
		desc.visible = false
