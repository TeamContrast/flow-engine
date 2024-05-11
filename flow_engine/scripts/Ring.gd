extends Area2D
## controls a typical (non-flying) ring
class_name FlowGoldRing

##Whether the ring exists due to Sonic dropping it
@export var dropped:bool = false
##Whether or not the ring can move around, or if it stays stationary
@export var mobile:bool = false

## true if the ring has been collected 
var collected:bool = false

# stores a reference to the raycast node
@onready var downCast:RayCast2D #= $"DownCast"
# holds a reference to the AnimatedSprite node for the ring
@onready var sprite:AnimatedSprite2D = $"AnimatedSprite2D"
# holds a referene to the AudioStreamPlayer for the ring
@onready var audio:AudioStreamPlayer = $"AudioStreamPlayer"

func _ready() -> void:
	sprite.play("default")

func _on_body_entered(body: Node2D) -> void:
	# collide with the player, if the ring has not yet been collected
	if not collected:
		collected = true
		sprite.stop()
		sprite.connect("animation_finished", hide, CONNECT_ONE_SHOT)
		sprite.play("Sparkle")
		audio.play()
		FlowStatSingleton.addRing(body.get_rid(), 1)
		FlowStatSingleton.boostChangeBy(body.get_rid(), 2.0)
