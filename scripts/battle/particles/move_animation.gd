extends Resource
class_name MoveAnimation

@export var combatantAnimation: String = ''
@export var particlePreset: ParticlePreset = null

func _init(
	i_combatantAnimation = '',
	i_particlePreset = null,
):
	combatantAnimation = i_combatantAnimation
	particlePreset = i_particlePreset
