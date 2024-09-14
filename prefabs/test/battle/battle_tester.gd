extends BattleController

@export var encounter: StaticEncounter = null
@export var _playerCombatant: Combatant
@export var playerLv: int = 1
@export var playerCommand: BattleCommand = null
@export var playerStatus: StatusEffect = null
@export var minionCommand: BattleCommand = null
@export var minionStatus: StatusEffect = null
@export var enemy1Command: BattleCommand = null
@export var enemy1Status: StatusEffect = null
@export var enemy2Command: BattleCommand = null
@export var enemy2Status: StatusEffect = null
@export var enemy3Command: BattleCommand = null
@export var enemy3Status: StatusEffect = null

@onready var battleAnimManager: BattleAnimationManager = get_node('BattleAnimationManager')
@onready var nextButton: Button = get_node('SfxButton')

func _ready():
	battleUI = get_node('MockBattleUI')
	SceneLoader.audioHandler = get_node('AudioHandler')
	PlayerResources.playerInfo = PlayerInfo.new()
	PlayerResources.playerInfo.encounter = encounter
	nextButton.grab_focus()
	var combatants: Array[Combatant] = [_playerCombatant, encounter.autoAlly, encounter.combatant1, encounter.combatant2, encounter.combatant3]
	var combatantLvs: Array[int] = [playerLv, encounter.autoAllyLevel, encounter.combatant1Level, encounter.combatant2Level, encounter.combatant3Level]
	var combatantCommands: Array[BattleCommand] = [playerCommand, minionCommand, enemy1Command, enemy2Command, enemy3Command]
	var combatantStatuses: Array[StatusEffect] = [playerStatus, minionStatus, enemy1Status, enemy2Status, enemy3Status]
	for idx in range(len(combatants)):
		var combatant: Combatant = combatants[idx]
		if combatant != null:
			# keep track of current HP since we will do level ups immediately here
			var currentCombatantHp: int = combatant.currentHp
			if combatantLvs[idx] > combatant.stats.level:
				combatant.level_up_nonplayer(combatantLvs[idx])
			if len(combatant.stats.moves) == 0:
				combatant.assign_moves_nonplayer()
			for move: Move in combatant.stats.moves:
				print(combatant.disp_name(), ': ', move.moveName)
			if currentCombatantHp == -1:
				combatant.currentHp = combatant.stats.maxHp
			else:
				combatant.currentHp = currentCombatantHp
			if combatant.statChanges == null:
				combatant.statChanges = StatChanges.new()
			combatant.command = combatantCommands[idx]
			combatant.statusEffect = combatantStatuses[idx]
			combatant = combatant.copy()
		battleAnimManager.get_all_combatant_nodes()[idx].combatant = combatant
		battleAnimManager.get_all_combatant_nodes()[idx].load_combatant_node()
	var battleState = BattleState.new()
	battleState.menu = BattleState.Menu.PRE_ROUND
	battleUI.menuState = BattleState.Menu.PRE_ROUND
	# get command for each combatant, if that combatant is alive and hasn't made a command, get one
	for combatantNode: CombatantNode in battleAnimManager.get_all_combatant_nodes():
		if combatantNode.combatant != null and combatantNode.is_alive():
			combatantNode.get_command(battleAnimManager.get_all_combatant_nodes())
	
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
	return battleAnimManager.get_all_combatant_nodes()

func _on_battle_animation_manager_combatant_animation_start() -> void:
	nextButton.disabled = true

func _on_battle_animation_manager_combatant_animation_complete() -> void:
	nextButton.disabled = false
