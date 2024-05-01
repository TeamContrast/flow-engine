"""
Used to control the boost bar UI
"""

extends Control

@export var barUnit: PackedScene

var barItems:Array[Control] = []

@export var boostAmount:float = 20

@export var infiniteBoost:bool = false

var growMode = false

var visualBar = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(20):
		barItems.append(barUnit.instantiate())
		barItems[i].position = Vector2(0, -14 * i - 16)
		add_child(barItems[i])


func _process(_delta) -> void:
	if visualBar < boostAmount and visualBar <= 60:
		visualBar += 0.5;
		barItems[floor(fmod(visualBar-2,20))].scale.x = 4
	else:
		visualBar = boostAmount
	
	
	boostAmount = clampf(boostAmount, 0, 60)
	
	if boostAmount < 60 and infiniteBoost:
		boostAmount = 60
	
	var index:int = 0
	for i in barItems:
		index += 1;
		var colorVal = floor(visualBar/20) + (1 if floor(fmod(visualBar,20)) > index else 0)
		i.get_node("TextureRect").position.y = -24 + 8 * colorVal
		i.scale.x = lerpf(i.scale.x, 2.0, 0.2)

func changeBy(x) -> void:
	boostAmount += x
