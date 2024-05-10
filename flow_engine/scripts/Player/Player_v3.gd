extends CharacterBody2D

##This is a version of the player more natively integrated into Godot's physics runtimes, 
##with the goal of having better collision detection and more "just works" physics functionality
class_name RushPlayerPS2D

@export_group("Effects & Sounds")
## audio streams for Sonic's boost sound
@export var boost_sfx: AudioStream
## audio streams for Sonic's stomp sound
@export var stomp_sfx: AudioStream
## audio streams for Sonic's stomp landing sound
@export var stomp_land_sfx: AudioStream
## a reference to a bouncing ring prefab, so we can spawn a bunch of them when
## sonic is hurt 
@export var bounceRing: PackedScene
##The floaty wisp things that give Sonic boost
@export var boostParticle: PackedScene

@export_group("Ground")
## sonic's acceleration on his own
@export var ACCELERATION:float = 0.15 / 4
## how much sonic decelerates when skidding.
@export var SKID_ACCEL:float = 1
## maximum speed under sonic's own power
@export var MAX_SPEED:float = 20 / 2
## used to dampen Sonic's movement a little bit. Basically poor man's friction
@export var SPEED_DECAY:float = 0.2 /2
## the speed of sonic's boost. Generally just a tad higher than MAX_SPEED
@export var BOOST_SPEED:float = 25 /2
## The cooldown on activating the boost. Smaller values make it more spammable.
@export var BOOST_COOLDOWN:float = 0.0
##The amount of velocity a single spindash charge (jump + down) will build up
@export var SPINDASH_ACCUMULATE:float = 15.0
##The maximum velocity Sonic can build up from charging a Spindash
@export var SPINDASH_CHARGE_CAP:float = 0.0

@export_group("Air")
## sonic's gravity
@export var GRAVITY:float = 0.3 / 4
## sonic's acceleration in the air.
@export var AIR_ACCEL:float = 0.1 / 4
## what velocity should sonic jump at?
@export var JUMP_VELOCITY:float = 3.5
## what is the Velocity that sonic should slow to when releasing the jump button?
@export var JUMP_SHORT_LIMIT:float = 1.5
##If enabled, Sonic can initiate boosting in midair.
@export var AIR_BOOST:bool = true

@export_group("Stomp")
## how fast (in pixels per 1/120th of a second) should sonic stomp
@export var STOMP_SPEED:float = 20 / 2
## what is the limit to Sonic's horizontal movement when stomping?
@export var MAX_STOMP_XVEL:float = 2 / 2
##How much Sonic will bounce upon landing from a stomp
@export var STOMP_BOUNCE:float = 0.0

@export_group("Camera")
## the speed at which the camera should typically follow sonic
@export var DEFAULT_CAM_LAG:float = 20
## the speed at which the camera should follow sonic when starting a boost
@export var BOOST_CAM_LAG:float = 0
## how fast the Boost lag should slide back to the default lag while boosting
@export var CAM_LAG_SLIDE:float = 0.01 # (float,1)

# references to all the various raycasting nodes used for Sonic's collision with
# the map
#bottom
@onready var LeftCast:RayCast2D = $"LeftCast"
@onready var RightCast:RayCast2D = $"RightCast"
#sides
@onready var LSideCast:RayCast2D = $"LSideCast"
@onready var RSideCast:RayCast2D = $"RSideCast"
#top
@onready var LeftCastTop:RayCast2D = $"LeftCastTop"
@onready var RightCastTop:RayCast2D = $"RightCastTop"

## a reference to Sonic's physics collider
@onready var collider:CollisionShape2D = $"playerCollider"

# sonic's sprites/renderers
### sonic's sprite
@onready var sprite1:AnimatedSprite2D = $"PlayerSprites"
## the sprite that appears over sonic while boosting
@onready var boostSprite:AnimatedSprite2D = $"BoostSprite"
## the line renderer for boosting and stomping
@onready var boostLine:Line2D = $"BoostLine"

