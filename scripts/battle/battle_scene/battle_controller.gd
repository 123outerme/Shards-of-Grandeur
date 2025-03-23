extends Node2D
class_name BattleController

 # below this level, 2 enemies cannot spawn from a random battle
const MIN_LV_TWO_ENEMIES = 4
# above this level, the chance to spawn 2 enemies is not modified
const MAX_LV_TWO_ENEMIES = 8
# below this level, 3 enemies cannot spawn from a random battle
const MIN_LV_THREE_ENEMIES = 10
# above this level, the chance to spawn 3 enemies is not modified
const MAX_LV_THREE_ENEMIES = 20

const shardParticlePreset: ParticlePreset = preload("res://gamedata/moves/particles_shard.tres")

@export var state: BattleState = BattleState.new()
@export var globalMarker: Marker2D

var battleLoaded: bool = false
var battleEnded: bool = false

@onready var tilemapParent: Node2D = get_node_or_null('TileMapParent')
var tilemap: Node2D = null
var battleMapPath: String = ''

@onready var battleAnimationManager: BattleAnimationManager = get_node('BattleAnimationManager')
@onready var playerCombatant: CombatantNode = get_node_or_null("BattleAnimationManager/PlayerCombatant")
@onready var minionCombatant: CombatantNode = get_node_or_null("BattleAnimationManager/MinionCombatant")
@onready var enemyCombatant1: CombatantNode = get_node_or_null("BattleAnimationManager/EnemyCombatant1")
@onready var enemyCombatant2: CombatantNode = get_node_or_null("BattleAnimationManager/EnemyCombatant2")
@onready var enemyCombatant3: CombatantNode = get_node_or_null("BattleAnimationManager/EnemyCombatant3")

@onready var battleUI: BattleUI = get_node_or_null("BattleCam")
@onready var battlePanels: BattlePanels = get_node_or_null("BattleCam/UIPanels")
@onready var turnExecutor: TurnExecutor = get_node_or_null("TurnExecutor")
@onready var shade: ColorRect = get_node_or_null('Shade')

var shadeTween: Tween = null
var battlefieldShadeTween: Tween = null
var battlefieldShadeAnim: BattlefieldShadeAnim = null

var battleMapsDir: String = 'res://prefabs/battle/battle_maps/'

