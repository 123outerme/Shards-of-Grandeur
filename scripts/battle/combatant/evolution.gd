extends Resource
class_name Evolution

@export var evolutionSaveName: String  = ''
@export var combatantSprite: CombatantSprite = null

@export_category("Evolution - Equipment")
@export var requiredArmor: Armor = null
@export var requiredWeapon: Weapon = null
@export var requiredAccessory: Accessory = null

@export_category("Evolution - Stats")
@export var stats: Stats = Stats.new()
@export var statAllocationStrategy: StatAllocationStrategy = null
@export var moveEffectiveness: MoveEffectiveness = null
@export var ai: CombatantAi = null
@export var aiType: Combatant.AiType = Combatant.AiType.NONE
@export var aggroType: Combatant.AggroType = Combatant.AggroType.LOWEST_HP
@export var strategy: Combatant.ResourceStrategy = Combatant.ResourceStrategy.GREEDY
@export var dropTable: CombatantRewards = null

func _init(
	i_evoSaveName = '',
	i_sprite = null,
	i_requiredArmor = null,
	i_requiredWeapon = null,
	i_requiredAccessory: Accessory = null,
	i_stats = Stats.new(),
	i_statAllocStrat: StatAllocationStrategy = null,
	i_moveEffectiveness = null,
	i_ai: CombatantAi = null,
	i_aiType = Combatant.AiType.NONE,
	i_aggroType = Combatant.AggroType.LOWEST_HP,
	i_strategy = Combatant.ResourceStrategy.GREEDY,
	i_dropTable: CombatantRewards = null
):
	evolutionSaveName = i_evoSaveName
	combatantSprite = i_sprite
	requiredArmor = i_requiredArmor
	requiredWeapon = i_requiredWeapon
	requiredAccessory = i_requiredAccessory
	stats = i_stats
	statAllocationStrategy = i_statAllocStrat
	moveEffectiveness = i_moveEffectiveness
	ai = i_ai
	aiType = i_aiType
	aggroType = i_aggroType
	strategy = i_strategy
	dropTable = i_dropTable

func combatant_can_evolve(combatant: Combatant) -> bool:
	if requiredArmor == null and requiredWeapon == null and requiredAccessory == null:
		return false

	if requiredArmor != null and (combatant.stats.equippedArmor == null or \
			combatant.stats.equippedArmor.itemName != requiredArmor.itemName):
		return false

	if requiredWeapon != null and (combatant.stats.equippedWeapon == null or \
			combatant.stats.equippedWeapon.itemName != requiredWeapon.itemName):
		return false
	
	if requiredAccessory != null and (combatant.stats.equippedAccessory == null or \
			combatant.stats.equippedAccessory.itemName != requiredAccessory.itemName):
		return false

	return true
