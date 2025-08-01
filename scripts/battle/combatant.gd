extends Resource
class_name Combatant

enum AiType {
	NONE = 0,
	DAMAGE = 1,
	SUPPORT = 2,
	BUFFER = 3,
	DEBUFFER = 4,
}

enum AggroType {
	LOWEST_HP = 0,
	HIGHEST_HP = 1,
	MOST_ORBS = 2,
	HIGHEST_STATS = 3,
}

enum ResourceStrategy {
	GREEDY = 0,
	BIG_SPENDER = 1,
	BIG_SAVER = 2,
}

enum MinionStatAllocationMode {
	DEFAULT = -1,
	MANUAL = 0,
	AUTOMATIC = 1,
}

const HP_BAR_COLORS: Dictionary[String, Color] = {
	'full': Color(0, 0.870588, 0), #00de00
	'warn': Color(1, 0.717647, 0), #ffb700
	'low': Color(0.937255, 0, 0) #ef0000
}

const ELEMENT_EFFECTIVENESS_MULTIPLIERS: Dictionary[String, float] = {
	'superEffective': 1.5,
	'effective': 1,
	'resisted': 0.65
}

const STATUS_EFFECTIVENESS_MULTIPLIERS: Dictionary[String, float] = {
	'effective': 1,
	'resisted': 0.5,
	'immune': 0
}

const MAX_ORBS = 10

## sprite used to display the combatant
@export var sprite: CombatantSprite = null

@export_category("Combatant - Stats")

## nickname of the minion, overrides the display name
@export_storage var nickname: String = ''

## stats of the combatant
@export var stats: Stats = Stats.new()

## defines evolutions for the combatant
@export var evolutions: Evolutions = null

## stats for each evolution the combatant has
@export_storage var evolutionStats: Dictionary[String, Stats] = {}

## whether or not the minion should auto-allocate stat points
@export_storage var minionStatAllocMode: MinionStatAllocationMode = MinionStatAllocationMode.DEFAULT

## current HP
@export_storage var currentHp: int = -1

## current orbs in a battle
@export_storage var orbs: int = 0

## stat and element buffs/debuffs
@export var statChanges: StatChanges = StatChanges.new()

## the currently applied status effect in a battle
@export_storage var statusEffect: StatusEffect = null

## the currently applied Runes in a battle
@export_storage var runes: Array[Rune] = []

## the runes that have been currently triggered this battle step
@export_storage var triggeredRunes: Array[Rune] = []

@export_storage var triggeredRunesDmg: Array[int] = []

@export_storage var triggeredRunesStatus: Array[bool] = []

## how much Attunement the minion has
@export_storage var friendship: float = 0

## the amount of Attunement needed to reach max
@export var maxFriendship: float = 30

## if true, this minion can be summoned for free and can follow the player in the Overworld
@export var fullyAttuned: bool = false

## game version last saved on
@export_storage var version: String = ''

@export_category("Combatant - Encounter")

@export var ai: CombatantAi = null

## AI "combat role" type
@export var aiType: AiType = AiType.NONE

## AI targeting strategy
@export var damageAggroType: AggroType = AggroType.LOWEST_HP

## Orb spending strategy
@export var strategy: ResourceStrategy = ResourceStrategy.GREEDY

## if a random roll [0,1] hits below this amount, the AI will act "randomly"
@export var aiOverrideWeight: float = 0.35

## the effectiveness of elements/statuses on this combatant
@export var moveEffectiveness: MoveEffectiveness = null

## the equipment this enemy could spawn with
@export var weightedEquipment: CombatantEquipment = null

## the loot this enemy could drop
@export var dropTable: CombatantRewards = null

## the way this combatant allocates stat points automatically (enemy or auto-alloc minion)
@export var statAllocationStrategy: StatAllocationStrategy = null

#@export_category("Combatant - In Battle")
## the current command this combatant has entered for their battle turn
@export_storage var command: BattleCommand = null

## if true, this combatant cannot fight in the battle anymore
@export_storage var downed: bool = false

## these three are used for animating turn animations; they represent the state of the combatant before a command is issued
@export_storage var battleStorageHp: int = -1
@export_storage var battleStorageOrbs: int = -1
@export_storage var battleStorageStatus: StatusEffect = null

