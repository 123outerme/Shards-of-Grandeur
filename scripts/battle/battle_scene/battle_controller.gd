extends Node2D
class_name BattleController

signal combatant_finished_moving
signal combatants_play_hit
signal combatant_finished_animating

 # below this level, 2 enemies cannot spawn from a random battle
const MIN_LV_TWO_ENEMIES = 4
# above this level, the chance to spawn 2 enemies is not modified
const MAX_LV_TWO_ENEMIES = 8
# below this level, 3 enemies cannot spawn from a random battle
const MIN_LV_THREE_ENEMIES = 10
# above this level, the chance to spawn 3 enemies is not modified
const MAX_LV_THREE_ENEMIES = 20

@export var state: BattleState = BattleState.new()
@export var globalMarker: Marker2D

var battleLoaded: bool = false
var battleEnded: bool = false

@onready var tilemapParent: Node2D = get_node_or_null('TileMapParent')
var tilemap: TileMap = null
var battleMapPath: String = ''

@onready var combatantGroup: Node2D = get_node_or_null('CombatantGroup')
@onready var combatantNodes: Array[Node] = get_tree().get_nodes_in_group("CombatantNode")
@onready var playerCombatant: CombatantNode = get_node_or_null("CombatantGroup/PlayerCombatant")
@onready var minionCombatant: CombatantNode = get_node_or_null("CombatantGroup/MinionCombatant")
@onready var enemyCombatant1: CombatantNode = get_node_or_null("CombatantGroup/EnemyCombatant1")
@onready var enemyCombatant2: CombatantNode = get_node_or_null("CombatantGroup/EnemyCombatant2")
@onready var enemyCombatant3: CombatantNode = get_node_or_null("CombatantGroup/EnemyCombatant3")

@onready var battleUI: BattleUI = get_node_or_null("BattleCam")
@onready var battlePanels: BattlePanels = get_node_or_null("BattleCam/UIPanels")
@onready var turnExecutor: TurnExecutor = get_node_or_null("TurnExecutor")
@onready var shade: ColorRect = get_node_or_null('Shade')

var shadeTween: Tween = null

var battleMapsDir: String = 'res://prefabs/battle/battle_maps/'

# Called when the node enters the scene tree for the first time.
func _ready():
	battleLoaded = false
	if PlayerResources.battleSaveFolder != '':
		SaveHandler.load_data(PlayerResources.battleSaveFolder)
	call_deferred('load_into_battle')
	
