extends Resource
class_name MoveAnimation

enum AnimContactTarget {
	GLOBAL = 0, ## Global (always tween to global)
	TARGET = 1, ## Target (enemy or ally, or team/global if move targets multiple)
	TARGET_TEAM = 2, ## Target's Team (always tween to enemy team, ally team, or global even if targets single)
}

## sprite animation to play with this move
@export var combatantAnimation: String = ''

@export_category('Contact Animation (Tweening to Target Combatant)')
## if true, the user will tween towards the move target(s)'s position (if not self)
@export var makesContact: bool = false

## Where the user's movement tween should take them
@export var makesContactTarget: AnimContactTarget = AnimContactTarget.TARGET

## the position offset the tween must go to. X direction is reversed if user is on the right side 
@export var makesContactPosOffset: Vector2 = Vector2.ZERO

@export_category('Hide HP Tags')
@export var hideUserHpTag: bool = false
@export var hideTargetHpTag: bool = false

@export_category('Particle Presets')
@export var userParticlePreset: ParticlePreset = null
@export var targetsParticlePreset: ParticlePreset = null

@export_category('Move Sprites')
@export var chargeMoveSprites: Array[MoveAnimSprite] = []
@export var surgeMoveSprites: Array[MoveAnimSprite] = []

@export_category('Battlefield Shades')
@export var chargeBattlefieldShade: BattlefieldShadeAnim = null
@export var surgeBattlefieldShade: BattlefieldShadeAnim = null

func _init(
	i_combatantAnimation = '',
	i_makesContact = false,
	i_makesContactTarget: AnimContactTarget = AnimContactTarget.TARGET,
	i_makesContactPosOffset: Vector2 = Vector2.ZERO,
	i_hideUserHpTag = false,
	i_hideTargetHpTag = false,
	i_userParticles = null,
	i_targetsParticles = null,
	i_chargeMoveSprites: Array[MoveAnimSprite] = [],
	i_surgeMoveSprites: Array[MoveAnimSprite] = [],
	i_chargeBattlefieldShade = null,
	i_surgeBattlefieldShade = null,
):
	combatantAnimation = i_combatantAnimation
	makesContact = i_makesContact
	makesContactTarget = i_makesContactTarget
	makesContactPosOffset = i_makesContactPosOffset
	hideUserHpTag = i_hideUserHpTag
	hideTargetHpTag = i_hideTargetHpTag
	userParticlePreset = i_userParticles
	targetsParticlePreset = i_targetsParticles
	chargeMoveSprites = i_chargeMoveSprites
	surgeMoveSprites = i_surgeMoveSprites
	chargeBattlefieldShade = i_chargeBattlefieldShade
	surgeBattlefieldShade = i_surgeBattlefieldShade