static var useSurgeReqs: StoryRequirements = load('res://gamedata/story_requirements/surge_move_reqs.tres') as StoryRequirements
static var runeReqs: StoryRequirements = load('res://gamedata/story_requirements/rune_reqs.tres') as StoryRequirements

static func load_combatant_resource(saveName: String) -> Combatant:
	var combatant: Combatant = load("res://gamedata/combatants/" + saveName + '/' + saveName + ".tres")
	if combatant != null:
		combatant = combatant.copy()
		combatant.initialize()
	else:
		printerr('Combatant.load_combatant_resource ERROR: combatant ', saveName, ' could not be loaded')
	return combatant

static func get_hp_bar_color(curHp: float, maxHp: float) -> Color:
	var hpRatio = curHp / maxHp
	if hpRatio >= 0.65:
		return HP_BAR_COLORS.full
	if hpRatio >= 0.35:
		return HP_BAR_COLORS.warn
	return HP_BAR_COLORS.low

static func are_surge_moves_allowed() -> bool:
	return useSurgeReqs != null and useSurgeReqs.is_valid() # if null, something went wrong that should be noticed...

static func are_runes_allowed() -> bool:
	return runeReqs == null or runeReqs.is_valid() # if null, I may have decided not to restrict runes by story requirements

func _init(
	i_nickname = '',
	i_stats = Stats.new(),
	i_evolutions = null,
	i_evolutionStats: Dictionary[String, Stats] = {},
	i_minionStatAllocMode: MinionStatAllocationMode = MinionStatAllocationMode.DEFAULT,
	i_curHp = -1,
	i_statChanges = StatChanges.new(),
	i_statusEffect = null,
	i_sprite = null,
	i_runes: Array[Rune] = [],
	i_triggeredRunes: Array[Rune] = [],
	i_triggeredRunesDmg: Array[int] = [],
	i_triggeredRunesStatus: Array[bool] = [],
	i_friendship = 0,
	i_maxFriendship: float = 30.0,
	i_fullyAttuned: bool = false,
	i_ai: CombatantAi = null,
	i_aiType = AiType.NONE,
	i_damageAggroType = AggroType.LOWEST_HP,
	i_overrideWeight = 0.35,
	i_moveEffectiveness = null,
	i_weightedEquipment = null,
	i_dropTable: CombatantRewards = null,
	i_statAllocStrat: StatAllocationStrategy = null,
	i_command = null,
	i_downed = false,
):
	nickname = i_nickname
	stats = i_stats
	if i_curHp != -1:
		currentHp = i_curHp
	else:
		currentHp = stats.maxHp
	evolutions = i_evolutions
	
	evolutionStats = i_evolutionStats
	
	minionStatAllocMode = i_minionStatAllocMode
	statChanges = i_statChanges
	statusEffect = i_statusEffect
	sprite = i_sprite
	ai = i_ai
	aiType = i_aiType
	damageAggroType = i_damageAggroType
	runes = i_runes
	triggeredRunes = i_triggeredRunes
	triggeredRunesDmg = i_triggeredRunesDmg
	triggeredRunesStatus = i_triggeredRunesStatus
	friendship = i_friendship
	maxFriendship = i_maxFriendship
	fullyAttuned = i_fullyAttuned
	aiOverrideWeight = i_overrideWeight
	moveEffectiveness = i_moveEffectiveness
	weightedEquipment = i_weightedEquipment
	dropTable = i_dropTable
	statAllocationStrategy = i_statAllocStrat
	command = i_command
	downed = i_downed

func initialize() -> Combatant:
	if currentHp == -1:
		stats.maxHp = stats.statGrowth.initialMaxHp
		currentHp = stats.maxHp # load max HP if combatant was loaded from resource
	if battleStorageHp == -1:
		battleStorageHp = currentHp
	if battleStorageOrbs == -1:
		battleStorageOrbs = orbs
	if battleStorageStatus == null:
		battleStorageStatus = statusEffect
	version = GameSettings.get_game_version()
	return self

func disp_name() -> String:
	if nickname != '':
		return nickname
	return stats.displayName

func save_name() -> String:
	return stats.saveName

func validate_evolution_stats():
	if evolutions != null:
		if evolutionStats.is_empty():
			# first index is base form stats
			#print('creating evolution stats obj for ', stats.displayName)
			evolutionStats['_base'] = stats
		for evolution: Evolution in evolutions.evolutionList:
			if not evolutionStats.has(evolution.evolutionSaveName):
				evolutionStats[evolution.evolutionSaveName] = evolution.stats.copy()