func load_into_battle():
	if SceneLoader.curMapEntry == null:
		var worldLocation: WorldLocation = MapLoader.get_world_location_for_name(PlayerResources.playerInfo.map)
		SceneLoader.curMapEntry = worldLocation.maps[len(worldLocation.maps) - 1]
		for mapEntry: MapEntry in worldLocation.maps:
			if mapEntry.requirements == null or mapEntry.requirements.is_valid():
				SceneLoader.curMapEntry = mapEntry
				break
	battleMapPath = SceneLoader.curMapEntry.get_battle_map_path()
	var battleMap = load(battleMapPath)
	tilemap = battleMap.instantiate()
	tilemapParent.add_child(tilemap)
	
	var newBattle: bool = state.enemyCombatant1 == null
	var hasStaticMinion: bool = false
	if newBattle: # new battle
		playerCombatant.combatant = PlayerResources.playerInfo.combatant.copy()
		playerCombatant.combatant.orbs = playerCombatant.combatant.get_starting_orbs()
		minionCombatant.combatant = null
		if PlayerResources.playerInfo.encounter is StaticEncounter:
			var staticEncounter: StaticEncounter = PlayerResources.playerInfo.encounter as StaticEncounter
			enemyCombatant1.combatant = staticEncounter.combatant1.copy().initialize()
			enemyCombatant1.combatant.stats.equippedArmor = staticEncounter.combatant1Armor
			enemyCombatant1.combatant.stats.equippedWeapon = staticEncounter.combatant1Weapon
			# stats start out in base form, this will evolve the combatant
			if enemyCombatant1.combatant.get_evolution() != null:
				enemyCombatant1.combatant.switch_evolution(enemyCombatant1.combatant.get_evolution(), null)
			enemyCombatant1.initialCombatantLv = enemyCombatant1.combatant.stats.level
			enemyCombatant1.combatant.level_up_nonplayer(staticEncounter.combatant1Level, staticEncounter.combatant1StatAllocStrat)
			enemyCombatant1.combatant.orbs = enemyCombatant1.combatant.get_starting_orbs()
			if len(staticEncounter.combatant1Moves) == 0:
				enemyCombatant1.combatant.assign_moves_nonplayer()
			else:
				enemyCombatant1.combatant.stats.moves = staticEncounter.combatant1Moves.duplicate()
		
			if staticEncounter.combatant2 != null:
				enemyCombatant2.combatant = staticEncounter.combatant2.copy().initialize()
				enemyCombatant2.combatant.stats.equippedArmor = staticEncounter.combatant2Armor
				enemyCombatant2.combatant.stats.equippedWeapon = staticEncounter.combatant2Weapon
				# stats start out in base form, this will evolve the combatant
				if enemyCombatant2.combatant.get_evolution() != null:
					enemyCombatant2.combatant.switch_evolution(enemyCombatant2.combatant.get_evolution(), null)
				enemyCombatant2.initialCombatantLv = enemyCombatant2.combatant.stats.level
				enemyCombatant2.combatant.level_up_nonplayer(staticEncounter.combatant2Level, staticEncounter.combatant2StatAllocStrat)
				enemyCombatant2.combatant.orbs = enemyCombatant2.combatant.get_starting_orbs()
				if len(staticEncounter.combatant2Moves) == 0:
					enemyCombatant2.combatant.assign_moves_nonplayer()
				else:
					enemyCombatant2.combatant.stats.moves = staticEncounter.combatant2Moves.duplicate()
			
			if staticEncounter.combatant3 != null:
				enemyCombatant3.combatant = staticEncounter.combatant3.copy().initialize()
				enemyCombatant3.combatant.stats.equippedArmor = staticEncounter.combatant3Armor
				enemyCombatant3.combatant.stats.equippedWeapon = staticEncounter.combatant3Weapon
				if enemyCombatant3.combatant.get_evolution() != null:
					enemyCombatant3.combatant.switch_evolution(enemyCombatant3.combatant.get_evolution(), null)
				enemyCombatant3.initialCombatantLv = enemyCombatant3.combatant.stats.level
				enemyCombatant3.combatant.level_up_nonplayer(staticEncounter.combatant3Level, staticEncounter.combatant3StatAllocStrat)
				enemyCombatant3.combatant.orbs = enemyCombatant3.combatant.get_starting_orbs()
				if len(staticEncounter.combatant3Moves) == 0:
					enemyCombatant3.combatant.assign_moves_nonplayer()
				else:
					enemyCombatant3.combatant.stats.moves = staticEncounter.combatant3Moves.duplicate()
			
			if staticEncounter.autoAlly != null:
				hasStaticMinion = true
				minionCombatant.combatant = staticEncounter.autoAlly.copy().initialize()
				minionCombatant.combatant.stats.equippedArmor = staticEncounter.autoAllyArmor
				minionCombatant.combatant.stats.equippedWeapon = staticEncounter.autoAllyWeapon
				if minionCombatant.combatant.get_evolution() != null:
					minionCombatant.combatant.switch_evolution(minionCombatant.combatant.get_evolution(), null)
				minionCombatant.initialCombatantLv = minionCombatant.combatant.stats.level
				minionCombatant.combatant.level_up_nonplayer(staticEncounter.autoAllyLevel, staticEncounter.autoAllyStatAllocStrat)
				minionCombatant.combatant.orbs = minionCombatant.combatant.get_starting_orbs()
				if len(staticEncounter.autoAllyMoves) == 0:
					minionCombatant.combatant.assign_moves_nonplayer()
				else:
					minionCombatant.combatant.stats.moves = staticEncounter.autoAllyMoves.duplicate() 
		else:
			var randomEncounter: RandomEncounter = PlayerResources.playerInfo.encounter as RandomEncounter
			# load enemy 1
			enemyCombatant1.combatant = randomEncounter.combatant1.copy().initialize()
			if randomEncounter.combatant1Equipment != null:
				var equipmentIdx: int = WeightedThing.pick_item(randomEncounter.combatant1Equipment.weightedEquipment)
				if equipmentIdx > -1:
					enemyCombatant1.combatant.stats.equippedArmor = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].armor
					enemyCombatant1.combatant.stats.equippedWeapon = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].weapon
			else:
				enemyCombatant1.combatant.pick_equipment()
			if enemyCombatant1.combatant.get_evolution() != null:
				enemyCombatant1.combatant.switch_evolution(enemyCombatant1.combatant.get_evolution(), null)
			enemyCombatant1.initialCombatantLv = enemyCombatant1.combatant.stats.level
			enemyCombatant1.combatant.level_up_nonplayer(randomEncounter.get_combatant_level(), randomEncounter.combatant1StatAllocStrat)
			enemyCombatant1.combatant.orbs = enemyCombatant1.combatant.get_starting_orbs()
			enemyCombatant1.combatant.assign_moves_nonplayer()
			
			var rngBeginnerNoEnemy: float = randf() - 0.5 + \
					(0.1 * (max(playerCombatant.combatant.stats.level, MIN_LV_TWO_ENEMIES) - MIN_LV_TWO_ENEMIES)) if playerCombatant.combatant.stats.level < MAX_LV_TWO_ENEMIES else 1.0
			# if 4 < level < 8, give a 50% chance to have a second combatant + 10% per level up to 90% at lv 7, before team table calc
			var eCombatant2Idx: int = WeightedThing.pick_item(randomEncounter.combatant2Options)
			if eCombatant2Idx > -1 and randomEncounter.combatant2Options[eCombatant2Idx].combatant != null and rngBeginnerNoEnemy > 0.5:
				# load enemy 2
				var combatantOption: WeightedCombatant = randomEncounter.combatant2Options[eCombatant2Idx] 
				enemyCombatant2.combatant = combatantOption.combatant.copy().initialize()
				if combatantOption.weightedEquipment != null and len(combatantOption.weightedEquipment.weightedEquipment) > 0:
					var equipmentIdx: int = WeightedThing.pick_item(combatantOption.weightedEquipment.weightedEqiupment)
					if equipmentIdx > -1:
						enemyCombatant2.combatant.stats.equippedArmor = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].armor
						enemyCombatant2.combatant.stats.equippedWeapon = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].weapon
				else:
					enemyCombatant2.combatant.pick_equipment()
				if enemyCombatant2.combatant.get_evolution() != null:
					enemyCombatant2.combatant.switch_evolution(enemyCombatant2.combatant.get_evolution(), null)
				enemyCombatant2.initialCombatantLv = enemyCombatant2.combatant.stats.level
				enemyCombatant2.combatant.level_up_nonplayer(randomEncounter.get_combatant_level(), combatantOption.statAllocationStrategy)
				enemyCombatant2.combatant.orbs = enemyCombatant2.combatant.get_starting_orbs()
				enemyCombatant2.combatant.assign_moves_nonplayer()
			else:
				enemyCombatant2.combatant = null
			
			rngBeginnerNoEnemy = randf() - 0.5 + \
					(0.1 * (max(playerCombatant.combatant.stats.level, MIN_LV_THREE_ENEMIES) - MIN_LV_THREE_ENEMIES)) if playerCombatant.combatant.stats.level < MAX_LV_THREE_ENEMIES else 1.0
			# if level < 10, give a 0% chance to have a third combatant + 10% per level after 1 up to 100% at lv 20, before team table calc
			var eCombatant3Idx: int = WeightedThing.pick_item(randomEncounter.combatant3Options)
			if eCombatant3Idx > -1 and randomEncounter.combatant3Options[eCombatant3Idx].combatant != null and rngBeginnerNoEnemy > 0.5:
				# load enemy 3
				var combatantOption: WeightedCombatant = randomEncounter.combatant3Options[eCombatant3Idx]
				enemyCombatant3.combatant = combatantOption.combatant.copy().initialize()
				if combatantOption.weightedEquipment != null and len(combatantOption.weightedEquipment.weightedEquipment) > 0:
					var equipmentIdx: int = WeightedThing.pick_item(combatantOption.weightedEquipment.weightedEqiupment)
					if equipmentIdx > -1:
						enemyCombatant3.combatant.stats.equippedArmor = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].armor
						enemyCombatant3.combatant.stats.equippedWeapon = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].weapon
				else:
					enemyCombatant3.combatant.pick_equipment()
				if enemyCombatant3.combatant.get_evolution() != null:
					enemyCombatant3.combatant.switch_evolution(enemyCombatant3.combatant.get_evolution(), null)
				enemyCombatant3.combatant.level_up_nonplayer(randomEncounter.get_combatant_level(), combatantOption.statAllocationStrategy)
				enemyCombatant3.initialCombatantLv = enemyCombatant3.combatant.stats.level
				enemyCombatant3.combatant.orbs = enemyCombatant3.combatant.get_starting_orbs()
				enemyCombatant3.combatant.assign_moves_nonplayer()
			else:
				enemyCombatant3.combatant = null
			#enemyCombatant3.leftSide = false # what was this doing????
	else: # loaded a battle already in progress
		playerCombatant.combatant = state.playerCombatant
		minionCombatant.combatant = state.minionCombatant
		enemyCombatant1.combatant = state.enemyCombatant1
		enemyCombatant2.combatant = state.enemyCombatant2
		enemyCombatant3.combatant = state.enemyCombatant3
		
	playerCombatant.leftSide = true
	playerCombatant.spriteFacesRight = playerCombatant.combatant.get_faces_right()
	playerCombatant.role = CombatantNode.Role.ALLY
	
	minionCombatant.leftSide = true
	if minionCombatant.combatant != null:
		minionCombatant.spriteFacesRight = minionCombatant.combatant.get_faces_right()
	minionCombatant.role = CombatantNode.Role.ALLY
	
	enemyCombatant1.role = CombatantNode.Role.ENEMY
	enemyCombatant1.spriteFacesRight = enemyCombatant1.combatant.get_faces_right()
	enemyCombatant2.role = CombatantNode.Role.ENEMY
	if enemyCombatant2.combatant != null:
		enemyCombatant2.spriteFacesRight = enemyCombatant2.combatant.get_faces_right()
	enemyCombatant3.role = CombatantNode.Role.ENEMY
	if enemyCombatant3.combatant != null:
		enemyCombatant3.spriteFacesRight = enemyCombatant3.combatant.get_faces_right()
	
	battleUI.commandingMinion = state.commandingMinion
	battleUI.prevMenu = state.prevMenu
	
	for node in combatantNodes:
		node.load_combatant_node()
	
	combatantGroup.reparent(tilemap)
	update_combatant_focus_neighbors()
	
	if state.menu == BattleState.Menu.SUMMON and \
			(PlayerResources.inventory.count_of(Item.Type.SHARD) == 0 or hasStaticMinion \
				or PlayerResources.playerInfo.encounter.has_special_rule(EnemyEncounter.SpecialRules.NO_SUMMONS) \
			):
		state.menu = BattleState.Menu.PRE_BATTLE
	
	shadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	shadeTween.tween_property(shade, 'modulate', Color(1, 1, 1, 0), 0.5)
	shadeTween.finished.connect(_fade_in_finish)
	battleUI.set_menu_state(state.menu, false)
	SaveHandler.save_data()
	
