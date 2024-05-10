extends VBoxContainer

##Used to control the boost bar UI
class_name FlowBoostBar

##The texture for the boost bar units when they're empty
const boost_bar_white:AtlasTexture = preload("res://flow_engine/sprites/UI/white_progress.tres")
## The texture for the boost bar units when they're between empty and yellow
const boost_bar_blue:AtlasTexture = preload("res://flow_engine/sprites/UI/blue_progress.tres")
##The texture for the boost bar units when they're between red and blue
const boost_bar_yellow:AtlasTexture = preload("res://flow_engine/sprites/UI/yellow_progress.tres")
##The texture for the boost bar units when they're full
const boost_bar_red:AtlasTexture = preload("res://flow_engine/sprites/UI/red_progress.tres")

@export var boostAmount:float = 20
##The maximum amount of boost for Sonic
@export var max_boost:float = 60.0
##If true, Sonic the boost bar will always be full (infinite boost)
@export var infiniteBoost:bool = false

#var growMode = false

var visualBar:float = 0

var initial_unit_scale:Vector2

var texture_cached:TextureRect = TextureRect.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	texture_cached.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_cached.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	texture_cached.texture = boost_bar_red
	for i in range(boostAmount):
		add_child(texture_cached.duplicate())
	initial_unit_scale = get_child(0).scale
	updateBoostBar()

func updateBoostBar() -> void:
	if visualBar < boostAmount and visualBar <= 60:
		visualBar += 0.5
		get_child(floorf(fmod(visualBar - 2, get_child_count()))).scale.x = 4
	else:
		visualBar = boostAmount
	
	if infiniteBoost:
		boostAmount = 60
	
	boostAmount = clampf(boostAmount, 0, 60)
	
	var index:int = 0
	for i:TextureRect in get_children():
		
		var colorVal:float = floorf(visualBar / get_child_count()) + (1 if floorf(fmod(visualBar, get_child_count())) > index else 0)
		
		texture_cached.scale = i.scale
		match colorVal:
			3:
				texture_cached.texture = boost_bar_white
			2:
				texture_cached.texture = boost_bar_blue
			1:
				texture_cached.texture = boost_bar_yellow
			0:
				texture_cached.texture = boost_bar_red
		i = texture_cached.duplicate()
		
		#i.get_node("TextureRect").position.y = -24 + 8 * colorVal
		var anim:Tween = create_tween()
		anim.tween_property(get_child(index), "scale", Vector2(2.0, initial_unit_scale.y), 0.2)
		index += 1
		#i.scale.x = lerpf(i.scale.x, 2.0, 0.2)

func changeBy(x:float) -> void:
	boostAmount += x
	updateBoostBar()