func get_evolution_stats_idx(evolution: Evolution) -> String:
	validate_evolution_stats()
	if evolutions == null or evolution == null:
		return '_base'
	return evolution.evolutionSaveName

func get_evolution_stats(evolution: Evolution) -> Stats:
	validate_evolution_stats()
	if evolutions == null or evolution == null or not evolutionStats.has(evolution.evolutionSaveName):
		return evolutionStats['_base']
	
	return evolutionStats[evolution.evolutionSaveName] as Stats

func get_evolution() -> Evolution:
	if evolutions != null:
		for evolution in evolutions.evolutionList:
			if evolution.combatant_can_evolve(self):
				return evolution
	return null

# null for base form, otherwise an Evolution
# returns 0b00000 if no lv/move changes were made
# adds 0b00001 if lv changed
# adds 0b00010 if movepool changed
# adds 0b00100 if some moves were found invalid (empty slots or not in the movepool)
# adds 0b01000 if ALL moves were found invalid
# adds 0b10000 if stat pts were automatically assigned
func switch_evolution(evolution: Evolution, prevEvolution: Evolution, isMinion: bool = false, overrideStatAllocStrat: StatAllocationStrategy = null) -> int:
	validate_evolution_stats()
	validate_all_evolutions_stat_totals()
	if evolutions == null:
		return 0
	# save the pre-switch stats back to the stats dict
	var returnCode: int = 0
	var prevNullMoves: int = validate_moves()
	var prevIdx: String = get_evolution_stats_idx(prevEvolution)
	evolutionStats[prevIdx] = stats
	stats = get_evolution_stats(evolution)
	
	if evolution != null:
		# if it's already found, nothing will be done
		PlayerResources.playerInfo.mark_evolution_found(save_name() + '#' + evolution.evolutionSaveName)
	
	# if this is a player evolution, keep learned moves and add moves granted by new evolution
	if save_name() == 'player' and evolution != null:
		# adjust movepool to be all learned moves (moves in base form), plus moves granted by this evolution
		print('adjust movepool for player evo')
		var movepool: MovePool = get_evolution_stats(null).movepool.copy()
		# for each move granted by this evolution, if not in the movepool, add it
		for move: Move in evolution.stats.movepool.pool:
			if not (move in movepool.pool):
				movepool.pool.append(move)
		stats.movepool = movepool
	
	# if this stats set is underlevelled, level it up now
	if stats.level < evolutionStats[prevIdx].level:
		stats.level_up(evolutionStats[prevIdx].level - stats.level)
		returnCode += 0b00001
	# change the current HP by keeping the same HP ratio
	var hpRatio: float = (currentHp as float) / evolutionStats[prevIdx].maxHp
	# don't gain any HP by switching forms
	currentHp = floori(hpRatio * stats.maxHp)
	# allocate stat points if set to do so
	if isMinion and should_auto_alloc_stat_pts():
		var statAllocStrat: StatAllocationStrategy = get_stat_allocation_strategy()
		if overrideStatAllocStrat != null:
			statAllocStrat = overrideStatAllocStrat
		if statAllocStrat != null:
			statAllocStrat.allocate_stats(stats)
			returnCode += 0b10000
	
	# copy over moves
	#stats.moves = evolutionStats[prevIdx].moves
	# copy over equipment
	stats.equippedArmor = evolutionStats[prevIdx].equippedArmor
	stats.equippedWeapon = evolutionStats[prevIdx].equippedWeapon
	stats.equippedAccessory = evolutionStats[prevIdx].equippedAccessory
	# if the movepool changed: alert the player
	if stats.movepool != evolutionStats[prevIdx].movepool:
		returnCode += 0b00010
	var nullMoves: int = validate_moves()
	# if any moves were invalidated, alert the user
	if prevNullMoves != nullMoves:
		returnCode += 0b00100
	# if all set moves were invalidated alert the user
	if nullMoves == Stats.MAX_MOVES:
		returnCode += 0b01000
	return returnCode

func validate_all_evolutions_stat_totals():
	validate_evolution_stats()
	for index in evolutionStats:
		var eStats: Stats = evolutionStats[index]
		if not eStats.is_stat_total_valid():
			#print('WARN: ', save_name(), ' evolution ', index, "'s stat total was invalid. Resetting.")
			eStats.reset_stat_points()

