extends Resource
class_name MovePool

@export var pool: Array[Move] = []

func _init(i_pool: Array[Move] = []):
	pool = i_pool

func has_moves_at_level(level: int) -> bool:
	for move: Move in pool:
		if move.requiredLv == level:
			return true
	return false

func copy() -> MovePool:
	return MovePool.new(pool.duplicate(false))
