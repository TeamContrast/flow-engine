extends Area2D

##controls a spring, as well as boost rings
class_name FlowCharacterLauncher

@export_group("Physics")
## how strong is the spring?
@export var STRENGTH: float = 7
##If enabled, spring will override Sonic's momentum
@export var OVERRIDE_MOMENTUM:bool = true
## does the spring force the player to go in the direction it is facing?
@export var DIRECTED:bool = false
## add a scaling effect (usually for boost rings)
@export_group("Animation")
@export var ringScale: bool = false
##How much the spring will expand when animating an activation
@export var scaling:float = 2.0

## stores the animated sprite
@onready var animation:AnimatedSprite2D = $"AnimatedSprite2D"
## stores the audio stream player
@onready var sound:AudioStreamPlayer = $"AudioStreamPlayer"

## The animation Tween 
var anim:Tween

func animate() -> void:
	anim = self.create_tween()
	var scale_to:Vector2 = Vector2(scaling, scaling)
	anim.tween_property(self, "scale", scale_to, 0.1)
	anim.play()
	await anim.finished
	anim.stop()
	anim.tween_property(self, "scale", Vector2.ONE, 0.1)
	anim.play()

func _on_Area2D_area_entered(area:Area2D) -> void:
	# if the player collides with the spring
	if area.name == "Player":
		# calculate what vector to launch Sonic in
		var launchVector:Vector2 = Vector2(0, -STRENGTH).rotated(rotation)
		
		# calculate how fast sonic is moving perpendicularly to the spring
		var sideVector:Vector2 = area.velocity1.dot(launchVector.normalized().rotated(PI / 2))\
				*launchVector.normalized().rotated(PI / 2)
		
		# calculate the final vector to throw sonic in. Ignore sideVector if 
		# the spring is directed
		var finalVector:Vector2 = (Vector2.ZERO if DIRECTED else sideVector) + launchVector
		
		# print out the values for debugging
		print("sideVector: ",sideVector)
		print("launchVector: ",launchVector)
		print("finalVector: ",finalVector)
		
		if OVERRIDE_MOMENTUM:
			# set sonic's velocity to the final vector
			area.velocity1 = finalVector
		else:
			#add velocity to Sonic's current velocity
			area.velocity1 += finalVector
		
		# set sonic to the air state
		area.state = -1
		# Sonic didn't jump here...
		area.canShort = false
		# set Sonic's position to the spring's position
		area.position = position
		# if sonic stomped on to the spring, he is no longer stomping
		area.stomping = false
		
		# set sonic's sprite rotation to Sonic's rotation
		area.find_child("PlayerSprites").rotation = area.rotation
		# reset sonic's rotation (this is typically how sonic works in the air)
		area.rotation = 0
		
		# set the spring's current animation frame to 0
		animation.frame = 0
		# play the spring sound
		sound.play()
		
		#scale the spring, if scaling is active
		if ringScale:
			animate()
