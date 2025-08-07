extends BattleController

signal results_ok_pressed
signal start_next_round

@export var bgMap: PackedScene

@export var useBattleAnims: bool = true
@export var allowSurge: bool = true
@export var allowRunes: bool = true

@export var encounter: StaticEncounter = null
@export var _playerCombatant: Combatant
@export var playerLv: int = 1
@export_range(0, Combatant.MAX_ORBS) var playerOrbs: int = 0
@export var playerAi: CombatantAi = null
@export var playerCommand: BattleCommand = null
@export var currentPlayerHp: int = -1
@export var playerStatAllocStrat: StatAllocationStrategy = null
@export var playerStatus: StatusEffect = null
@export var playerRunes: Array[Rune] = []
@export var playerRuneCasterPositions: Array[String] = []
@export_range(0, Combatant.MAX_ORBS) var minionOrbs: int = 0
@export var minionCommand: BattleCommand = null
@export var minionStatus: StatusEffect = null
@export var minionRunes: Array[Rune] = []
@export var minionRuneCasterPositions: Array[String] = []
@export_range(0, Combatant.MAX_ORBS) var enemy1Orbs: int = 0
@export var enemy1Command: BattleCommand = null
@export var enemy1Status: StatusEffect = null
@export var enemy1Runes: Array[Rune] = []
@export var enemy1RuneCasterPositions: Array[String] = []
@export_range(0, Combatant.MAX_ORBS) var enemy2Orbs: int = 0
@export var enemy2Command: BattleCommand = null
@export var enemy2Status: StatusEffect = null
@export var enemy2Runes: Array[Rune] = []
@export var enemy2RuneCasterPositions: Array[String] = []
@export_range(0, Combatant.MAX_ORBS) var enemy3Orbs: int = 0
@export var enemy3Command: BattleCommand = null
@export var enemy3Status: StatusEffect = null
@export var enemy3Runes: Array[Rune] = []
@export var enemy3RuneCasterPositions: Array[String] = []

@onready var initialOkButton: Button = $BattleCam/BattleTextBox/TextContainer/MarginContainer/Results/InitialOKButton

var simStarted: bool = false

