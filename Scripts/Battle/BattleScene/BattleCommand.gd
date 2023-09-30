extends Resource
class_name BattleCommand

enum Type {
	NONE = 0,
	MOVE = 1,
	USE_ITEM = 2,
	ESCAPE = 3,
}

@export var type: Type = Type.NONE
#@export var move: Move = null
@export var item: Item = null
@export var targets: Array
#@export var user: 

func _init():
	pass
