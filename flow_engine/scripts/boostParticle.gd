extends Node2D

var initialVel:Vector2 = Vector2.ZERO
var cVel:Vector2 = initialVel

@export var boostValue:float = 2.0

var player
var boostBar

@onready var line:Line2D = $"Line2D"
var lineLength = 30

var speed:float = 10.0

var oPos:Vector2
var lPos:Vector2

var timer:float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	initialVel = Vector2(randf() - 0.5, randf() - 0.5)
	initialVel = initialVel.normalized() * speed
	
	player = get_node("/root/Node2D/Player")
	boostBar = get_node("/root/Node2D/CanvasLayer/boostBar")
	
	oPos = position
	lPos = oPos
	
	for i in range(lineLength):
		line.points[i] = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if timer < 1:
		timer += delta
	else:
		timer = 1
		speed += delta * 10

	cVel = initialVel.lerp((player.position - position).normalized() * speed, timer)
	
	position = oPos.lerp(player.position, timer)
	
	oPos += initialVel
	
	for i in range(lineLength - 1, 0, -1):
		line.points[i] = line.points[i - 1] - (position - lPos)
	
	line.points[0] = Vector2.ZERO
	
	if timer >= 1 and position.distance_to(player.position) <= speed:
		FlowStatSingleton.boostChangeBy(player.get_rid(), boostValue)
		#boostBar.changeBy(boostValue)
		queue_free()
	
	lPos = position