## holds a reference to the boost UI bar
@onready var boostBar:Control
## holds a reference to the ring counter UI item
@onready var ringCounter:TextureRect

## the audio stream player with the boost sound
@onready var boostSound:AudioStreamPlayer = $"BoostSound"
## the audio stream player with the rail grinding sound
@onready var RailSound:AudioStreamPlayer = $"RailSound"
## the audio stream player with the character's voices
@onready var voiceSound:AudioStreamPlayer2D = $"Voice"

## a little text label attached to sonic for debugging
@onready var text_label:RichTextLabel = $"Camera2D/RichTextLabel"

## a reference to the scene's camera
@onready var cam:Camera2D = $"Camera2D"
## a reference to the particle node for griding
@onready var grindParticles:GPUParticles2D = $"GrindParticles"

## how long is Sonic's boost/stomp trail?
var TRAIL_LENGTH:int = 40

## a list of particle systems for Sonic to control with his speed 
## used for the confetti in the carnival level, or the falling leaves in leaf storm
var parts:Array[GPUParticles2D] = []

##Sonic's current state
var state:CharStates = CharStates.STATE_AIR

##An enumeration on Sonic's various states.
##For a quick check, if the value is negative, Sonic is in the air in some form.
enum CharStates {
	##Sonic is grinding on a rail
	STATE_GRINDING = 2,
	##Sonic is on the ground
	STATE_GROUND = 1,
	##Sonic is in the air
	STATE_AIR = -1,
	##Sonic jumped or is jumping
	STATE_JUMP = -2,
}

## can the player shorten the jump (aka was this -1 (air) state initiated by a jump?)
#var canShort:bool = false 

@export_flags("Crouching", "Spindashing", "Rolling") var append_state:int

enum StateFlags {
	IS_CROUCHING = 1,
	IS_SPINDASHING = 2,
	IS_ROLLING = 4,
	IS_STOMPING = 8,
	IS_BOOSTING = 16,
	IS_TRICKING = 32,
	
}

# state flags
var crouching:bool = false
var spindashing:bool = false
var rolling:bool = false
var stomping:bool = false
var boosting:bool = false
var tricking:bool = false

var trickingCanStop:bool = false

# flags and values for getting hurt
var hurt:bool = false
var invincible:int = 0

# grinding values.
## the origin position of the currently grinded rail 
var grindPos:Vector2 = Vector2.ZERO
### how far along the rail (in pixels) is sonic?
var grindOffset:float = 0.0
## the curve that sonic is currently grinding on
var grindCurve:Curve2D = null
## the velocity along the grind rail at which sonic is currently moving
var grindVel:float = 0.0
### how high above the rail is the center of Sonic's sprite?
var grindHeight:float = 16

## the minimum speed/pitch changes on the grinding sound
var RAILSOUND_MINPITCH:float = 0.5
## the maximum speed/pitch changes on the grinding sound
var RAILSOUND_MAXPITCH:float = 2.0

##average Ground position between the two foot raycasts
var avgGPoint:Vector2 = Vector2.ZERO 
##average top position between the two head raycasts
var avgTPoint:Vector2 = Vector2.ZERO 
## average ground rotation between the two foot raycasts
var avgGRot:float = 0
## the angle of the left foot raycast
var langle:float = 0
## the angle of the right foot raycast
var rangle:float = 0
## Sonic's rotation during the last frame
var lRot:float = 0
## the position at which sonic starts the level
var startpos:Vector2 = Vector2.ZERO
## the layer on which sonic starts
var startLayer:int = 0

## the ground velocity
var gVel:float = 0
## the ground velocity during the previous frame
var pgVel:float = 0

var lastPos:Vector2 = Vector2.ZERO

## whether or not sonic is currently on the "back" layer
var backLayer:bool = false

var testmult:Vector2 = DisplayServer.window_get_size_with_decorations()

