extends Resource
class_name Evolution

@export var evolutionSaveName: String  = ''
@export var spriteFrames: SpriteFrames = null
@export var maxSize: Vector2 = Vector2(16, 16)
@export var facesRight: bool = false
@export var requiredArmor: Armor = null
@export var requiredWeapon: Weapon = null
@export var stats: Stats = Stats.new()
@export var moveEffectiveness: MoveEffectiveness = null

func _init(
	i_evoSaveName = '',
	i_spriteFrames = null,
	i_maxSize = Vector2(16, 16),
	i_facesRight = false,
	i_requiredArmor = null,
	i_requiredWeapon = null,
	i_stats = Stats.new(),
	i_moveEffectiveness = null,
):
	evolutionSaveName = i_evoSaveName
	spriteFrames = i_spriteFrames
	maxSize = i_maxSize
	facesRight = i_facesRight
	requiredArmor = i_requiredArmor
	requiredWeapon = i_requiredWeapon
	stats = i_stats
	moveEffectiveness = i_moveEffectiveness

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