func _ready() -> void:
	tilemapParent = get_node('TileMapParent')
	battleAnimationManager = get_node('BattleAnimationManager')
	battleUI = get_node('BattleCam')
	var map: Node = bgMap.instantiate()
	tilemapParent.add_child(map)
	SceneLoader.audioHandler = get_node('AudioHandler')
	SceneLoader.audioHandler.play_music(encounter.battleMusic, -1)
	PlayerResources.playerInfo = PlayerInfo.new()
	PlayerResources.playerInfo.encounter = encounter
	if allowSurge:
		# enable the battle text to show whether a move was charged or surged 
		PlayerResources.questInventory.currentAct = 1
		PlayerResources.playerInfo.set_dialogue_seen('grandstone_dr_ildran', 'surge')
	if allowRunes:
		PlayerResources.questInventory.currentAct = 2
		PlayerResources.playerInfo.set_cutscene_seen('standstill_helia_approach')
	SettingsHandler.gameSettings = GameSettings.new()
	SettingsHandler.gameSettings.battleAnims = useBattleAnims
	var combatants: Array[Combatant] = [_playerCombatant, encounter.autoAlly, encounter.combatant1, encounter.combatant2, encounter.combatant3]
	var combatantLvs: Array[int] = [playerLv, encounter.autoAllyLevel, encounter.combatant1Level, encounter.combatant2Level, encounter.combatant3Level]
	var combatantOrbs: Array[int] = [playerOrbs, minionOrbs, enemy1Orbs, enemy2Orbs, enemy3Orbs]
	var combatantArmor: Array[Armor] = [null, encounter.autoAllyArmor, encounter.combatant1Armor, encounter.combatant2Armor, encounter.combatant3Armor]
	var combatantWeapons: Array[Weapon] = [null, encounter.autoAllyWeapon, encounter.combatant1Weapon, encounter.combatant2Weapon, encounter.combatant3Weapon]
	var combatantCommands: Array[BattleCommand] = [playerCommand, minionCommand, enemy1Command, enemy2Command, enemy3Command]
	var combatantStatuses: Array[StatusEffect] = [playerStatus, minionStatus, enemy1Status, enemy2Status, enemy3Status]
	var combatantAis: Array[CombatantAi] = [playerAi, null, null, null, null]
	var combatantStatAllocStrats: Array[StatAllocationStrategy] = [playerStatAllocStrat, null, null, null, null]
	var combatantMoves: Array[Array] = [[], encounter.autoAllyMoves, encounter.combatant1Moves, encounter.combatant2Moves, encounter.combatant3Moves]
	if encounter is StaticEncounter:
		combatantAis[1] = encounter.autoAllyAi
		combatantAis[2] = encounter.combatant1Ai
		combatantAis[3] = encounter.combatant2Ai
		combatantAis[4] = encounter.combatant3Ai
		
		combatantStatAllocStrats[1] = encounter.autoAllyStatAllocStrat
		combatantStatAllocStrats[2] = encounter.combatant1StatAllocStrat
		combatantStatAllocStrats[3] = encounter.combatant2StatAllocStrat
		combatantStatAllocStrats[4] = encounter.combatant3StatAllocStrat
	var combatantRunes: Array = [playerRunes, minionRunes, enemy1Runes, enemy2Runes, enemy3Runes]
	var combatantRuneCasters: Array = [playerRuneCasterPositions, minionRuneCasterPositions, enemy1RuneCasterPositions, enemy2RuneCasterPositions, enemy3RuneCasterPositions]
	var currentHps: Array[int] = [currentPlayerHp, -1, -1, -1, -1]
	for idx in range(len(combatants)):
		var combatant: Combatant = combatants[idx]
		if combatant != null:
			combatant = combatant.copy()
			combatant.stats.equippedArmor = combatantArmor[idx]
			combatant.stats.equippedWeapon = combatantWeapons[idx]
			if combatant.get_evolution() != null:
				combatant.switch_evolution(combatant.get_evolution(), null)
			if combatantLvs[idx] > combatant.stats.level:
				combatant.level_up_nonplayer(combatantLvs[idx], combatantStatAllocStrats[idx])
			if len(combatant.stats.moves) == 0:
				if combatantMoves[idx] != null and len(combatantMoves[idx]) > 0:
					combatant.stats.moves = combatantMoves[idx].duplicate(false)
				else:
					combatant.assign_moves_nonplayer()
			for move: Move in combatant.stats.moves:
				print(combatant.disp_name(), ': ', move.moveName)
			if currentHps[idx] == -1:
				combatant.currentHp = combatant.stats.maxHp
			else:
				combatant.currentHp = currentHps[idx]
			if combatant.statChanges == null:
				combatant.statChanges = StatChanges.new()
			combatant.orbs = combatantOrbs[idx]
			combatant.statusEffect = combatantStatuses[idx]
			if combatantAis[idx] == null:
				combatantAis[idx] = combatant.get_ai()
		if combatantAis[idx] != null:
			get_all_combatant_nodes()[idx].battleAi = combatantAis[idx].copy()
		get_all_combatant_nodes()[idx].combatant = combatant
		get_all_combatant_nodes()[idx].role = CombatantNode.Role.ENEMY if idx > 1 else CombatantNode.Role.ALLY
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
	
	battleUI.allCommands._ready() # run the ready function again now that we're set up
	battleUI.results.okBtn.visible = false # make invisible so that we can use the other OK button to wait for the recorder to be ready
	
	state = BattleState.new()
	
	for combatantNode: CombatantNode in get_all_combatant_nodes():
		combatantNode.update_hp_tag()
	battleUI.battlePanels.set_turn_counter(1, encounter.winCon)
	await results_ok_pressed
	
	simStarted = true
	while battleUI.battleController.turnExecutor.result == WinCon.TurnResult.NOTHING:
		# get player and ally command (since normally it isn't auto calculated)
		battleUI.battleController.playerCombatant.get_command(battleUI.battleController.get_all_combatant_nodes(), battleUI.battleController.state)
		battleUI.battleController.minionCombatant.get_command(battleUI.battleController.get_all_combatant_nodes(), battleUI.battleController.state)
		
		battleUI.menuState = BattleState.Menu.PRE_ROUND
		battleUI.commandingMinion = true # sets up state so complete_command will start pre-round
		battleUI.complete_command() # start pre-round
		
		await start_next_round
		
		# advance turn number
		battleUI.battleController.state.turnNumber += 1
		battleUI.battlePanels.set_turn_counter(battleUI.battleController.state.turnNumber, encounter.winCon)

func _on_battle_cam_menu_state_changed(battleState: BattleState.Menu) -> void:
	if battleState == BattleState.Menu.ALL_COMMANDS and simStarted:
		start_next_round.emit()

func _on_results_ok_button_pressed() -> void:
	initialOkButton.visible = false
	battleUI.results.okBtn.visible = true
	results_ok_pressed.emit()
