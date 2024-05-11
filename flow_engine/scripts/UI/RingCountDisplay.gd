extends Control

##controls the current ring count indicator
class_name FlowRingCounter

## stores references to each display digit
@onready var digits:Array[TextureRect] 

## reference to the hundreds digit
@onready var hun_digit:TextureRect = $"Numbers/Digit 3/TextureRect2"

##reference to the tens digit
@onready var tens_digit:TextureRect = $"Numbers/Digit 2/TextureRect2"

##reference to the ones digit
@onready var ones_digit:TextureRect = $"Numbers/Digit 1/TextureRect2"

var linked_player_id:RID 

func _ready():
	# locate all the digits from smallest place to largest
	for i in range(3,0,-1):
		digits.append(get_node("Numbers/Digit %d/TextureRect2" % i))
	#Register to the stat singleton
	FlowStatSingleton.connect("rings_updated", updateCounter)

func updateCounter(id:RID) -> void:
	#Don't update if it's not our player
	if id != linked_player_id:
		return
	#Get the ring count from the singleton
	var ringCount:int = FlowStatSingleton.getRingCount(id)
	# place stores the place multiplier for the value 
	var place:int = 1
	for i:TextureRect in digits:
		# get the current value (0-9) of the current digit
		var value:int = (ringCount / place) % 10
		
		# update the place multiplier
		place *= 10
		
		# change the display to reflect the given value
		i.position.x = -24 * value

##add a single ring to the ring count
#func addRing():
#	ringCount += 1
#	updateCounter()
