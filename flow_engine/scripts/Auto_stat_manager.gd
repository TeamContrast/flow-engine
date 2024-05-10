extends Node

##This is a singleton for managing player rings, boost, etc. It's designed with
##the possibility of multiple players in mind, as to not hamper the possibility of 
##multiplayer support


##A struct of sorts to keep track of player stats
class FlowCharacterSheet:
	extends Resource
	##A reference to the player themselves, used for checks
	var area:Area2D = null
	##The player's ring count
	var rings:int = 0
	##The player's boost bar
	var boostAmount:float

##A signal emitted when rings are updated. Binds the Area2D of the player for checks.
signal rings_updated
##A signal emitted when boost is updated. Binds the Area2D of the player for checks.
signal boost_updated

##Reference to the last player. This is to speed up single player instances
var last_char:FlowCharacterSheet
##An array of all players
var all_chars:Array[FlowCharacterSheet]

func add_player(area:Area2D) -> void:
	var new_char:FlowCharacterSheet = find_char(area)
	if new_char.area == null:
		new_char.area = area
		all_chars.append(new_char)
		last_char = new_char
		print("Character added!")

func find_char(area:Area2D) -> FlowCharacterSheet:
	for players in all_chars:
		if players.area == area:
			return players
	return FlowCharacterSheet.new()

##Get the boost amount of a player
func getBoostAmount(area:Area2D) -> float:
	if last_char.area != area:
		last_char = find_char(area)
	return last_char.boostAmount

##This adds amount of boost to area player
func boostChangeBy(area:Area2D, amount:float) -> void:
	if last_char.area != area:
		last_char = find_char(area)
	last_char.boostAmount += amount
	emit_signal("boost_updated", area)

##Get the ring count ofa player
func getRingCount(area:Area2D) -> int:
	if last_char.area != area:
		last_char = find_char(area)
	return last_char.rings

##This adds amount rings to area player
func addRing(area:Area2D, amount:int) -> void:
	if last_char.area != area:
		last_char = find_char(area)
	last_char.rings += amount
	emit_signal("rings_updated", area)
