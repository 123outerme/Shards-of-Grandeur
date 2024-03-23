extends BattleController

@export var _playerCombatant: Combatant
@export var playerLv: int = 1
@export var _minionCombatant: Combatant
@export var minionLv: int = 1
@export var enemy1Combatant: Combatant
@export var enemy1Lv: int = 1
@export var enemy2Combatant: Combatant
@export var enemy2Lv: int = 1
@export var enemy3Combatant: Combatant
@export var enemy3Lv: int = 1

@onready var allCombatantNodes: Array[CombatantNode] = [
	get_node('PlayerCombatantNode'),
	get_node('MinionCombatantNode'),
	get_node('Enemy1CombatantNode'),
	get_node('Enemy2CombatantNode'),
	get_node('Enemy3CombatantNode')
]
@onready var nextButton: Button = get_node('SfxButton')

func _ready():
	battleUI = get_node('MockBattleUI')
	SceneLoader.audioHandler = get_node('AudioHandler')
	nextButton.grab_focus()
	var combatants: Array[Combatant] = [_playerCombatant, _minionCombatant, enemy1Combatant, enemy2Combatant, enemy3Combatant]
	var combatantLvs: Array[int] = [playerLv, minionLv, enemy1Lv, enemy2Lv, enemy3Lv]
	for idx in range(len(combatants)):
		var combatant = combatants[idx]
		if combatant != null:
			if combatantLvs[idx] > combatant.stats.level:
				combatant.level_up_nonplayer(combatantLvs[idx] - combatant.stats.level)
			if len(combatant.stats.moves) == 0:
				combatant.assign_moves_nonplayer()
			if combatant.currentHp == -1:
				combatant.currentHp = combatant.stats.maxHp
			if combatant.statChanges == null:
				combatant.statChanges = StatChanges.new()
			combatant = combatant.copy()
		allCombatantNodes[idx].combatant = combatant
		allCombatantNodes[idx].load_combatant_node()
	var battleState = BattleState.new()
	battleState.menu = BattleState.Menu.PRE_ROUND
	battleUI.menuState = BattleState.Menu.PRE_ROUND
	# get command for each combatant, if that combatant is alive and hasn't made a command, get one
	for combatantNode in allCombatantNodes:
		if combatantNode.combatant != null and combatantNode.is_alive():
			combatantNode.get_command(allCombatantNodes)
	
	state.calcdStateIndex = 0
	turnExecutor.start_simulation()
	turnExecutor.update_turn_text()
	while state.calcdStateIndex < len(state.calcdStateStrings):
		turnExecutor.update_turn_text()
		state.calcdStateIndex += 1
	
	if battleUI.menuState != BattleState.Menu.RESULTS:
		battleUI.menuState = BattleState.Menu.RESULTS
		await nextButton.pressed
		turnExecutor.play_turn()
	while turnExecutor.turnQueue.peek_next() != null:
		await nextButton.pressed
		turnExecutor.finish_turn()
	
	reset_intermediate_state_strs()
	turnExecutor.update_turn_text()
	await nextButton.pressed
	while not turnExecutor.advance_precalcd_text():
		await nextButton.pressed
	nextButton.visible = false

func get_all_combatant_nodes() -> Array[CombatantNode]:
	return allCombatantNodes
