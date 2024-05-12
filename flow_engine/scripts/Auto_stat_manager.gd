extends Node

##This is a singleton for managing player rings, boost, etc. It's designed with
##the possibility of multiple players in mind, as to not hamper the possibility of 
##multiplayer support

##This is a singleton specifically so that anything in the scene can easily query the stats
##of the player by their RID, so that specific situational handling can be implemented

##A struct of sorts to keep track of player stats
class FlowCharacterSheet:
	extends Resource
	##The player's RID, used for checks
	var character_id:RID
	##The player's ring count
	var rings:int = 0
	##The player's boost bar
	var boostAmount:float
	##The max amount of boost the player can have
	var maxBoost:float

##A signal emitted when rings are updated. Binds the Area2D of the player for checks.
signal rings_updated
##A signal emitted when boost is updated. Binds the Area2D of the player for checks.
signal boost_updated

##Reference to the last player. This is to speed up single player instances
var last_char:FlowCharacterSheet
##An array of all players
var all_chars:Array[FlowCharacterSheet]

func add_player(id:RID) -> void:
	var new_char:FlowCharacterSheet = find_char(id)
	if not new_char.character_id.is_valid():
		new_char.character_id = id
		all_chars.append(new_char)
		last_char = new_char
		print("Character added!")

func find_char(id:RID) -> FlowCharacterSheet:
	for players in all_chars:
		if players.character_id == id:
			return players
	return FlowCharacterSheet.new()

##Get the boost amount of a player
func getBoostAmount(id:RID) -> float:
	if last_char.character_id != id:
		last_char = find_char(id)
	return last_char.boostAmount

func getBoostMax(id:RID) -> float:
	if last_char.character_id != id:
		last_char = find_char(id)
	return last_char.maxBoost

##This adds amount of boost to area player
func boostChangeBy(id:RID, amount:float) -> void:
	if last_char.character_id != id:
		last_char = find_char(id)
	last_char.boostAmount = minf(last_char.boostAmount + amount, last_char.maxBoost)
	emit_signal("boost_updated", id)

##Set the maximum boost of a character. 
##This will also fill their boost gauge
func setMaxBoost(id:RID, maxboost:float) -> void:
	if last_char.character_id != id:
		last_char = find_char(id)
	last_char.maxBoost = maxboost
	last_char.boostAmount = maxboost
	emit_signal("boost_updated", id)



##Get the ring count of a player
func getRingCount(id:RID) -> int:
	if last_char.character_id != id:
		last_char = find_char(id)
	return last_char.rings

##This adds amount rings to area player
func addRing(id:RID, amount:int) -> void:
	if last_char.character_id != id:
		last_char = find_char(id)
	last_char.rings += amount
	emit_signal("rings_updated", id)
