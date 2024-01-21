extends Resource
class_name MovePool

@export var pool: Array[Move] = []

func _init(i_pool: Array[Move] = []):
	pool = i_pool

func copy() -> MovePool:
	return MovePool.new(pool.duplicate(false))
