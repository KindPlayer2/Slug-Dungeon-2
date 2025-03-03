extends RigidBody2D
@export var item: InvItem
var player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_2d_area_entered(body):
	if body.is_in_group("Player"):
		player = body
		player.get_parent().collect(item)
		await get_tree().create_timer(0.1).timeout
		self.queue_free()