func reset_all_evolutions_stat_totals():
	stats.reset_stat_points()
	for index in evolutionStats:
		var eStats: Stats = evolutionStats[index]
		eStats.reset_stat_points()

func get_sprite_frames() -> SpriteFrames:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.spriteFrames
	return sprite.spriteFrames

func get_ai() -> CombatantAi:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.ai
	return ai

func get_ai_type() -> AiType:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.aiType
	return aiType

func get_aggro_type() -> AggroType:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.aggroType
	return damageAggroType

func get_resource_strategy() -> ResourceStrategy:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.strategy
	return strategy

func get_stat_allocation_strategy() -> StatAllocationStrategy:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.statAllocationStrategy
	return statAllocationStrategy

func get_drop_table() -> CombatantRewards:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.dropTable
	return dropTable

func get_sprite_obj() -> CombatantSprite:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite
	return sprite

func get_max_size() -> Vector2:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.maxSize
	return sprite.maxSize

func get_idle_size() -> Vector2:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.idleSize
	return sprite.idleSize

func get_center_pos() -> Vector2:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.centerPosition
	return sprite.centerPosition

func get_feet_pos() -> Vector2:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.feetPosition
	return sprite.feetPosition

func get_head_pos() -> Vector2:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.headPosition
	return sprite.headPosition

func get_faces_right() -> bool:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.spriteFacesRight
	return sprite.spriteFacesRight

func get_nav_layer() -> int:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.combatantSprite.navigationLayer
	return sprite.navigationLayer

func get_evolution_save_name() -> String:
	var evolution: Evolution = get_evolution()
	if evolution != null:
		return evolution.evolutionSaveName
	return save_name()

func update_downed():
	downed = currentHp <= 0

func get_exhaustion_level() -> StatusEffect.Potency:
	if statusEffect == null or statusEffect.type != StatusEffect.Type.EXHAUSTION:
		return StatusEffect.Potency.NONE # if no status or not exhaustion
	return statusEffect.potency # return exhaustion potency
	
func get_mania_level() -> StatusEffect.Potency:
	if statusEffect == null or statusEffect.type != StatusEffect.Type.MANIA:
		return StatusEffect.Potency.NONE # if no status or not exhaustion
	return statusEffect.potency # return manic potency

func would_item_have_effect(item: Item) -> bool:
	if item.itemType == Item.Type.HEALING:
		return currentHp < stats.maxHp
	if item is KeyItem:
		if item.get_as_subclass() is StatResetItem:
			return stats.statPts < stats.get_total_gained_stat_points()
		if item.get_as_subclass() is BattleModifierItem:
			return item.can_be_used_now()
	return true

func add_orbs(num: int):
	orbs = max(0, min(Combatant.MAX_ORBS, orbs + num)) # bounded [0,max]

func get_starting_orbs() -> int:
	var bonusOrbs: int = 0
	if stats.equippedWeapon != null:
		bonusOrbs += stats.equippedWeapon.bonusOrbs
	if stats.equippedArmor != null:
		bonusOrbs += stats.equippedArmor.bonusOrbs
	if stats.equippedAccessory != null:
		bonusOrbs += stats.equippedAccessory.bonusOrbs
	
	return max(0, min(Combatant.MAX_ORBS, bonusOrbs)) # bounded [0, max]

func update_runes(otherCombatants: Array[Combatant], battleState: BattleState, timing: BattleCommand.ApplyTiming) -> void:
	if timing == BattleCommand.ApplyTiming.BEFORE_ROUND or \
			timing == BattleCommand.ApplyTiming.AFTER_ROUND or \
			timing == BattleCommand.ApplyTiming.AFTER_POST_ROUND:
		# reset the list of triggered runes when appropriate (before each turn is handled by `update_battle_state()`)
		triggeredRunes = []
		triggeredRunesDmg = []
		triggeredRunesStatus = []
	
	var runesToCheck: bool = len(runes) > 0
	var firstCheck: bool = true
	while runesToCheck:
		if currentHp <= 0:
			runesToCheck = false
			break
		var runeWasTriggered: bool = false
		for runeIdx: int in range(len(runes)):
			var rune: Rune = runes[runeIdx]
			var triggers: bool = rune.does_rune_trigger(self, otherCombatants, battleState, timing, firstCheck)
			if triggers and not triggeredRunes.has(rune):
				apply_rune_effect(rune)
				runeWasTriggered = true
		for rune: Rune in triggeredRunes:
			runes.erase(rune) # erase triggered runes outside of the loop that's looping on `runes`
		
		if not runeWasTriggered or len(runes) == 0:
			runesToCheck = false
		firstCheck = false

