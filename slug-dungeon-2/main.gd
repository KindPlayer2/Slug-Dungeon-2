extends Node2D

var playerScene = preload("res://player.tscn")
var leafManScene = preload("res://leafMan.tscn")
var BeetleScene = preload("res://Beetle.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inst(Vector2(0,200))
	var instance = leafManScene.instantiate() # Replace with function body.
	instance.position = Vector2(-500,10)
	add_child(instance)
	
	var instance2 = BeetleScene.instantiate() # Replace with function body.
	instance2.position = Vector2(400,10)
	add_child(instance2)

func inst(pos: Vector2):
	var instance = playerScene.instantiate() # Replace with function body.
	instance.position = pos
	add_child(instance)
