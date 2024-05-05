extends Area2D
##flips sonic between the two available collision layers
class_name FlowLayerFlipper

##The layer interaction that this LayerFlopper will trigger
@export_enum("Left Layer:0","Right Layer:1", "Toggle:2") var layer:int

func _tripped(entry:Area2D) -> void:
	print("Activated")
	if entry.has_node("playerCollider"):
		print("player detected")
		match layer:
			0:
				entry.LeftLayerOn()
			1:
				entry.RightLayerOn()
			2:
				entry.FlipLayer()