func apply_rune_effect(rune: Rune) -> void:
	if rune == null:
		return

	triggeredRunes.append(rune)
	
	if rune.caster == null:
		printerr('HUGE ERROR in apply_rune_effect(): Rune does not have a caster')
		triggeredRunesDmg.append(0)
		triggeredRunesStatus.append(false)
		return

	rune.caster.add_orbs(rune.orbChange)
	
	var attackerStats: Stats = rune.caster.statChanges.apply(rune.caster.stats)
	var defenderStats: Stats = statChanges.apply(stats)
	
	var atkStat: float = attackerStats.get_stat_for_dmg_category(rune.category)
	var resStat: float = defenderStats.resistance
	
	var damageMultiplier: float = rune.caster.statChanges.get_element_multiplier(rune.element) * \
			get_element_effectiveness_multiplier(rune.element)
	
	var damage: int = BattleCommand.damage_formula(rune.power, atkStat, resStat, attackerStats.level, stats.level, damageMultiplier)
	
	if damage > 0:
		if rune.caster.currentHp > 0 and rune.lifesteal > 0: # if caster is still alive and this rune has lifesteal:
			var hpHealed: int = max(1, roundi(max(0, rune.lifesteal) * damage))
			rune.caster.currentHp = min(rune.caster.stats.maxHp, max(0, rune.caster.currentHp + hpHealed))
	if currentHp > 0: # if this combatant is still alive:
		currentHp = min(stats.maxHp, max(0, currentHp - damage))
	triggeredRunesDmg.append(damage)
	
	if rune.statChanges != null:
		statChanges.stack(rune.statChanges)
	
	var appliedStatus: bool = false
	if rune.statusEffect != null:
		if statusEffect == null or rune.statusEffect.overwritesOtherStatuses:
			BattleCommand.setup_status(rune.caster, self, rune.statusEffect, rune.power, rune.category, rune.element, [], damage)
			appliedStatus = true
	triggeredRunesStatus.append(appliedStatus)

func could_combatant_surge(effect: MoveEffect) -> bool:
	if effect.orbChange >= 0:
		return true # no cost required to charge orbs
	
	if Combatant.are_surge_moves_allowed():
		return false # AI can't use surge moves yet
	
	return effect.orbChange * -1 <= orbs

func get_move_effectiveness() -> MoveEffectiveness:
	var evolution: Evolution = get_evolution()
	if evolution == null:
		return moveEffectiveness
	else:
		return evolution.moveEffectiveness

func get_element_weaknesses() -> Array[Move.Element]:
	var weaknesses: Array[Move.Element] = []
	var effectiveness: MoveEffectiveness = get_move_effectiveness()
	
	if effectiveness != null:
		weaknesses.append_array(effectiveness.elementWeaknesses)
	
	return weaknesses

func get_element_resistances() -> Array[Move.Element]:
	var resistances: Array[Move.Element] = []
	var effectiveness: MoveEffectiveness = get_move_effectiveness()
	
	if effectiveness != null:
		resistances.append_array(effectiveness.elementResistances)
		
	return resistances

func get_element_effectiveness_multiplier(element: Move.Element) -> float:
	var effectiveness: MoveEffectiveness = get_move_effectiveness()
	
	if effectiveness == null:
		return ELEMENT_EFFECTIVENESS_MULTIPLIERS.effective
	
	if effectiveness.is_weak_to_element(element):
		return ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective
	
	if effectiveness.is_resistant_to_element(element):
		return ELEMENT_EFFECTIVENESS_MULTIPLIERS.resisted
	
	return ELEMENT_EFFECTIVENESS_MULTIPLIERS.effective

func get_status_resistances() -> Array[StatusEffect.Type]:
	var resistances: Array[StatusEffect.Type] = []
	var effectiveness: MoveEffectiveness = get_move_effectiveness()
	
	if effectiveness != null:
		resistances.append_array(effectiveness.statusResistances)
	
	return resistances

func get_status_immunities() -> Array[StatusEffect.Type]:
	var immunities: Array[StatusEffect.Type] = []
	var effectiveness: MoveEffectiveness = get_move_effectiveness()
	
	if effectiveness != null:
		immunities.append_array(effectiveness.statusImmunities)
	
	return immunities