##This is Sonic's default floor angle. In the context of Godot math, this being 
##a higher value will allow Sonic to run up walls/across ceilings. Likewise, 
##it being set lower will instantly "unstick" Sonic from a wall/ceiling, since 
##it won't be considered a floor anymore
var default_floor_max_angle:float

func _ready():
	# get the UI elements
	boostBar = get_node("/root/Node2D/CanvasLayer/boostBar")
	ringCounter = get_node("/root/Node2D/CanvasLayer/RingCounter")
	
	#set the default default floor_max_angle to whatever the user set in GUI
	default_floor_max_angle = floor_max_angle
	
	# put all child particle systems in parts except for the grind particles
	for i in get_children():
		if i is GPUParticles2D and not i == grindParticles:
			parts.append(i)
	
	# set the start position and layer
	startpos = position
	startLayer = collision_layer
	setCollisionLayer(false)
	
	# set the trail length to whatever the boostLine's size is.
	TRAIL_LENGTH = boostLine.get_point_count()
	
	# reset all game values
	resetGame()

##Returns the given angle as an angle (in radians) between -PI and PI
func limitAngle(ang:float) -> float:
	var sign1:float = 1
	if not ang == 0:
		sign1 = ang / absf(ang)
	ang = fmod(ang, PI * 2)
	if absf(ang) > PI:
		ang = (2 * PI - absf(ang)) * sign1 * -1
	return ang

##returns the angle distance between rot1 and rot2, even over the 360deg
##mark (i.e. 350 and 10 will be 20 degrees apart)
func angleDist(rot1:float, rot2:float) -> float:
	rot1 = limitAngle(rot1)
	rot2 = limitAngle(rot2)
	if absf(rot1-rot2) > PI and rot1>rot2:
		return absf(limitAngle(rot1)-(limitAngle(rot2)+PI*2))
	elif abs(rot1-rot2) > PI and rot1 < rot2:
		return absf((limitAngle(rot1) + PI * 2) - (limitAngle(rot2)))
	else:
		return absf(rot1 - rot2)

##gets the distance between point vec1 and point vec2 (probably unnecessary)
func VecDist(vec1:Vector2, vec2:Vector2) -> float:
	return (vec1 - vec2).length()

##Handles the boosting controls
func boostControl():
	if Input.is_action_just_pressed("boost") and boostBar.boostAmount > 0:
		
		# set boosting to true
		boosting = true
		
		# reset the boost line points
		for i in range(0, TRAIL_LENGTH):
			boostLine.points[i] = Vector2.ZERO
		
		# play the boost sfx
		boostSound.stream = boost_sfx
		boostSound.play()
		
		# set the camera smoothing to the initial boost lag
		cam.set_position_smoothing_speed(BOOST_CAM_LAG)
		
		# stop moving vertically as much if you are in the air (air boost)
		if state == CharStates.STATE_AIR and velocity.x < ACCELERATION:
			velocity.x = BOOST_SPEED * (1 if sprite1.flip_h else -1)
			velocity.y = 0
		
		voiceSound.play_effort()
	
	if Input.is_action_pressed("boost") and boosting and boostBar.boostAmount > 0:
