extends Area2D
## controls a typical (non-flying) ring
class_name FlowGoldRing

## true if the ring has been collected 
var collected:bool = false

## holds a reference to the AnimatedSprite node for the ring
@onready var sprite:AnimatedSprite2D = $"AnimatedSprite2D"

## holds a referene to the AudioStreamPlayer for the ring
@onready var audio:AudioStreamPlayer = $"AudioStreamPlayer"

func _ready() -> void:
	sprite.play("default")

func _on_Ring_area_entered(area:Area2D) -> void:
	# collide with the player, if the ring has not yet been collected
	if not collected and area.name == "Player":
		collected = true
		sprite.stop()
		sprite.connect("animation_finished", hide, CONNECT_ONE_SHOT)
		sprite.play("Sparkle")
		audio.play();
		get_node("/root/Node2D/CanvasLayer/RingCounter").addRing()
		get_node("/root/Node2D/CanvasLayer/boostBar").changeBy(2)
