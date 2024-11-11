extends BattleController
class_name BattleTester

@export var useBattleAnims: bool = true

@export var encounter: StaticEncounter = null
@export var _playerCombatant: Combatant
@export var playerLv: int = 1
@export var playerAi: CombatantAi = null
@export var playerCommand: BattleCommand = null
@export var currentPlayerHp: int = -1
@export var playerStatAllocStrat: StatAllocationStrategy = null
@export var playerStatus: StatusEffect = null
@export var playerRunes: Array[Rune] = []
@export var playerRuneCasterPositions: Array[String] = []
@export var minionCommand: BattleCommand = null
@export var minionStatus: StatusEffect = null
@export var minionRunes: Array[Rune] = []
@export var minionRuneCasterPositions: Array[String] = []
@export var enemy1Command: BattleCommand = null
@export var enemy1Status: StatusEffect = null
@export var enemy1Runes: Array[Rune] = []
@export var enemy1RuneCasterPositions: Array[String] = []
@export var enemy2Command: BattleCommand = null
@export var enemy2Status: StatusEffect = null
@export var enemy2Runes: Array[Rune] = []
@export var enemy2RuneCasterPositions: Array[String] = []
@export var enemy3Command: BattleCommand = null
@export var enemy3Status: StatusEffect = null
@export var enemy3Runes: Array[Rune] = []
@export var enemy3RuneCasterPositions: Array[String] = []

@onready var nextButton: Button = get_node('SfxButton')

func _ready():
	battleUI = get_node('MockBattleUI')
	battleAnimationManager = get_node('BattleAnimationManager')
	SceneLoader.audioHandler = get_node('AudioHandler')
	PlayerResources.playerInfo = PlayerInfo.new()
	PlayerResources.playerInfo.encounter = encounter
	SettingsHandler.gameSettings = GameSettings.new()
	SettingsHandler.gameSettings.battleAnims = useBattleAnims
	nextButton.grab_focus()
	var combatants: Array[Combatant] = [_playerCombatant, encounter.autoAlly, encounter.combatant1, encounter.combatant2, encounter.combatant3]
	var combatantLvs: Array[int] = [playerLv, encounter.autoAllyLevel, encounter.combatant1Level, encounter.combatant2Level, encounter.combatant3Level]
	var combatantCommands: Array[BattleCommand] = [playerCommand, minionCommand, enemy1Command, enemy2Command, enemy3Command]
	var combatantStatuses: Array[StatusEffect] = [playerStatus, minionStatus, enemy1Status, enemy2Status, enemy3Status]
	var combatantAis: Array[CombatantAi] = [playerAi, null, null, null, null]
	if encounter is StaticEncounter:
		combatantAis[2] = encounter.combatant1Ai
		combatantAis[3] = encounter.combatant2Ai
		combatantAis[4] = encounter.combatant3Ai
	var combatantRunes: Array = [playerRunes, minionRunes, enemy1Runes, enemy2Runes, enemy3Runes]
	var combatantRuneCasters: Array = [playerRuneCasterPositions, minionRuneCasterPositions, enemy1RuneCasterPositions, enemy2RuneCasterPositions, enemy3RuneCasterPositions]
	var currentHps: Array[int] = [currentPlayerHp, -1, -1, -1, -1]
	for idx in range(len(combatants)):
		var combatant: Combatant = combatants[idx]
		if combatant != null:
			combatant = combatant.copy()
			if combatant.get_evolution() != null:
				combatant.switch_evolution(combatant.get_evolution(), null)
			if combatantLvs[idx] > combatant.stats.level:
				combatant.level_up_nonplayer(combatantLvs[idx])
			if combatant == _playerCombatant and playerStatAllocStrat != null:
				playerStatAllocStrat.allocate_stats(combatant.stats)
			if len(combatant.stats.moves) == 0:
				combatant.assign_moves_nonplayer()
			for move: Move in combatant.stats.moves:
				print(combatant.disp_name(), ': ', move.moveName)
			if currentHps[idx] == -1:
				combatant.currentHp = combatant.stats.maxHp
			else:
				combatant.currentHp = currentHps[idx]
			if combatant.statChanges == null:
				combatant.statChanges = StatChanges.new()
			combatant.statusEffect = combatantStatuses[idx]
			if combatantAis[idx] == null:
				combatantAis[idx] = combatant.get_ai()
		if combatantAis[idx] != null:
			get_all_combatant_nodes()[idx].battleAi = combatantAis[idx].copy()
		get_all_combatant_nodes()[idx].combatant = combatant
		get_all_combatant_nodes()[idx].update_current_tag_stats(true)
		get_all_combatant_nodes()[idx].load_combatant_node()
	
	for idx: int in range(len(get_all_combatant_nodes())):
		var combatantNode: CombatantNode = get_all_combatant_nodes()[idx]
		if combatantNode.combatant != null:
			combatantNode.combatant.runes = []
			for runeIdx: int in range(len(combatantRuneCasters[idx])):
				var rune: Rune = combatantRunes[idx][runeIdx]
				if rune != null:
					var caster: Combatant = null
					for cNode: CombatantNode in get_all_combatant_nodes():
						if cNode.battlePosition == combatantRuneCasters[idx][runeIdx]:
							rune.init_rune_state(combatantNode.combatant, [cNode.combatant], state)
							combatantNode.combatant.runes.append(rune)
							break
			combatantNode.update_rune_sprites(true)
			#print(len(combatantNode.combatant.runes), ' runes were placed on ', combatantNode.combatant.disp_name(), ' / ', combatantNode.battlePosition)
	
	state = BattleState.new()
	state.menu = BattleState.Menu.PRE_ROUND
	battleUI.menuState = BattleState.Menu.PRE_ROUND
	# get command for each combatant, if that combatant is alive and hasn't made a command, get one
	for combatantNode: CombatantNode in get_all_combatant_nodes():
		if combatantNode.combatant != null and combatantNode.is_alive() and combatantNode.combatant.command == null:
			combatantNode.get_command(get_all_combatant_nodes(), state)
		combatantNode.update_hp_tag()
	
	state.calcdStateIndex = 0
	turnExecutor.start_simulation()
	for idx: int in range(len(get_all_combatant_nodes())):
		if get_all_combatant_nodes()[idx].combatant != null and combatantCommands[idx] != null:
			get_all_combatant_nodes()[idx].combatant.command = combatantCommands[idx]
	
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
	return battleAnimationManager.get_all_combatant_nodes()

func _on_battle_animation_manager_combatant_animation_start() -> void:
	nextButton.disabled = true

func _on_battle_animation_manager_combatant_animation_complete() -> void:
	nextButton.disabled = false