func summon_minion(minionName: String, shard: Item = null):
	state.usedShard = shard
	minionCombatant.combatant = PlayerResources.minions.get_minion(minionName)
	minionCombatant.spriteFacesRight = minionCombatant.combatant.get_faces_right()
	minionCombatant.initialCombatantLv = minionCombatant.combatant.stats.level
	minionCombatant.combatant.orbs = minionCombatant.combatant.get_starting_orbs()
	minionCombatant.load_combatant_node()
	#minionCombatant.combatant.currentHp = minionCombatant.combatant.stats.maxHp # just in case
	var preset: ParticlePreset = preload("res://gamedata/moves/particles_shard.tres")
	minionCombatant.play_particles(preset)

func get_all_combatant_nodes() -> Array[CombatantNode]:
	var allCombatantNodes: Array[CombatantNode] = []
	for node in combatantNodes:
		allCombatantNodes.append(node as CombatantNode)
	return allCombatantNodes

func save_data(save_path):
	if battleEnded:
		state.delete_data(SaveHandler.get_save_file_location('save')) # same as save_path in save/load data functions
	else:
		state.menu = battleUI.menuState
		state.prevMenu = battleUI.prevMenu
		state.playerCombatant = playerCombatant.combatant
		state.minionCombatant = minionCombatant.combatant
		state.enemyCombatant1 = enemyCombatant1.combatant
		state.enemyCombatant2 = enemyCombatant2.combatant
		state.enemyCombatant3 = enemyCombatant3.combatant
		state.commandingMinion = battleUI.commandingMinion
		state.fobButtonEnabled = battlePanels.flowOfBattle.get_fob_button_enabled()
		state.battleMapPath = battleMapPath
		if state.battleMusic == null:
			state.battleMusic = SceneLoader.audioHandler.get_cur_music()
		state.turnList = turnExecutor.turnQueue.combatants.duplicate(false)
		state.save_data(save_path, state)

