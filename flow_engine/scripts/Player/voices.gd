extends AudioStreamPlayer2D


@export var hurt:Array[AudioStream] 

@export var effort:Array[AudioStream]

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

func play_hurt():
	stream = hurt[floor(hurt.size() * randf())]
	play(0)

func play_effort():
	stream = effort[floor(effort.size() * randf())]
	play(0)
