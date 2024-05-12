extends Resource
class_name Evolution

@export var evolutionSaveName: String  = ''

@export_category("Evolution - Sprite")
@export var combatantSprite: CombatantSprite = null
@export var spriteFrames: SpriteFrames = null
@export var maxSize: Vector2 = Vector2(16, 16)
@export var centerPosition: Vector2 = Vector2(8, 8)
@export var feetPosition: Vector2 = Vector2(8, 16)
@export var facesRight: bool = false
@export_flags_2d_navigation var navigationLayer: int = 1

@export_category("Evolution - Equipment")
@export var requiredArmor: Armor = null
@export var requiredWeapon: Weapon = null

@export_category("Evolution - Stats")
@export var stats: Stats = Stats.new()
@export var innateStatCategories: Array[Stats.Category] = []
@export var moveEffectiveness: MoveEffectiveness = null
@export var aiType: Combatant.AiType = Combatant.AiType.NONE
@export var aggroType: Combatant.AggroType = Combatant.AggroType.LOWEST_HP
@export var strategy: Combatant.ResourceStrategy = Combatant.ResourceStrategy.GREEDY

func _init(
	i_evoSaveName = '',
	i_sprite = null,
	i_spriteFrames = null,
	i_maxSize = Vector2(16, 16),
	i_centerPosition = Vector2(8, 8),
	i_feetPosition = Vector2(8, 16),
	i_facesRight = false,
	i_navLayer = 1,
	i_requiredArmor = null,
	i_requiredWeapon = null,
	i_stats = Stats.new(),
	i_innateStatCategories: Array[Stats.Category] = [],
	i_moveEffectiveness = null,
	i_aiType = Combatant.AiType.NONE,
	i_aggroType = Combatant.AggroType.LOWEST_HP,
	i_strategy = Combatant.ResourceStrategy.GREEDY,
):
	evolutionSaveName = i_evoSaveName
	combatantSprite = i_sprite
	spriteFrames = i_spriteFrames
	maxSize = i_maxSize
	centerPosition = i_centerPosition
	feetPosition = i_feetPosition
	facesRight = i_facesRight
	requiredArmor = i_requiredArmor
	requiredWeapon = i_requiredWeapon
	stats = i_stats
	innateStatCategories = i_innateStatCategories
	moveEffectiveness = i_moveEffectiveness
	aiType = i_aiType
	aggroType = i_aggroType
	strategy = i_strategy

func combatant_can_evolve(combatant: Combatant) -> bool:
	if requiredArmor == null and requiredWeapon == null:
		return false

	if requiredArmor != null and (combatant.stats.equippedArmor == null or \
			combatant.stats.equippedArmor.itemName != requiredArmor.itemName):
		return false

	if requiredWeapon != null and (combatant.stats.equippedWeapon == null or \
			combatant.stats.equippedWeapon.itemName != requiredWeapon.itemName):
		return false

	return true
