extends GPUParticles2D


func _ready() -> void:
	change_state()
	GraphicsSingleton.connect("particle_effects_changed", change_state)

func change_state() -> void:
	if GraphicsSingleton.particle_effects:
		emitting = true
	else:
		emitting = false