func get_status_effectiveness_multiplier(type: StatusEffect.Type) -> float:
	var effectiveness: MoveEffectiveness = get_move_effectiveness()
	
	if effectiveness == null:
		return STATUS_EFFECTIVENESS_MULTIPLIERS.effective
	
	if effectiveness.is_resistant_to_status(type):
		return STATUS_EFFECTIVENESS_MULTIPLIERS.resisted
	
	if effectiveness.is_immune_to_status(type):
		return STATUS_EFFECTIVENESS_MULTIPLIERS.immune
	
	return STATUS_EFFECTIVENESS_MULTIPLIERS.effective

func would_ai_spend_orbs(effect: MoveEffect) -> bool:
	if not could_combatant_surge(effect):
		return false
	
	var spendingOrbs: int = effect.orbChange * -1
	
	match get_resource_strategy():
		ResourceStrategy.GREEDY:
			return orbs >= spendingOrbs # if we have the orbs, do it
		ResourceStrategy.BIG_SPENDER:
			return orbs >= spendingOrbs + 2 or orbs == 10 # if we have 2 more orbs than required, or we have 10 orbs, then do it
		ResourceStrategy.BIG_SAVER:
			return orbs >= spendingOrbs + 2 or orbs == 10 # if we have 2 more orbs than required, or we have 10 orbs, then do it
	return false # default: never spend orbs

func get_orbs_change_choice(moveEffect: MoveEffect) -> int:
	if moveEffect.orbChange >= 0:
		return moveEffect.orbChange # if we don't have the choice to spend, just return the number
	else:
		# spending orbs:
		match get_resource_strategy():
			ResourceStrategy.GREEDY:
				return orbs * -1 # always spend max
			ResourceStrategy.BIG_SPENDER:
				return orbs * -1 # always spend max
			ResourceStrategy.BIG_SAVER:
				if currentHp <= 0.25 * stats.maxHp:
					return orbs * -1 # spend max if health is <= 25%; could be gone next turn!
				var spending: int = moveEffect.orbChange # start with minimum
				# if combatant can upgrade status to at least weak, do it
				if moveEffect.surgeChanges.weakThresholdOrbs > abs(moveEffect.orbChange) and orbs > moveEffect.surgeChanges.weakThresholdOrbs:
					spending = moveEffect.surgeChanges.weakThresholdOrbs * -1
				# if combatant can upgrade status to at least strong, do it
				if moveEffect.surgeChanges.strongThresholdOrbs > abs(moveEffect.orbChange) and orbs > moveEffect.surgeChanges.strongThresholdOrbs:
					spending = moveEffect.surgeChanges.strongThresholdOrbs * -1
				# if combatant can upgrade status to overwhelming, do it
				if moveEffect.surgeChanges.overwhelmingThresholdOrbs > abs(moveEffect.orbChange) and orbs > moveEffect.surgeChanges.overwhelmingThresholdOrbs:
					spending = moveEffect.surgeChanges.overwhelmingThresholdOrbs * -1
				return spending
		return moveEffect.orbChange # default: always spend minimum

func level_up_nonplayer(newLv: int, overrideStatAllocStrat: StatAllocationStrategy = null):
	var lvDiff: int = newLv - stats.level
	if lvDiff > 0:
		stats.level_up(lvDiff)
		currentHp = stats.maxHp
		var allocStrat: StatAllocationStrategy = get_stat_allocation_strategy()
		if overrideStatAllocStrat != null:
			allocStrat = overrideStatAllocStrat
		# if a strategy is defined for this combatant: execute it
		if allocStrat != null:
			allocStrat.allocate_stats(stats)
	elif lvDiff < 0:
		printerr("level up nonplayer err: level diff is negative")