func load_data(save_path):
	var newState = state.load_data(save_path)
	if newState != null:
		state = newState
		battleMapPath = state.battleMapPath
		battlePanels.flowOfBattle.set_fob_button_enabled(state.fobButtonEnabled)
		turnExecutor.turnQueue = TurnQueue.new(state.turnList, false)
		if not battleLoaded:
			battleLoaded = true
			SceneLoader.audioHandler.play_music(state.battleMusic, -1)

func update_combatant_focus_neighbors():
	if enemyCombatant3.is_alive():
		playerCombatant.set_focus_right_combatant_node_neighbor(enemyCombatant3)
		enemyCombatant3.set_focus_left_combatant_node_neighbor(playerCombatant)
		
	if enemyCombatant2.is_alive():
		playerCombatant.set_focus_right_combatant_node_neighbor(enemyCombatant2)
		enemyCombatant2.set_focus_left_combatant_node_neighbor(playerCombatant)
	
	if enemyCombatant1.is_alive():
		playerCombatant.set_focus_right_combatant_node_neighbor(enemyCombatant1)
		enemyCombatant1.set_focus_left_combatant_node_neighbor(playerCombatant)
		enemyCombatant2.set_focus_bottom_combatant_node_neighbor(enemyCombatant1)
		enemyCombatant3.set_focus_top_combatant_node_neighbor(enemyCombatant1)
	else:
		enemyCombatant2.set_focus_bottom_combatant_node_neighbor(enemyCombatant3)
		enemyCombatant3.set_focus_top_combatant_node_neighbor(enemyCombatant2)
	
	if minionCombatant.is_alive():
		minionCombatant.set_focus_bottom_combatant_node_neighbor(playerCombatant)
		playerCombatant.set_focus_top_combatant_node_neighbor(minionCombatant)
		
