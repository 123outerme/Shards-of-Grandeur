extends Resource
class_name MovePool

## all moves a combatant will learn
@export var pool: Array[Move] = []

## the moves a combatant can use that should be given slight priority for selection by AI in battles
@export var signatureMoves: Array[Move] = []

## "Other" means no preference
@export var preferredMove1Role: MoveEffect.Role = MoveEffect.Role.OTHER

## "Any" means no preference
@export var preferredMove1DmgType: Move.DmgCategory = Move.DmgCategory.ANY

## "None" means no preference
@export var preferredMove1Element: Move.Element = Move.Element.NONE

## "Other" means no preference
@export var preferredMove2Role: MoveEffect.Role = MoveEffect.Role.OTHER

## "Any" means no preference
@export var preferredMove2DmgType: Move.DmgCategory = Move.DmgCategory.ANY

## "None" means no preference
@export var preferredMove2Element: Move.Element = Move.Element.NONE

## "Other" means no preference
@export var preferredMove3Role: MoveEffect.Role = MoveEffect.Role.OTHER

## "Any" means no preference
@export var preferredMove3DmgType: Move.DmgCategory = Move.DmgCategory.ANY

## "None" means no preference
@export var preferredMove3Element: Move.Element = Move.Element.NONE

## "Other" means no preference
@export var preferredMove4Role: MoveEffect.Role = MoveEffect.Role.OTHER

## "Any" means no preference
@export var preferredMove4DmgType: Move.DmgCategory = Move.DmgCategory.ANY

## "None" means no preference
@export var preferredMove4Element: Move.Element = Move.Element.NONE

func _init(
	i_pool: Array[Move] = [],
	i_signatureMoves: Array[Move] = [],
	i_prefRole1 = MoveEffect.Role.OTHER,
	i_prefType1 = Move.DmgCategory.ANY,
	i_prefElement1 = Move.Element.NONE,
	i_prefRole2 = MoveEffect.Role.OTHER,
	i_prefType2 = Move.DmgCategory.ANY,
	i_prefElement2 = Move.Element.NONE,
	i_prefRole3 = MoveEffect.Role.OTHER,
	i_prefType3 = Move.DmgCategory.ANY,
	i_prefElement3 = Move.Element.NONE,
	i_prefRole4 = MoveEffect.Role.OTHER,
	i_prefType4 = Move.DmgCategory.ANY,
	i_prefElement4 = Move.Element.NONE,
):
	pool = i_pool
	preferredMove1Role = i_prefRole1
	preferredMove1DmgType = i_prefType1
	preferredMove1Element = i_prefElement1
	
	preferredMove2Role = i_prefRole2
	preferredMove2DmgType = i_prefType2
	preferredMove2Element = i_prefElement2
	
	preferredMove3Role = i_prefRole3
	preferredMove3DmgType = i_prefType3
	preferredMove3Element = i_prefElement3
	
	preferredMove4Role = i_prefRole4
	preferredMove4DmgType = i_prefType4
	preferredMove4Element = i_prefElement4

func has_moves_at_level(level: int) -> bool:
	for move: Move in pool:
		if move.requiredLv == level:
			return true
	return false

func copy() -> MovePool:
	return MovePool.new(
		pool.duplicate(false),
		signatureMoves.duplicate(false),
		preferredMove1Role,
		preferredMove1DmgType,
		preferredMove1Element,
		preferredMove2Role,
		preferredMove2DmgType,
		preferredMove2Element,
		preferredMove3Role,
		preferredMove3DmgType,
		preferredMove3Element,
		preferredMove4Role,
		preferredMove4DmgType,
		preferredMove4Element,
	)