#		if boostSound.stream != boost_sfx:
#			boostSound.stream = boost_sfx
#			boostSound.play()
		
		# linearly interpolate the camera's "boost lag" back down to the normal (non-boost) value
		cam.set_position_smoothing_speed(lerpf(cam.get_position_smoothing_speed(), DEFAULT_CAM_LAG, CAM_LAG_SLIDE))
		
		if state == CharStates.STATE_GRINDING:
			# apply boost to a grind
			grindVel = BOOST_SPEED * (1 if sprite1.flip_h else -1)
		elif state == CharStates.STATE_GROUND:
			# apply boost if you are on the ground
			gVel = BOOST_SPEED * (1 if sprite1.flip_h else -1)
		elif (angleDist(velocity.angle(), 0) < PI/3 or angleDist(velocity.angle(), PI) < PI / 3):
			# apply boost if you are in the air (and are not going straight up or down)
			velocity = velocity.normalized() * BOOST_SPEED
		#elif(state == CharStates.STATE_AIR and (not canShort)):
		elif(state == CharStates.STATE_AIR):
			#Do nothing, because that actually mimics what the Rush games did
			pass
		else:
			# if none of these situations fit, you shouldn't be boosting here!
			boosting = false
		
		# set the visibility and rotation of the boost line and sprite
		boostSprite.visible = true
		boostSprite.rotation = velocity.angle() - rotation
		boostLine.visible = true
		boostLine.rotation = -rotation
		
		# decrease boost value while boosting
		boostBar.changeBy(-0.06)
	else:
		# the camera lag should be normal while not boosting
		cam.set_position_smoothing_speed(DEFAULT_CAM_LAG)
		
		# stop the boost sound, if it is playing
		if boostSound.stream == boost_sfx:
			boostSound.stop()
		
		# disable all visual boost indicators
		boostSprite.visible = false
		boostLine.visible = false
		
		# we're not boosting, so set boosting to false
		boosting = false

##handles physics while Sonic is in the air
func airProcess() -> void:
	# apply gravity
	#velocity = Vector2(velocity.x, velocity.y + GRAVITY)
	velocity.y += GRAVITY
	
	
	# set a default avgGPoint
	if get_last_slide_collision() != null:
		avgGPoint = get_last_slide_collision().get_position()
	else:
		avgGPoint = Vector2.ZERO
	
	# handle collision with the ground
	if is_on_floor():
#		print("ground hit")
		state = CharStates.STATE_GROUND
		rotation = get_floor_angle()
		sprite1.rotation = 0
		gVel = sin(rotation) * (velocity.y + 0.5) + cos(rotation) * velocity.x
		
		# play the stomp sound if you were stomping
		if stomping:
			boostSound.stream = stomp_land_sfx
			boostSound.play()
			stomping = false
	
	# air-based movement (using the arrow keys)
	if Input.is_action_pressed("move right") and velocity.x < MAX_SPEED:
		#velocity = Vector2(velocity.x + AIR_ACCEL,velocity.y)
		velocity.x += AIR_ACCEL
	elif Input.is_action_pressed("move left") and velocity.x > -MAX_SPEED:
		#velocity = Vector2(velocity.x - AIR_ACCEL, velocity.y)
		velocity.x -= AIR_ACCEL 
	
	
	### STOMPING CONTROLS ###
	
	# initiating a stomp
	if Input.is_action_just_pressed("stomp") and not stomping:
		# set the stomping state, and animation state 
		stomping = true
		sprite1.play("Roll")
		rotation = 0
		sprite1.rotation = 0
		
		# clear all points in the boostLine rendered line
		for i in range(0, TRAIL_LENGTH):
			boostLine.points[i] = Vector2.ZERO
		
		# play sound 
		boostSound.stream = stomp_sfx
		boostSound.play()
	
	# for every frame while a stomp is occuring...
	if stomping:
		velocity = Vector2(maxf(-MAX_STOMP_XVEL, minf(MAX_STOMP_XVEL, velocity.x)), STOMP_SPEED)
		
		# make sure that the boost sprite is not visible
		boostSprite.visible = false
		
		# manage the boost line 
		boostLine.visible = true
		boostLine.rotation = -rotation
		
		# don't run the boost code when stomping
	else:
		boostControl()
	
	# slowly slide Sonic's rotation back to zero as you fly through the air
	sprite1.rotation = lerpf(sprite1.rotation, 0.0, 0.1)
	
	# handle left and right sideways collision (respectively)
	if is_on_wall():
		boosting = false
	
	#if LSideCast.is_colliding() and VecDist(LSideCast.get_collision_point(),position+velocity) < 14 and velocity.x < 0:
	#	velocity = Vector2(0,velocity.y)
	#	position = LSideCast.get_collision_point() + Vector2(14,0)
	#	boosting = false
	#if RSideCast.is_colliding() and VecDist(RSideCast.get_collision_point(),position+velocity) < 14 and velocity.x > 0:
	#	velocity = Vector2(0,velocity.y)
	#	position = RSideCast.get_collision_point() - Vector2(14,0)
	#	boosting = false
	
	# top collision
	if VecDist(avgTPoint,position + velocity) < 21:
