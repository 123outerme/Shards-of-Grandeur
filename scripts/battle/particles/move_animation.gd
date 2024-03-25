extends Resource
class_name MoveAnimation

@export var combatantAnimation: String = ''
@export var makesContact: bool = false
@export var userParticlePreset: ParticlePreset = null
@export var targetsParticlePreset: ParticlePreset = null
@export var moveSprites: Array[MoveAnimSprite] = []

func _init(
	i_combatantAnimation = '',
	i_makesContact = false,
	i_userParticles = null,
	i_targetsParticles = null,
	i_moveSprites: Array[MoveAnimSprite] = [],
):
	combatantAnimation = i_combatantAnimation
	makesContact = i_makesContact
	userParticlePreset = i_userParticles
	targetsParticlePreset = i_targetsParticles
	moveSprites = i_moveSprites
