@tool

##This Script is used to generate a line of rings in a level. It includes 
##code to render circles where the rings will spawn.
class_name RingGenerator

extends Node2D

## the number of rings to spawn
@export var count: int = 1
## how much to offset each subsequent ring by 
@export var offset: Vector2 = Vector2(30,0)
## the rotation applied to each subsequent displacement
@export var rotationalOffset: float = 0
## the scene containing the ring to spawn in the given locations
@export var ringSource: PackedScene

## stores a list of positions at which to spawn rings
var posList:PackedVector2Array = []

## Generates the positions for all rings and stores them in posList
func placeRings():
	posList.append(Vector2.ZERO)
	for i in range(1,count):
		posList.append((posList[i - 1]) + offset.rotated(rotationalOffset * i))

# place rings once the script is run in play mode
func _ready():
	placeRings()
	if not Engine.is_editor_hint():
		for i:Vector2 in posList:
			var currentRing = ringSource.instantiate()
			currentRing.position = i
			add_child(currentRing)


# place ring circle hints inside the editor
func _process(_delta):
	if Engine.is_editor_hint():
		var pposList:PackedVector2Array = posList
		posList = []
		placeRings()
		if not pposList == posList:
			#update()
			queue_redraw()

# draw the circles for the rings
func _draw():
	if Engine.is_editor_hint():
		for i in posList:
			draw_circle(i,7,Color(0.6, 0.6, 1, 0.5))