#		Vector2(avgTPoint.x-20*sin(rotation),avgTPoint.y+20*cos(rotation))
		#velocity = Vector2(velocity.x, 0)
		velocity.y = 0
	
	# render the sprites facing the correct direction
	if velocity.x < 0:
		sprite1.flip_h = false
	elif velocity.x > 0:
		sprite1.flip_h = true
	
	# Allow the player to change the duration of the jump by releasing the jump
	# button early
	if not Input.is_action_pressed("jump") and state == CharStates.STATE_JUMP:
		#velocity = Vector2(velocity.x, maxf(velocity.y,-JUMP_SHORT_LIMIT))
		velocity.y = maxf(velocity.y,-JUMP_SHORT_LIMIT)
	
	# ensure the proper speed of the animated sprites
	sprite1.speed_scale = 1

func gndProcess() -> void:
	# caluclate the ground rotation for the left and right raycast colliders,
	# respectively
	
	# calculate the average ground rotation
	avgGRot = get_floor_angle()
	
	# calculate the average ground level based on the available colliders
	
	# set the rotation and position of Sonic to snap to the ground.
	rotation = get_floor_angle()
	
	#apply_ground_snap()
	
	#position = Vector2(avgGPoint.x + 20 * sin(rotation), avgGPoint.y - 20 * cos(rotation))
	
	if not rolling:
		#If this is negative, the player is moving left. If positive, they're going right.
		var input_direction:float = Input.get_axis("move left", "move right")
		
		# handle rightward acceleration
		if input_direction > 0 and gVel < MAX_SPEED:
			#Analog controls :nice:
			gVel += ACCELERATION * input_direction 
			# "skid" mechanic, to more quickly accelerate when reversing 
			# (this makes Sonic feel more responsive)
			if gVel < 0:
				gVel += SKID_ACCEL
		
		# handle leftward acceleration
		elif input_direction < 0 and gVel > -MAX_SPEED:
			#This works as a += because input_direction is negative
			gVel += ACCELERATION * input_direction
			
			# "skid" mechanic (see rightward section)
			if gVel > 0:
				gVel -= SKID_ACCEL
		
		elif input_direction == 0.0:
			# general deceleration and stopping if no key is pressed
			# declines at a constant rate
			if not gVel == 0:
				gVel -= SPEED_DECAY * (gVel / absf(gVel))
			if absf(gVel) < SPEED_DECAY * 1.5:
				gVel = 0
	elif rolling:
		# general deceleration and stopping if no key is pressed
		# declines at a constant rate
		if not gVel == 0:
			gVel -= SPEED_DECAY * (gVel / absf(gVel)) * 0.3
		if absf(gVel) < SPEED_DECAY * 1.5:
			gVel = 0
	
	#wall collision
	if is_on_wall():
		gVel = 0
		boosting = false
	
	# apply gravity if you are on a slope, and apply the ground velocity
	gVel += sin(rotation) * GRAVITY
	
	#velocity = Vector2(cos(rotation) * gVel, sin(rotation) * gVel)
	velocity = Vector2.from_angle(rotation) * gVel
	
	# enter the air state if you run off a ramp, or walk off a cliff, or something
	
	#if not VecDist(avgGPoint, position) < 21 or not (LeftCast.is_colliding() and RightCast.is_colliding()):
	#	state = CharStates.STATE_AIR
	#	sprite1.rotation = rotation
	#	rotation = 0
	#	rolling = false
	
	if not is_on_floor():
		state = CharStates.STATE_AIR
		sprite1.rotation = 0
		rotation = 0
		rolling = false
	
	# fall off of walls if you aren't going fast enough
	
	#if absf(rotation) >= PI/3 and (absf(gVel) < 0.2 or (not gVel == 0 and not pgVel == 0 and not gVel / absf(gVel) == pgVel / absf(pgVel))):
	elif (absf(rotation) >= PI/3 and absf(gVel) < 0.2) or (gVel != 0 and gVel != pgVel):
		state = CharStates.STATE_AIR
		#sprite1.rotation = rotation
		sprite1.rotation = 0
		rotation = 0
		#position = Vector2(position.x - sin(rotation) * 2, position.y + cos(rotation) * 2)
		#since rotation = 0, we can do some math assumptions
		#position = Vector2(position.x, position.y + 2)
		#position += Vector2(0.0, 2.0)
		rolling = false
		
		
	
	# ensure Sonic is facing the right direction
	if gVel < 0:
		sprite1.flip_h = false
	elif gVel > 0:
		sprite1.flip_h = true
	
	#Make sure Sonic is actually on the ground before setting ground anims
	if state == CharStates.STATE_GROUND:
		#If he's rolling, he's just rolling, speed is irrelevant
		if rolling:
			sprite1.play("Roll")
		# set Sonic's sprite based on his ground velocity
		elif absf(gVel) > 12 / 2:
			sprite1.play("Run4")
		elif absf(gVel) > 10 / 2:
			sprite1.play("Run3")
		elif absf(gVel) > 5 / 2:
			sprite1.play("Run2")
		elif absf(gVel) > 0.02:
			sprite1.play("Walk")
		elif not crouching:
			sprite1.play("idle")
	elif state == CharStates.STATE_JUMP:
		sprite1.play("Roll")
	elif state == CharStates.STATE_AIR:
		pass
		#sprite1.play("Free_falling")
	
	if absf(gVel) > 0.02:
		crouching = false
		sprite1.speed_scale = 1
	else:
		gVel = 0
		rolling = false
	
	#crouching
	if Input.is_action_pressed("ui_down") and absf(gVel) <= 0.02:
		crouching = true
		sprite1.play("Crouch")
		sprite1.speed_scale = 1
		if sprite1.frame > 3:
			sprite1.speed_scale = 0
	elif crouching == true:
		sprite1.play("Crouch")
		sprite1.speed_scale = 1
		if sprite1.frame >= 6:
			sprite1.speed_scale = 1
			crouching = false
	
	# run boost controls
	boostControl()
	
	# jumping
	if Input.is_action_pressed("jump") and not (crouching or spindashing):
		if not state == CharStates.STATE_JUMP:
			state = CharStates.STATE_JUMP
			#velocity = Vector2(velocity.x + sin(rotation) * JUMP_VELOCITY, velocity.y - cos(rotation) * JUMP_VELOCITY)
			velocity = velocity + Vector2(sin(rotation), -cos(rotation)) * JUMP_VELOCITY
			sprite1.rotation = rotation
			rotation = 0
			sprite1.play("Roll")
			rolling = false
	
	#spindashing + spindash buildup
	if (Input.is_action_pressed("jump") and crouching) and not rolling:
		spindashing = true
	
	if spindashing and not rolling:
		sprite1.play("Spindash")
		sprite1.speed_scale = 1
		#if a charge is being built up
		if Input.is_action_just_pressed("jump"):
			#accumulate spindash speed
			gVel += SPINDASH_ACCUMULATE * (1 if sprite1.flip_h else -1)
			#cap buildup velocity so Sonic can't fly off
			if SPINDASH_CHARGE_CAP > 0:
				gVel = minf(gVel, SPINDASH_CHARGE_CAP)
		#charge release
		if not Input.is_action_pressed("ui_down"):
			spindashing = false
			rolling = true
	
	# set the previous ground velocity and last rotation for next frame
	pgVel = gVel
	lRot = rotation



