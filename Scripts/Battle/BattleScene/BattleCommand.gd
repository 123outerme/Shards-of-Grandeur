extends Resource
class_name BattleCommand

enum Type {
	NONE = 0,
	MOVE = 1,
	USE_ITEM = 2,
	ESCAPE = 3,
}

@export var type: Type = Type.NONE
@export var move: Move = null
@export var slot: InventorySlot = null
@export var targets: Array[Combatant]

static func command_guard(combatant: Combatant) -> BattleCommand:
	return BattleCommand.new(
		Type.MOVE,
		load("res://GameData/Moves/guard.tres") as Move,
		null,
		[combatant]
	)

static func command_escape() -> BattleCommand:
	return BattleCommand.new(
		Type.ESCAPE,
		null,
		null,
		[]
	)

func _init(
	i_type = Type.NONE,
	i_move = null,
	i_slot = null,
	i_targets: Array[Combatant] = [],
):
	type = i_type
	move = i_move
	slot = i_slot
	targets = i_targets
