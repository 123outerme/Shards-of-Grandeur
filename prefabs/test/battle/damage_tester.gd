@tool
extends Control

@export var attacker: Combatant
@export var attackerLv: int = 1
@export var move: Move
@export var surgeEffect: bool = false
@export_range(0, 10) var spendOrbs: int = 0
@export var defender: Combatant
@export var defenderLv: int = 1

@export var test: bool:
	get:
		return false
	set(val):
		run_damage_tests()

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		run_damage_tests()

func run_damage_tests():
	if attacker == null or defender == null or move == null:
		printerr('Warning: attacker/defender/move not set up')
		return
	
	if attacker.stats.level < attackerLv:
		attacker.level_up_nonplayer(attackerLv)
	attacker.orbs = min(spendOrbs * -1, move.surgeEffect.orbChange) if surgeEffect else 0
	if defender.stats.level < defenderLv:
		defender.level_up_nonplayer(defenderLv)
	
	var attackerNode: CombatantNode = CombatantNode.new()
	attackerNode.combatant = attacker
	
	var defenderNode: CombatantNode = CombatantNode.new()
	defenderNode.combatant = defender
	defenderNode.battlePosition = 'defender'
	
	var command: BattleCommand = BattleCommand.new(BattleCommand.Type.MOVE,
		move,
		Move.MoveEffectType.CHARGE if not surgeEffect else Move.MoveEffectType.SURGE,
		min(spendOrbs * -1, move.surgeEffect.orbChange) if surgeEffect else move.chargeEffect.orbChange,
		null,
		['defender'],
	)
	print('Defender HP before: ', defender.currentHp)
	command.execute_command(attacker, [defenderNode])
	print(command.get_command_results(attacker))
	print('Defender HP after: ', defender.currentHp)
	print('Attacker stats:\n', attacker.stats.print_stats())
	print('Defender stats:\n', defender.stats.print_stats())