func grindProcess() -> void:
	if tricking:
		sprite1.play("railTrick")
		sprite1.speed_scale = 1
		if sprite1.frame > 0:
			trickingCanStop = true
		if sprite1.frame <= 0 and trickingCanStop:
			tricking = false
			var part = boostParticle.instantiate()
			part.position = position 
			part.boostValue = 2
			get_node("/root/Node2D").add_child(part)
	else:
		sprite1.play("Grind")
	
	if Input.is_action_just_pressed("stomp") and not tricking:
		tricking = true
		trickingCanStop = false
		voiceSound.play_effort()
	
	grindHeight = sprite1.sprite_frames.get_frame_texture(sprite1.animation, sprite1.frame).get_height() / 2
	
	grindOffset += grindVel
	var dirVec:Vector2 = grindCurve.sample_baked(grindOffset + 1) - grindCurve.sample_baked(grindOffset)
	#grindVel = velocity.dot(dirVec)
	rotation = dirVec.angle()
	#position = grindCurve.sample_baked(grindOffset) \
	#	+ Vector2.UP * grindHeight*cos(rotation) + Vector2.RIGHT * grindHeight*sin(rotation) \
	#	+ grindPos
	
	
	RailSound.pitch_scale = lerp(RAILSOUND_MINPITCH,RAILSOUND_MAXPITCH,\
		absf(grindVel) / BOOST_SPEED)
	grindVel += sin(rotation) * GRAVITY
	
	if dirVec.length() < 0.5 or \
		grindCurve.sample_baked(grindOffset-1) == \
		grindCurve.sample_baked(grindOffset):
		state = CharStates.STATE_AIR
		tricking = false
		trickingCanStop = false
		RailSound.stop()
	else:
		velocity = dirVec * grindVel
	
	if Input.is_action_pressed("jump") and not crouching:
		if not state == CharStates.STATE_JUMP:
			state = CharStates.STATE_JUMP
			#velocity = Vector2(velocity.x + sin(rotation) * JUMP_VELOCITY, velocity.y - cos(rotation) * JUMP_VELOCITY)
			velocity = velocity + Vector2(sin(rotation), -cos(rotation)) * JUMP_VELOCITY
			sprite1.rotation = rotation
			rotation = 0
			sprite1.play("Roll")
			rolling = false
			tricking = false
			trickingCanStop = false
			RailSound.stop()
	boostControl()


