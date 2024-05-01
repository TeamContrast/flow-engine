extends Area2D
##flips sonic between the two available collision layers
class_name FlowLayerFlipper

##The layer interaction that this LayerFlopper will trigger
@export_enum("Left Layer","Right Layer", "Toggle") var layer:int

func _tripped(area:Area2D) -> void:
	if area.name == 'Player':
		match layer:
			0:
				area.LeftLayerOn(area)
			1:
				area.RightLayerOn(area)
			2:
				area.FlipLayer(area)
