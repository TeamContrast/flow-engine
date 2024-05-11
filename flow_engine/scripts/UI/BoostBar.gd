## Used to control the boost bar UI
extends Control
class_name FlowBoostBar

var barUnit = preload("res://flow_engine/UI/boost_bar_segment.tscn")

var barItems = []

@export var boostAmount: float = 20

@export var infiniteBoost: bool = false

var linked_player_id: RID 

var growMode = false

var visualBar = 0

var maxBoost = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	FlowStatSingleton.connect("boost_updated", updateBoostBar)
	for i in range(20):
		barItems.append(barUnit.instantiate())
		barItems[i].position = Vector2(0,-14*i-16)
		add_child(barItems[i])

func _process(_delta):
	if visualBar < boostAmount and visualBar <= 60:
		visualBar += 0.5
		barItems[floor(fmod(visualBar-1.0,20))].scale.x = 4
	else:
		visualBar = boostAmount
	
	boostAmount = clampf(boostAmount,0,60)
	
	if boostAmount < 60 and infiniteBoost:
		boostAmount = 60
	
	var index = 0
	for i in barItems:
		index += 1
		var colorVal = floor(visualBar/20)+(1 if fmod(visualBar,20) > index*1.0 else 0)
		var mat: ShaderMaterial = i.material
		mat.set_shader_parameter("uv_offset",Vector2(0,3-colorVal))
		i.scale.x = lerp(i.scale.x,2.0,0.2)

func updateBoostBar(id:RID) -> void:
	if id != linked_player_id:
		return
	
	maxBoost = FlowStatSingleton.getBoostMax(id)
	
	boostAmount = FlowStatSingleton.getBoostAmount(id)
	
	boostAmount = (boostAmount*1.0/maxBoost)*60.0
