extends Sprite2D

func _ready() -> void:
	GraphicsSingleton.connect("lighting_changed", toggle_lighting)

func toggle_lighting() -> void:
	$PointLight2D.enabled = GraphicsSingleton.real_time_lighting
	