func get_top_most_targetable_combatant_nodes() -> Array[CombatantNode]:
	var nodes: Array[CombatantNode] = []
	if minionCombatant.is_alive() and minionCombatant.selectCombatantBtn.visible:
		nodes.append(minionCombatant)
	else:
		nodes.append(playerCombatant)
		
	if enemyCombatant2.is_alive() and enemyCombatant2.selectCombatantBtn.visible:
		nodes.append(enemyCombatant2)
	elif enemyCombatant1.is_alive() and enemyCombatant1.selectCombatantBtn.visible:
		nodes.append(enemyCombatant1)
	elif enemyCombatant3.is_alive() and enemyCombatant3.selectCombatantBtn.visible:
		nodes.append(enemyCombatant3)
	return nodes

func get_bottom_most_targetable_combatant_nodes() -> Array[CombatantNode]:
	var nodes: Array[CombatantNode] = []
	if playerCombatant.is_alive() and playerCombatant.selectCombatantBtn.visible:
		nodes.append(playerCombatant)
	else:
		nodes.append(minionCombatant)
		
	if enemyCombatant3.is_alive() and enemyCombatant3.selectCombatantBtn.visible:
		nodes.append(enemyCombatant3)
	elif enemyCombatant1.is_alive() and enemyCombatant1.selectCombatantBtn.visible:
		nodes.append(enemyCombatant1)
	elif enemyCombatant2.is_alive() and enemyCombatant2.selectCombatantBtn.visible:
		nodes.append(enemyCombatant2)
	return nodes

func reset_intermediate_state_strs():
	state.calcdStateStrings = []
	state.calcdStateIndex = 0

func end_battle():
	PlayerResources.copy_combatant_to_info(PlayerResources.playerInfo.combatant)
	battleEnded = true
	PlayerResources.playerInfo.combatant.statChanges.reset()
	PlayerResources.playerInfo.combatant.statusEffect = null # clear status after battle (?)
	for combatantNode: CombatantNode in combatantNodes:
		if combatantNode.combatant != null and combatantNode.role == CombatantNode.Role.ENEMY:
			PlayerResources.playerInfo.set_enemy_defeated(combatantNode.combatant.save_name())
	
	if minionCombatant.combatant != null:
		#if not minionCombatant.combatant.downed and state.usedShard != null: # credit back used shard if the minion wasn't downed
			#PlayerResources.inventory.add_item(state.usedShard)
		PlayerResources.minions.add_friendship(minionCombatant.combatant.save_name(), minionCombatant.combatant.downed)
		minionCombatant.combatant.currentHp = minionCombatant.combatant.stats.maxHp # reset to max HP for next time minion will be summoned
		minionCombatant.combatant.downed = false # clear downed if it was downed
		minionCombatant.combatant.statChanges.reset()
		minionCombatant.combatant.statusEffect = null # clear status after battle (?)
	shadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	shadeTween.tween_property(shade, 'modulate', Color(1, 1, 1, 1), 0.5)
	shadeTween.finished.connect(_fade_out_finish)

func _fade_in_finish():
	pass

func _fade_out_finish():
	PlayerResources.playerInfo.encounter = null # clear encounter so other things can't trigger it
	SaveHandler.save_data('save')
	SceneLoader.audioHandler.fade_out_music()
	await SceneLoader.audioHandler.music_fade_completed
	tilemap.queue_free() # free tilemap first to avoid tilemap nav layer errors
	SceneLoader.load_overworld('save')
