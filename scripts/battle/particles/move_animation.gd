extends Resource
class_name MoveAnimation

@export var combatantAnimation: String = ''
@export var makesContact: bool = false
@export var userParticlePreset: ParticlePreset = null
@export var targetsParticlePreset: ParticlePreset = null
@export var chargeMoveSprites: Array[MoveAnimSprite] = []
@export var surgeMoveSprites: Array[MoveAnimSprite] = []
@export var chargeBattlefieldShade: BattlefieldShadeAnim = null
@export var surgeBattlefieldShade: BattlefieldShadeAnim = null

func _init(
	i_combatantAnimation = '',
	i_makesContact = false,
	i_userParticles = null,
	i_targetsParticles = null,
	i_chargeMoveSprites: Array[MoveAnimSprite] = [],
	i_surgeMoveSprites: Array[MoveAnimSprite] = [],
	i_chargeBattlefieldShade = null,
	i_surgeBattlefieldShade = null,
):
	combatantAnimation = i_combatantAnimation
	makesContact = i_makesContact
	userParticlePreset = i_userParticles
	targetsParticlePreset = i_targetsParticles
	chargeMoveSprites = i_chargeMoveSprites
	surgeMoveSprites = i_surgeMoveSprites
	chargeBattlefieldShade = i_chargeBattlefieldShade
	surgeBattlefieldShade = i_surgeBattlefieldShade
