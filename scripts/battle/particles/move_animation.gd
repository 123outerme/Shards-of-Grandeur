extends Resource
class_name MoveAnimation

@export var combatantAnimation: String = ''
@export var userParticlePreset: ParticlePreset = null
@export var targetsParticlePreset: ParticlePreset = null

func _init(
	i_combatantAnimation = '',
	i_userParticles = null,
	i_targetsParticles = null,
):
	combatantAnimation = i_combatantAnimation
	userParticlePreset = i_userParticles
	targetsParticlePreset = i_targetsParticles
