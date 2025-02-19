extends Node2D

var playerScene = preload("res://player.tscn")
var leafManScene = preload("res://leafMan.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inst(Vector2(0,200))
	var instance = leafManScene.instantiate() # Replace with function body.
	instance.position = Vector2(-200,10)
	add_child(instance)
	var instance2 = leafManScene.instantiate() # Replace with function body.
	instance2.position = Vector2(-400,10)
	add_child(instance2)
	var instance3 = leafManScene.instantiate() # Replace with function body.
	instance3.position = Vector2(-600,10)
	add_child(instance3)
	
func inst(pos: Vector2):
	var instance = playerScene.instantiate() # Replace with function body.
	instance.position = pos
	add_child(instance)