func _process(_delta:float) -> void:
	if invincible > 0:
		sprite1.modulate = Color(1,1,1,1-(invincible % 30)/30.0)
	else:
		hurt = false

##calculate Sonic's physics, controls, and all that fun stuff
func _physics_process(_delta:float) -> void:
	if invincible > 0:
		invincible -= 1
	# reset using the dedicated reset button
	if Input.is_action_pressed('restart'):
		resetGame()
		if get_tree().reload_current_scene() != OK:
			push_error("Could not reload current scene!")
	
	grindParticles.emitting = (state == CharStates.STATE_GRINDING)
	
	
	
	# run the correct function based on the current air/ground state
	match state:
		CharStates.STATE_GRINDING:
			grindProcess()
		CharStates.STATE_GROUND:
			gndProcess()
		CharStates.STATE_AIR:
			airProcess()
			#rolling = false
		CharStates.STATE_JUMP:
			airProcess()
	
	# update the boost line 
	for i in range(0, TRAIL_LENGTH - 1):
		boostLine.points[i] = (boostLine.points[i + 1] - velocity + (lastPos - position))
	boostLine.points[TRAIL_LENGTH - 1] = Vector2.ZERO
	if stomping:
		boostLine.points[TRAIL_LENGTH - 1] = Vector2(0.0, 8.0)
	
	# apply the character's velocity, no matter what state the player is in.
	
	#To be honest, I'm not 100% sure why this works, but it does, lol
	#var collision:KinematicCollision2D = move_and_collide(velocity.normalized())
	#if is_instance_valid(collision):
	#	velocity = velocity.normalized().slide(velocity.normalized())
	velocity = velocity / _delta
	
	move_and_slide()
	
	lastPos = position
	
	if parts:
		for i:GPUParticles2D in parts:
			i.process_material.direction = Vector3(velocity.x,velocity.y,0)
			#i.process_material.initial_velocity = velocity.length()*20
			
			i.rotation = -rotation