func assign_moves_nonplayer():
	stats.moves = [null, null, null, null]
	var preferredRoles: Array[MoveEffect.Role] = [
		stats.movepool.preferredMove1Role,
		stats.movepool.preferredMove2Role,
		stats.movepool.preferredMove3Role,
		stats.movepool.preferredMove4Role
	]
	var preferredTypes: Array[Move.DmgCategory] = [
		stats.movepool.preferredMove1DmgType,
		stats.movepool.preferredMove2DmgType,
		stats.movepool.preferredMove3DmgType,
		stats.movepool.preferredMove4DmgType
	]
	var preferredElements: Array[Move.Element] = [
		stats.movepool.preferredMove1Element,
		stats.movepool.preferredMove2Element,
		stats.movepool.preferredMove3Element,
		stats.movepool.preferredMove4Element
	]
	
	var bestScores: Array[int] = [
		-1,
		-1,
		-1,
		-1
	]
	
	# for each move slot, use the preferred role to find the highest lv move that includes that role
	# MoveEffect.Role.OTHER means no preference, so a slot with that preference skips this phase and goes onto the next
	# NOTE: loop through twice; one to allocate approximately the most preferred move to the slot; then to backfill the "best"/highest lv move after all good moves have been already picked
	var assignedSignatureMove: bool = false 
	for scoreToBeat: int in [31, -1]:
		for idx: int in range(len(preferredRoles)):
			var bestMove: Move = stats.moves[idx] # check against the previously assigned move (if any)
			# first time, score to beat is 31: has to be of the specified role (most specific of the filters)
			# second time, score to beat is -1: min score of a non-null move going into a null slot is 1 
			var bestScore: int = max(bestScores[idx], scoreToBeat)
			for move: Move in stats.movepool.pool:
				if move.requiredLv > stats.level:
					continue
				var score: int = 0
				# most important for the desired move role to match
				if move.has_effect_with_role(preferredRoles[idx]) and preferredRoles[idx] != MoveEffect.Role.OTHER:
					score += 64
					if move.effects_with_role(preferredRoles[idx]) == Move.MoveEffectType.BOTH:
						score += 8 # if both moves have the preferred role, bonus to score
						# more important than signature move, element, and level
						# but less important than dmg category
				else:
					# AOE damage is preferred, but if not available, take single-target instead
					if preferredRoles[idx] == MoveEffect.Role.AOE_DAMAGE and move.has_effect_with_role(MoveEffect.Role.SINGLE_TARGET_DAMAGE):
						score += 32 #* move.count_effects_with_role(preferredRoles[idx])
				
				if move.category == preferredTypes[idx] and preferredTypes[idx] != Move.DmgCategory.ANY:
					score += 16 # pretty important for the move damage category to match
				
				# if no signature move has been selected: prefer a signature move that we haven't already selected
				if not assignedSignatureMove and move in stats.movepool.signatureMoves and not move in stats.moves:
					score += 4 # more important than element and level for a signature move to be assigned
				
				if move.element == preferredElements[idx] and preferredElements[idx] != Move.Element.NONE:
					score += 2 # not as important for the move element to match what's preferred
				
				if bestMove == null or bestMove.requiredLv < move.requiredLv:
					score += 1 # least specific criteria: least important for the move to be higher lv
				
				#print(move.moveName, ' for slot ', idx, ' scored ', score, '. Prior to check best move is ', 'null' if bestMove == null else bestMove.moveName, ' (score ', bestScore, ')')
				if (score > bestScore \
							or (bestMove != null and score == bestScore and move.requiredLv > bestMove.requiredLv) \
						) \
						and not move in stats.moves:
					bestMove = move
					bestScore = score
			if bestMove != null:
				#print(stats.displayName + ' move ', idx, ' is now ', bestMove.moveName, ' (score ', bestScore, ')')
				stats.moves[idx] = bestMove
				bestScores[idx] = bestScore
				if bestMove in stats.movepool.signatureMoves:
					assignedSignatureMove = true
		
	stats.moves = stats.moves.filter(_filter_null) # remove null entries because they aren't needed
	# NOTE: check if having null entries breaks anything (specifically move picking) or not
	''' initial attempt, going by move in movepool and not by slot
	var nextMoveSlot: int = 0
	for move: Move in stats.movepool.pool:
		if move.requiredLv <= stats.level:
			if len(stats.moves) < 4:
				stats.moves.insert(nextMoveSlot, move)
				nextMoveSlot = len(stats.moves)
			else:
				var replaceIdx: int = -1
				for idx in range(len(stats.moves)):
					# first consider the move at `nextMoveSlot`
					var moveIdx = (nextMoveSlot + idx) % 4
					if move.has_effect_with_role(preferredMoves[moveIdx]) or preferredMoves[moveIdx] == MoveEffect.Role.OTHER:
						# if found, break so this is the one we definitely change
						replaceIdx = moveIdx
						break
				if replaceIdx != -1:
					# if we found a candidate slot this should go into, replace the move and update `nextMoveSlot`
					stats.moves[replaceIdx] = move
					nextMoveSlot = (nextMoveSlot + 1) % 4
				#stats.moves[nextMoveSlot] = move
	#'''