# Called when the node enters the scene tree for the first time.
func _ready():
	shade.visible = true
	playerCombatant.leftSide = true
	playerCombatant.role = CombatantNode.Role.ALLY
	
	minionCombatant.leftSide = true
	minionCombatant.role = CombatantNode.Role.ALLY
	
	enemyCombatant1.role = CombatantNode.Role.ENEMY
	enemyCombatant2.role = CombatantNode.Role.ENEMY
	enemyCombatant3.role = CombatantNode.Role.ENEMY
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
	if state != null and state.battleMapPath != '':
		battleMapPath = state.battleMapPath
	if PlayerResources.playerInfo.encounter != null:
		if PlayerResources.playerInfo.encounter.battleMapPath != '':
			battleMapPath = MapEntry.get_battle_map_scene_path(PlayerResources.playerInfo.encounter.battleMapPath)
	var battleMap = load(battleMapPath)
	tilemap = battleMap.instantiate()
	tilemapParent.add_child(tilemap)
	
	var newBattle: bool = state.enemyCombatant1 == null
	var hasStaticMinion: bool = false
	if newBattle: # new battle
		playerCombatant.combatant = PlayerResources.playerInfo.combatant.copy()
		playerCombatant.combatant.orbs = playerCombatant.combatant.get_starting_orbs()
		playerCombatant.combatant.update_battle_storage()
		minionCombatant.combatant = null
		# load enemy 1 (always defined statically)
		enemyCombatant1.combatant = PlayerResources.playerInfo.encounter.combatant1.copy().initialize()
		# if static encounter:
		if PlayerResources.playerInfo.encounter is StaticEncounter:
			var staticEncounter: StaticEncounter = PlayerResources.playerInfo.encounter as StaticEncounter
			enemyCombatant1.combatant.stats.equippedArmor = staticEncounter.combatant1Armor
			enemyCombatant1.combatant.stats.equippedWeapon = staticEncounter.combatant1Weapon
			enemyCombatant1.combatant.stats.equippedAccessory = staticEncounter.combatant1Accessory
			# stats start out in base form, this will evolve the combatant
			if enemyCombatant1.combatant.get_evolution() != null:
				enemyCombatant1.combatant.switch_evolution(enemyCombatant1.combatant.get_evolution(), null)
			
			if staticEncounter.combatant1Ai != null:
				enemyCombatant1.battleAi = staticEncounter.combatant1Ai.copy()
			else:
				enemyCombatant1.battleAi = staticEncounter.combatant1.get_ai().copy()
			enemyCombatant1.initialCombatantLv = enemyCombatant1.combatant.stats.level
			enemyCombatant1.combatant.level_up_nonplayer(staticEncounter.combatant1Level, staticEncounter.combatant1StatAllocStrat)
			enemyCombatant1.combatant.orbs = enemyCombatant1.combatant.get_starting_orbs()
			if len(staticEncounter.combatant1Moves) == 0:
				enemyCombatant1.combatant.assign_moves_nonplayer()
			else:
				enemyCombatant1.combatant.stats.moves = staticEncounter.combatant1Moves.duplicate()
			enemyCombatant1.shardSummoned = staticEncounter.combatant1ShardSummoned
			
			if staticEncounter.combatant2 != null:
				enemyCombatant2.combatant = staticEncounter.combatant2.copy().initialize()
				enemyCombatant2.combatant.stats.equippedArmor = staticEncounter.combatant2Armor
				enemyCombatant2.combatant.stats.equippedWeapon = staticEncounter.combatant2Weapon
				enemyCombatant2.combatant.stats.equippedAccessory = staticEncounter.combatant2Accessory
				# stats start out in base form, this will evolve the combatant
				if enemyCombatant2.combatant.get_evolution() != null:
					enemyCombatant2.combatant.switch_evolution(enemyCombatant2.combatant.get_evolution(), null)
				if staticEncounter.combatant2Ai != null:
					enemyCombatant2.battleAi = staticEncounter.combatant2Ai.copy()
				else:
					enemyCombatant2.battleAi = staticEncounter.combatant2.get_ai().copy()
				enemyCombatant2.initialCombatantLv = enemyCombatant2.combatant.stats.level
				enemyCombatant2.combatant.level_up_nonplayer(staticEncounter.combatant2Level, staticEncounter.combatant2StatAllocStrat)
				enemyCombatant2.combatant.orbs = enemyCombatant2.combatant.get_starting_orbs()
				if len(staticEncounter.combatant2Moves) == 0:
					enemyCombatant2.combatant.assign_moves_nonplayer()
				else:
					enemyCombatant2.combatant.stats.moves = staticEncounter.combatant2Moves.duplicate()
				enemyCombatant2.shardSummoned = staticEncounter.combatant2ShardSummoned
			
			if staticEncounter.combatant3 != null:
				enemyCombatant3.combatant = staticEncounter.combatant3.copy().initialize()
				enemyCombatant3.combatant.stats.equippedArmor = staticEncounter.combatant3Armor
				enemyCombatant3.combatant.stats.equippedWeapon = staticEncounter.combatant3Weapon
				enemyCombatant3.combatant.stats.equippedAccessory = staticEncounter.combatant3Accessory
				if enemyCombatant3.combatant.get_evolution() != null:
					enemyCombatant3.combatant.switch_evolution(enemyCombatant3.combatant.get_evolution(), null)
				if staticEncounter.combatant3Ai != null:
					enemyCombatant3.battleAi = staticEncounter.combatant3Ai.copy()
				else:
					enemyCombatant3.battleAi = staticEncounter.combatant3.get_ai().copy()
				enemyCombatant3.initialCombatantLv = enemyCombatant3.combatant.stats.level
				enemyCombatant3.combatant.level_up_nonplayer(staticEncounter.combatant3Level, staticEncounter.combatant3StatAllocStrat)
				enemyCombatant3.combatant.orbs = enemyCombatant3.combatant.get_starting_orbs()
				if len(staticEncounter.combatant3Moves) == 0:
					enemyCombatant3.combatant.assign_moves_nonplayer()
				else:
					enemyCombatant3.combatant.stats.moves = staticEncounter.combatant3Moves.duplicate()
				enemyCombatant3.shardSummoned = staticEncounter.combatant3ShardSummoned
			
			if staticEncounter.autoAlly != null:
				hasStaticMinion = true
				minionCombatant.combatant = staticEncounter.autoAlly.copy().initialize()
				minionCombatant.combatant.stats.equippedArmor = staticEncounter.autoAllyArmor
				minionCombatant.combatant.stats.equippedWeapon = staticEncounter.autoAllyWeapon
				minionCombatant.combatant.stats.equippedAccessory = staticEncounter.autoAllyAccessory
				if minionCombatant.combatant.get_evolution() != null:
					minionCombatant.combatant.switch_evolution(minionCombatant.combatant.get_evolution(), null)
				minionCombatant.initialCombatantLv = minionCombatant.combatant.stats.level
				minionCombatant.combatant.level_up_nonplayer(staticEncounter.autoAllyLevel, staticEncounter.autoAllyStatAllocStrat)
				minionCombatant.combatant.orbs = minionCombatant.combatant.get_starting_orbs()
				if len(staticEncounter.autoAllyMoves) == 0:
					minionCombatant.combatant.assign_moves_nonplayer()
				else:
					minionCombatant.combatant.stats.moves = staticEncounter.autoAllyMoves.duplicate() 
				minionCombatant.shardSummoned = staticEncounter.autoAllyShardSummoned
		else:
			var randomEncounter: RandomEncounter = PlayerResources.playerInfo.encounter as RandomEncounter
			if randomEncounter.combatant1Equipment != null:
				var equipmentIdx: int = WeightedThing.pick_item(randomEncounter.combatant1Equipment.weightedEquipment)
				if equipmentIdx > -1:
					enemyCombatant1.combatant.stats.equippedArmor = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].armor
					enemyCombatant1.combatant.stats.equippedWeapon = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].weapon
					enemyCombatant1.combatant.stats.equippedAccessory = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].accessory
			else:
				enemyCombatant1.combatant.pick_equipment()
			
			if randomEncounter.combatant1Armor != null:
				enemyCombatant1.combatant.stats.equippedArmor = randomEncounter.combatant1Armor
			if randomEncounter.combatant1Weapon != null:
				enemyCombatant1.combatant.stats.equippedWeapon = randomEncounter.combatant1Weapon
			if randomEncounter.combatant1Accessory != null:
				enemyCombatant1.combatant.stats.equippedAccessory = randomEncounter.combatant1Accessory
				
			if enemyCombatant1.combatant.get_evolution() != null:
				enemyCombatant1.combatant.switch_evolution(enemyCombatant1.combatant.get_evolution(), null)
			enemyCombatant1.battleAi = enemyCombatant1.combatant.get_ai().copy()
			enemyCombatant1.initialCombatantLv = enemyCombatant1.combatant.stats.level
			enemyCombatant1.combatant.level_up_nonplayer(randomEncounter.get_combatant_level(), randomEncounter.combatant1StatAllocStrat)
			enemyCombatant1.combatant.orbs = enemyCombatant1.combatant.get_starting_orbs()
			enemyCombatant1.combatant.assign_moves_nonplayer()
			
			enemyCombatant2.combatant = null
			var combatant2StatAllocStrat: StatAllocationStrategy = null
			if PlayerResources.playerInfo.get_spawns_three_face_combatant():
				enemyCombatant2.combatant = randomEncounter.combatant1.copy().initialize()
				combatant2StatAllocStrat = randomEncounter.combatant1StatAllocStrat 
				if randomEncounter.combatant1Equipment != null:
					var equipmentIdx: int = WeightedThing.pick_item(randomEncounter.combatant1Equipment.weightedEquipment)
					if equipmentIdx > -1:
						enemyCombatant2.combatant.stats.equippedArmor = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].armor
						enemyCombatant2.combatant.stats.equippedWeapon = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].weapon
						enemyCombatant2.combatant.stats.equippedAccessory = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].accessory
				else:
					enemyCombatant2.combatant.pick_equipment()
				# override random equipment with static equipment (intended for use in making combatant1 a specific evolution):
				if randomEncounter.combatant1Armor != null:
					enemyCombatant2.combatant.stats.equippedArmor = randomEncounter.combatant1Armor
				if randomEncounter.combatant1Weapon != null:
					enemyCombatant2.combatant.stats.equippedWeapon = randomEncounter.combatant1Weapon
				if randomEncounter.combatant1Weapon != null:
					enemyCombatant2.combatant.stats.equippedAccessory = randomEncounter.combatant1Accessory
			else:
				var rngBeginnerNoEnemy: float = randf() - 0.5 + \
						(0.1 * (max(playerCombatant.combatant.stats.level, MIN_LV_TWO_ENEMIES) - MIN_LV_TWO_ENEMIES)) if playerCombatant.combatant.stats.level < MAX_LV_TWO_ENEMIES else 1.0
				# if 4 < level < 8, give a 50% chance to have a second combatant + 10% per level up to 90% at lv 7, before team table calc
				var eCombatant2Idx: int = WeightedThing.pick_item(randomEncounter.combatant2Options)
				if eCombatant2Idx > -1 and randomEncounter.combatant2Options[eCombatant2Idx].combatant != null and rngBeginnerNoEnemy > 0.5:
					# load enemy 2
					var combatantOption: WeightedCombatant = randomEncounter.combatant2Options[eCombatant2Idx] 
					enemyCombatant2.combatant = combatantOption.combatant.copy().initialize()
					combatant2StatAllocStrat = combatantOption.statAllocationStrategy
					if combatantOption.weightedEquipment != null and len(combatantOption.weightedEquipment.weightedEquipment) > 0:
						var equipmentIdx: int = WeightedThing.pick_item(combatantOption.weightedEquipment.weightedEquipment)
						if equipmentIdx > -1:
							enemyCombatant2.combatant.stats.equippedArmor = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].armor
							enemyCombatant2.combatant.stats.equippedWeapon = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].weapon
							enemyCombatant2.combatant.stats.equippedAccessory = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].accessory
						else:
							enemyCombatant2.combatant.pick_equipment()
			if enemyCombatant2.combatant != null:
				if enemyCombatant2.combatant.get_evolution() != null:
					enemyCombatant2.combatant.switch_evolution(enemyCombatant2.combatant.get_evolution(), null)
				enemyCombatant2.battleAi = enemyCombatant2.combatant.get_ai().copy()
				enemyCombatant2.initialCombatantLv = enemyCombatant2.combatant.stats.level
				enemyCombatant2.combatant.level_up_nonplayer(randomEncounter.get_combatant_level(), combatant2StatAllocStrat)
				enemyCombatant2.combatant.orbs = enemyCombatant2.combatant.get_starting_orbs()
				enemyCombatant2.combatant.assign_moves_nonplayer()
			
			enemyCombatant3.combatant = null
			var combatant3StatAllocStrat: StatAllocationStrategy = null
			if PlayerResources.playerInfo.get_spawns_three_face_combatant():
				enemyCombatant3.combatant = randomEncounter.combatant1.copy().initialize()
				combatant3StatAllocStrat = randomEncounter.combatant1StatAllocStrat 
				if randomEncounter.combatant1Equipment != null:
					var equipmentIdx: int = WeightedThing.pick_item(randomEncounter.combatant1Equipment.weightedEquipment)
					if equipmentIdx > -1:
						enemyCombatant3.combatant.stats.equippedArmor = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].armor
						enemyCombatant3.combatant.stats.equippedWeapon = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].weapon
						enemyCombatant3.combatant.stats.equippedAccessory = randomEncounter.combatant1Equipment.weightedEquipment[equipmentIdx].accessory
				else:
					enemyCombatant3.combatant.pick_equipment()
				# override random equipment with static equipment (intended for use in making combatant1 a specific evolution):
				if randomEncounter.combatant1Armor != null:
					enemyCombatant3.combatant.stats.equippedArmor = randomEncounter.combatant1Armor
				if randomEncounter.combatant1Weapon != null:
					enemyCombatant3.combatant.stats.equippedWeapon = randomEncounter.combatant1Weapon
				if randomEncounter.combatant1Weapon != null:
					enemyCombatant3.combatant.stats.equippedAccessory = randomEncounter.combatant1Accessory
			else:
				var rngBeginnerNoEnemy: float = randf() - 0.5 + \
						(0.1 * (max(playerCombatant.combatant.stats.level, MIN_LV_THREE_ENEMIES) - MIN_LV_THREE_ENEMIES)) if playerCombatant.combatant.stats.level < MAX_LV_THREE_ENEMIES else 1.0
				# if level < 10, give a 0% chance to have a third combatant + 10% per level after 1 up to 100% at lv 20, before team table calc
				var eCombatant3Idx: int = WeightedThing.pick_item(randomEncounter.combatant3Options)
				if eCombatant3Idx > -1 and randomEncounter.combatant3Options[eCombatant3Idx].combatant != null and rngBeginnerNoEnemy > 0.5:
					# load enemy 3
					var combatantOption: WeightedCombatant = randomEncounter.combatant3Options[eCombatant3Idx]
					enemyCombatant3.combatant = combatantOption.combatant.copy().initialize()
					combatant3StatAllocStrat = combatantOption.statAllocationStrategy
					if combatantOption.weightedEquipment != null and len(combatantOption.weightedEquipment.weightedEquipment) > 0:
						var equipmentIdx: int = WeightedThing.pick_item(combatantOption.weightedEquipment.weightedEquipment)
						if equipmentIdx > -1:
							enemyCombatant3.combatant.stats.equippedArmor = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].armor
							enemyCombatant3.combatant.stats.equippedWeapon = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].weapon
							enemyCombatant3.combatant.stats.equippedAccessory = combatantOption.weightedEquipment.weightedEquipment[equipmentIdx].accessory
					else:
						enemyCombatant3.combatant.pick_equipment()
			if enemyCombatant3.combatant != null:
				if enemyCombatant3.combatant.get_evolution() != null:
					enemyCombatant3.combatant.switch_evolution(enemyCombatant3.combatant.get_evolution(), null)
				enemyCombatant3.battleAi = enemyCombatant3.combatant.get_ai().copy()
				enemyCombatant3.combatant.level_up_nonplayer(randomEncounter.get_combatant_level(), combatant3StatAllocStrat)
				enemyCombatant3.initialCombatantLv = enemyCombatant3.combatant.stats.level
				enemyCombatant3.combatant.orbs = enemyCombatant3.combatant.get_starting_orbs()
				enemyCombatant3.combatant.assign_moves_nonplayer()
		if minionCombatant.combatant != null:
			minionCombatant.combatant.update_battle_storage()
		enemyCombatant1.combatant.update_battle_storage()
		if enemyCombatant2.combatant != null:
			enemyCombatant2.combatant.update_battle_storage()
		if enemyCombatant3.combatant != null:
			enemyCombatant3.combatant.update_battle_storage()
			#enemyCombatant3.leftSide = false # what was this doing????
	else: # loaded a battle already in progress
		playerCombatant.combatant = state.playerCombatant
		minionCombatant.combatant = state.minionCombatant
		enemyCombatant1.combatant = state.enemyCombatant1
		enemyCombatant1.battleAi = state.enemyAi1
		if enemyCombatant1.battleAi == null and enemyCombatant1.combatant != null and enemyCombatant1.combatant.get_ai() != null: # failsafe: copy AI from the combatant
			enemyCombatant1.battleAi = enemyCombatant1.combatant.get_ai().copy()
		enemyCombatant2.combatant = state.enemyCombatant2
		enemyCombatant2.battleAi = state.enemyAi2
		if enemyCombatant2.battleAi == null and enemyCombatant2.combatant != null and enemyCombatant2.combatant.get_ai() != null: # failsafe: copy AI from the combatant
			enemyCombatant2.battleAi = enemyCombatant2.combatant.get_ai().copy()
		enemyCombatant3.combatant = state.enemyCombatant3
		enemyCombatant3.battleAi = state.enemyAi3
		if enemyCombatant3.battleAi == null and enemyCombatant3.combatant != null and enemyCombatant3.combatant.get_ai() != null: # failsafe: copy AI from the combatant
			enemyCombatant3.battleAi = enemyCombatant3.combatant.get_ai().copy()
		# update escape/win state (in case we're loading in BATTLE_COMPLETE)
		if state.playerEscaped:
			battleUI.escapes = true
			battleUI.battleComplete.playerEscapes = true
			battleUI.playerWins = false
			battleUI.battleComplete.playerWins = false
		else:
			battleUI.escapes = false
			battleUI.battleComplete.playerEscapes = false
			battleUI.playerWins =  PlayerResources.playerInfo.encounter.get_win_con_result(get_all_combatant_nodes(), state) == WinCon.TurnResult.PLAYER_WIN
			battleUI.battleComplete.playerWins = battleUI.playerWins
	
	battleUI.commandingMinion = state.commandingMinion
	battleUI.prevMenu = state.prevMenu
	battlePanels.set_turn_counter(state.turnNumber, PlayerResources.playerInfo.encounter.winCon)
	
	for node in get_all_combatant_nodes():
		node.load_combatant_node()
		if node.shardSummoned:
			node.play_particles(shardParticlePreset)
		if PlayerResources.playerInfo.encounter.winCon != null and PlayerResources.playerInfo.encounter.winCon is WeakenEnemyWinCon:
			var weakenWinCon: WeakenEnemyWinCon = PlayerResources.playerInfo.encounter.winCon as WeakenEnemyWinCon
			if weakenWinCon.enemyPosition == node.battlePosition:
				node.set_weaken_target_hp_display(weakenWinCon.targetPercentHp)
	
	battleAnimationManager.reparent(tilemap)
	update_combatant_focus_neighbors()
	
	if state.menu == BattleState.Menu.SUMMON and \
			((PlayerResources.inventory.count_of(Item.Type.SHARD) == 0 and not PlayerResources.minions.has_fully_attuned_minion()) \
				or hasStaticMinion \
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
	clean_up_minion_combatant()
	minionCombatant.combatant.update_battle_storage()
	minionCombatant.shardSummoned = true
	minionCombatant.load_combatant_node()
	#minionCombatant.combatant.currentHp = minionCombatant.combatant.stats.maxHp # just in case
	minionCombatant.play_particles(shardParticlePreset)

func get_all_combatant_nodes() -> Array[CombatantNode]:
	return battleAnimationManager.get_all_combatant_nodes()

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
		state.enemyAi1 = enemyCombatant1.battleAi
		state.enemyAi2 = enemyCombatant2.battleAi
		state.enemyAi3 = enemyCombatant3.battleAi
		state.commandingMinion = battleUI.commandingMinion
		state.fobButtonEnabled = battlePanels.flowOfBattle.get_fob_button_enabled()
		state.battleMapPath = battleMapPath
		if state.battleMusic == null:
			state.battleMusic = SceneLoader.audioHandler.get_cur_music()
		state.playerEscaped = battleUI.escapes
		update_state_turn_list()
		state.save_data(save_path, state)

func load_data(save_path):
	var newState = state.load_data(save_path)
	if newState != null:
		state = newState
		battleMapPath = state.battleMapPath
		battlePanels.set_turn_counter(state.turnNumber, PlayerResources.playerInfo.encounter.winCon)
		battlePanels.flowOfBattle.set_fob_button_enabled(state.fobButtonEnabled)
		turnExecutor.turnQueue = TurnQueue.new(state.turnList, false)
		if not battleLoaded:
			battleLoaded = true
			SceneLoader.audioHandler.play_music(state.battleMusic, -1)

func update_state_turn_list() -> void:
	state.turnList = turnExecutor.turnQueue.combatants.duplicate(false)

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

func get_top_left_most_targetable_combatant_node() -> CombatantNode:
	if minionCombatant.is_alive() and minionCombatant.selectCombatantBtn.visible:
		return minionCombatant
	if playerCombatant.is_alive() and playerCombatant.selectCombatantBtn.visible:
		return playerCombatant

	if enemyCombatant2.is_alive() and enemyCombatant2.selectCombatantBtn.visible:
		return enemyCombatant2
	if enemyCombatant1.is_alive() and enemyCombatant1.selectCombatantBtn.visible:
		return enemyCombatant1
	if enemyCombatant3.is_alive() and enemyCombatant3.selectCombatantBtn.visible:
		return enemyCombatant3
	return null

func get_top_right_most_targetable_combatant_node() -> CombatantNode:
	if enemyCombatant2.is_alive() and enemyCombatant2.selectCombatantBtn.visible:
		return enemyCombatant2
	if enemyCombatant1.is_alive() and enemyCombatant1.selectCombatantBtn.visible:
		return enemyCombatant1
	if enemyCombatant3.is_alive() and enemyCombatant3.selectCombatantBtn.visible:
		return enemyCombatant3
	
	if minionCombatant.is_alive() and minionCombatant.selectCombatantBtn.visible:
		return minionCombatant
	if playerCombatant.is_alive() and playerCombatant.selectCombatantBtn.visible:
		return playerCombatant
	return null

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
	PlayerResources.playerInfo.combatant.battleStorageStatus = null
	PlayerResources.playerInfo.combatant.runes = []
	PlayerResources.playerInfo.combatant.triggeredRunes = []
	PlayerResources.playerInfo.combatant.triggeredRunesDmg = []
	PlayerResources.playerInfo.combatant.triggeredRunesStatus = []
	for combatantNode: CombatantNode in get_all_combatant_nodes():
		if combatantNode.combatant != null and combatantNode.role == CombatantNode.Role.ENEMY:
			PlayerResources.playerInfo.set_enemy_defeated(combatantNode.combatant.save_name())
			# if this creature is an evolution, set its save name as defeated as well.
			if combatantNode.combatant.get_evolution() != null:
				PlayerResources.playerInfo.set_enemy_defeated(combatantNode.combatant.get_evolution_save_name())
	clean_up_minion_combatant()
	if minionCombatant.combatant != null:
		minionCombatant.combatant.orbs = 0
		minionCombatant.combatant.update_battle_storage()
		PlayerResources.minions.add_friendship(minionCombatant.combatant.save_name(), minionCombatant.combatant.downed, PlayerResources.playerInfo.get_battle_attunement_modifier())
	if PlayerResources.playerInfo.encounter is RandomEncounter:
		PlayerResources.playerInfo.activeBattleModifierItems = []
	SceneLoader.audioHandler.fade_out_music()
	shadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	shadeTween.tween_property(shade, 'modulate', Color(1, 1, 1, 1), 0.5)
	shadeTween.finished.connect(_fade_out_finish)

func clean_up_minion_combatant() -> void:
	if minionCombatant.combatant != null:
		#if not minionCombatant.combatant.downed and state.usedShard != null: # credit back used shard if the minion wasn't downed
			#PlayerResources.inventory.add_item(state.usedShard)
		minionCombatant.combatant.currentHp = minionCombatant.combatant.stats.maxHp # reset to max HP for next time minion will be summoned
		minionCombatant.combatant.battleStorageHp = minionCombatant.combatant.stats.maxHp
		minionCombatant.combatant.downed = false # clear downed if it was downed
		minionCombatant.combatant.statChanges.reset()
		minionCombatant.combatant.statusEffect = null # clear status after battle (?)
		minionCombatant.combatant.runes = []
		minionCombatant.combatant.triggeredRunes = []
		minionCombatant.combatant.triggeredRunesDmg = []
		minionCombatant.combatant.triggeredRunesStatus = []
		minionCombatant.combatant.battleStorageStatus = null

func _fade_in_finish() -> void:
	shadeTween = null

func _fade_out_finish() -> void:
	PlayerResources.playerInfo.encounter = null # clear encounter so other things can't trigger it
	SaveHandler.save_data('save')
	if SceneLoader.audioHandler.fadingOutMusic:
		await SceneLoader.audioHandler.music_fade_completed
	tilemap.queue_free() # free tilemap first to avoid tilemap nav layer errors
	SceneLoader.load_overworld('save')