##shortcut to change the collision mask for every raycast node connected to
## sonic at the same time. Value is true for loop_right, false for loop_left
func setCollisionLayer(value:bool) -> void:
	backLayer = value
	
	set_collision_mask_value(2, not backLayer)
	set_collision_mask_value(3, backLayer)
	#for rays:RayCast2D in [LeftCast, RightCast, RSideCast, LSideCast, LeftCastTop, RightCastTop]:
	#	rays.set_collision_mask_value(2, not backLayer)
	#	rays.set_collision_mask_value(3, backLayer)

func FlipLayer() -> void:
	# toggle between layers
	setCollisionLayer(not backLayer)

## enables interaction with the "left loop" collision layer for Sonic
func LeftLayerOn() -> void:
	# explicitly set the collision layer to 0
	setCollisionLayer(false)

func RightLayerOn() -> void:
	# explicitly set the collision layer to 1
	setCollisionLayer(true)

func _on_DeathPlane_area_entered(area:Node) -> void:
	if self == area:
		resetGame()
		if get_tree().reload_current_scene() != OK: 
			push_error("Could not reload current scene!")

## reset your position and state if you pull a dimps (fall out of the world)
func resetGame() -> void:
	velocity = Vector2.ZERO
	state = CharStates.STATE_AIR
	position = startpos
	setCollisionLayer(false)

func _setVelocity(vel:Vector2) -> void:
	velocity = vel

##this function is run whenever sonic hits a rail.
func _on_Railgrind(area, curve:Curve2D, origin) -> void:
	# stick to the current rail if you're already grindin
	if state == CharStates.STATE_GRINDING:
		return
	
	# activate grind, if you are going downward
	if self == area and velocity.y > 0:
		state = CharStates.STATE_GRINDING
		grindCurve = curve
		grindPos = origin
		grindOffset = grindCurve.get_closest_offset(position-grindPos)
		grindVel = velocity.x
		
		RailSound.play()
		
		# play the sound if you were stomping
		if stomping:
			boostSound.stream = stomp_land_sfx
			boostSound.play()
			stomping = false

func isAttacking() -> bool:
	if stomping or boosting or rolling or spindashing or \
		(state == CharStates.STATE_JUMP):
		return true
	return false

func hurt_player() -> void:
	if not invincible > 0:
		invincible = 120 * 5
		state = CharStates.STATE_AIR
		velocity = Vector2(-velocity.x + sin(rotation) * JUMP_VELOCITY, velocity.y - cos(rotation) * JUMP_VELOCITY)
		rotation = 0
		position += velocity * 2
		sprite1.play("hurt")
		
		voiceSound.play_hurt()
		
		var t:int = 0
		var angle:float = 101.25
		var n:bool = false
		var speed:int = 4
		
		while t < mini(ringCounter.ringCount, 32):
			var currentRing = bounceRing.instantiate()
			currentRing.velocity = Vector2(-sin(angle) * speed, cos(angle) * speed) / 2
			currentRing.position = position
			if n:
				currentRing.velocity.x *= -1
				angle += 22.5
			n = not n 
			t += 1
			if t == 16:
				speed = 2
				angle = 101.25
			get_node("/root/Node2D").call_deferred("add_child", currentRing)
		ringCounter.ringCount = 0