# returns the number of null moves after validation but before any re-assignment
func validate_moves() -> int:
	var emptySlots: int = Stats.MAX_MOVES - len(stats.moves) # each move slot that isn't represented in the array counts as empty
	
	for moveIdx in range(len(stats.moves)):
		var move: Move = stats.moves[moveIdx]
		if move != null and not move in stats.movepool.pool:
			stats.moves[moveIdx] = null
		if stats.moves[moveIdx] == null:
			emptySlots += 1
	if emptySlots == Stats.MAX_MOVES:
		assign_moves_nonplayer()
	return emptySlots

func pick_equipment():
	if weightedEquipment == null:
		return
	
	var choice: int = WeightedThing.pick_item(weightedEquipment.weightedEquipment)
	if choice >= 0 and choice < len(weightedEquipment.weightedEquipment):
		var equipmentChoice: WeightedEquipment = weightedEquipment.weightedEquipment[choice]
		stats.equippedWeapon = equipmentChoice.weapon
		stats.equippedArmor = equipmentChoice.armor
		stats.equippedAccessory = equipmentChoice.accessory
	else:
		stats.equippedWeapon = null
		stats.equippedArmor = null
		stats.equippedAccessory = null

func validate_allocation_strategy_non_null():
	if statAllocationStrategy == null:
		print('Combatant ', save_name(), ' is missing its stat allocation strategy. Fixing...')
		var combatantOfType: Combatant = Combatant.load_combatant_resource(save_name()) as Combatant
		statAllocationStrategy = combatantOfType.statAllocationStrategy
		if statAllocationStrategy != null:
			print('Combatant ', save_name(), ' stat allocation strategy validation error fixed.')
		else:
			printerr('Combatant ', save_name(), ' stat allocation strategy validation error was not fixed.')

func should_auto_alloc_stat_pts() -> bool:
	# currently, default shouldn't be to auto-allocate, only the explicit automatic setting
	return minionStatAllocMode == MinionStatAllocationMode.AUTOMATIC

func copy() -> Combatant:
	var newCombatant: Combatant = Combatant.new()
	newCombatant.save_from_object(self)
	return newCombatant

func save_from_object(c: Combatant):
	stats = c.stats.copy()
	evolutions = c.evolutions
	evolutionStats = {}
	for evolutionName in c.evolutionStats:
		evolutionStats[evolutionName] = c.evolutionStats[evolutionName].copy()
	
	nickname = c.nickname
	currentHp = c.currentHp
	
	if c.statChanges != null:
		statChanges = c.statChanges.copy()
	else:
		statChanges = null
		
	if c.statusEffect != null:
		statusEffect = c.statusEffect.duplicate(true)
	else:
		statusEffect = null
	sprite = c.sprite
	ai = c.ai
	aiType = c.aiType
	damageAggroType = c.damageAggroType
	
	runes = []
	for rune: Rune in c.runes:
		runes.append(rune.copy(true))
	
	triggeredRunes = []
	for rune: Rune in c.triggeredRunes:
		triggeredRunes.append(rune.copy(true))
	
	strategy = c.strategy
	friendship = c.friendship
	aiOverrideWeight = c.aiOverrideWeight
	moveEffectiveness = c.moveEffectiveness
	weightedEquipment = c.weightedEquipment
	dropTable = c.dropTable
	if c.statAllocationStrategy != null:
		statAllocationStrategy = c.statAllocationStrategy.duplicate(false)
	else:
		statAllocationStrategy = null
	
	if c.command != null:
		command = c.command.duplicate(false)
	else:
		command = null
	
	downed = c.downed
	
	battleStorageHp = c.battleStorageHp
	battleStorageOrbs = c.battleStorageOrbs
	battleStorageStatus = c.battleStorageStatus

func update_battle_storage() -> void:
	battleStorageHp = currentHp
	battleStorageOrbs = orbs
	battleStorageStatus = statusEffect
	triggeredRunes = []
	triggeredRunesDmg = []
	triggeredRunesStatus = []

func _desc_order(a, b) -> bool:
	return a > b

func _filter_null(a) -> bool:
	return a != null
