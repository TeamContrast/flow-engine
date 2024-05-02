"""
Used to control the boost bar UI
"""

extends Control

@export var barUnit: PackedScene

var barItems:Array[Control] = []

@export var boostAmount:float = 20

@export var infiniteBoost:bool = false

#var growMode = false

var visualBar:float = 0

var initial_unit_scale:Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(20):
		barItems.append(barUnit.instantiate())
		barItems[i].position = Vector2(0, -14 * i - 16)
		add_child(barItems[i])
	initial_unit_scale = barItems[0].scale
	updateBoostBar()

func updateBoostBar() -> void:
	if visualBar < boostAmount and visualBar <= 60:
		visualBar += 0.5;
		barItems[floor(fmod(visualBar-2,20))].scale.x = 4
	else:
		visualBar = boostAmount
	
	if infiniteBoost:
		boostAmount = 60
	
	boostAmount = clampf(boostAmount, 0, 60)
	
	var index:int = 0
	for i in barItems:
		index += 1;
		var colorVal:float = floor(visualBar/20) + (1 if floor(fmod(visualBar,20)) > index else 0)
		i.get_node("TextureRect").position.y = -24 + 8 * colorVal
		var anim:Tween = create_tween()
		anim.tween_property(i, "scale", Vector2(2.0, initial_unit_scale.y), 0.2)
		#i.scale.x = lerpf(i.scale.x, 2.0, 0.2)

func changeBy(x:float) -> void:
	boostAmount += x
	updateBoostBar()
