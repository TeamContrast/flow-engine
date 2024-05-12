extends Node

#A singleton for graphics settings, as the name suggests

#This may *seem* unnecessary, but I've found that Flow Engine is actually capable of running quite well
# on *absurdly* old hardware, the caveat being that graphics effects slow it down a lot. Besides, as more
#graphics effects are added, a control panel of sorts for them would be nice

var real_time_lighting:bool = true

var particle_effects:bool = true

signal lighting_changed

signal particle_effects_changed

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_lighting"):
		real_time_lighting = not real_time_lighting
		emit_signal("lighting_changed")
		print("Lighting effects: ", real_time_lighting)
	elif event.is_action_pressed("toggle_particles"):
		particle_effects = not particle_effects
		emit_signal("particle_effects_changed")
		print("Particle effects: ", particle_effects)
