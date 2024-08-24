extends Resource
class_name MovePool

@export var pool: Array[Move] = []

## "Other" means no preference
@export var preferredMove1Role: MoveEffect.Role = MoveEffect.Role.OTHER

## "Other" means no preference
@export var preferredMove2Role: MoveEffect.Role = MoveEffect.Role.OTHER

## "Other" means no preference
@export var preferredMove3Role: MoveEffect.Role = MoveEffect.Role.OTHER

## "Other" means no preference
@export var preferredMove4Role: MoveEffect.Role = MoveEffect.Role.OTHER

func _init(
	i_pool: Array[Move] = [],
	i_prefMove1 = MoveEffect.Role.OTHER,
	i_prefMove2 = MoveEffect.Role.OTHER,
	i_prefMove3 = MoveEffect.Role.OTHER,
	i_prefMove4 = MoveEffect.Role.OTHER,
):
	pool = i_pool
	preferredMove1Role = i_prefMove1
	preferredMove2Role = i_prefMove2
	preferredMove3Role = i_prefMove3
	preferredMove4Role = i_prefMove4

func has_moves_at_level(level: int) -> bool:
	for move: Move in pool:
		if move.requiredLv == level:
			return true
	return false

func copy() -> MovePool:
	return MovePool.new(pool.duplicate(false))
