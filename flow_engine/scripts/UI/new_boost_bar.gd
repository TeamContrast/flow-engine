extends TextureProgressBar

var linked_player_id:RID 

func _init() -> void:
	#Connect to the singleton to look for a player to link to
	FlowStatSingleton.connect("boost_updated", setupBoostBar)

func setupBoostBar(id:RID) -> void:
	#make sure this is the right player
	if id != linked_player_id:
		return
	#setup the boost bar to reflect the boost amount of the character
	max_value = FlowStatSingleton.getBoostAmount(id)
	
	#Detach from setup now that we're set up, and connect to update signals
	FlowStatSingleton.disconnect("boost_updated", setupBoostBar)
	FlowStatSingleton.connect("boost_updated", updateBoostBar)

func updateBoostBar(id:RID) -> void:
	if id != linked_player_id:
		return
	value = FlowStatSingleton.getBoostAmount(id)
