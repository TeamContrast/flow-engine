extends AudioStreamPlayer2D


@export var hurt:Array[AudioStream] # (Array, AudioStream)

@export var effort:Array[AudioStream] # (Array, AudioStream)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func play_hurt():
	stream = hurt[floor(hurt.size()*randf())]
	play(0)

func play_effort():
	stream = effort[floor(effort.size()*randf())]
	play(0)
