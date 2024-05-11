extends Area2D

##this is the controller script for the basic egg pawn enemy. It is currently 
##pretty basic, but I'll probably update it a bit more later
class_name FlowEggPawn

@export var boostParticle: PackedScene

## is the egg pawn alive?
var alive:bool = true

## keeps track of the pawn's velocity once it has "exploded"
var splodeVel:Vector2 = Vector2.ZERO

## keeps a reference to the audio stream player for the explosion sound
@onready var boomSound:AudioStreamPlayer2D = $"BoomSound"

func _physics_process(_delta: float) -> void:
	if alive:
		# a stupid simple AI routine. Simply move x by -0.1 pixels per frame
		position.x -= 0.1;
	else:
		# calculations for the explosion animation. 
		# Applies velocity, rotates, and then applies gravity
		position += splodeVel
		rotation += 0.1
		splodeVel.y += 0.2

#func _on_EggPawn_area_entered(area:Area2D):
func _on_body_entered(body: Node2D) -> void:
	# if the player collides with this egg pawn
	if alive:
		# if the player isn't attacking (boosting or jumping) hurt the player
		if not body.isAttacking():
			body.hurt_player()
		elif body.state == -1:
			# if it is attacking from the air, bounce it back up a bit 
			body.velocity1.y = -5
		if body.isAttacking():
#			get_node("/root/Node2D/CanvasLayer/boostBar").changeBy(2)
			var newNode:Node2D = boostParticle.instantiate()
			newNode.position = position
			newNode.boostValue = 2
			get_node("/root/Node2D").add_child(newNode)
		
		# this robot is dead...
		alive = false
		
		# set the velocity to match Sonic's speed, with a few constraints
		splodeVel = body.get("velocity1") * 1.5
		splodeVel.y = min(splodeVel.y, 10)
		splodeVel.y -= 7
		
		# play the explosion sfx
		boomSound.play()
