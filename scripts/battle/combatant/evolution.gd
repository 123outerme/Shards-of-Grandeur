extends Resource
class_name Evolution

@export var evolutionSaveName: String  = ''
@export var spriteFrames: SpriteFrames = null
@export var maxSize: Vector2 = Vector2(16, 16)
@export var facesRight: bool = false
@export var requiredEquipment: Item = null
@export var stats: Stats = Stats.new()

func _init(
	i_evoSaveName = '',
	i_spriteFrames = null,
	i_maxSize = Vector2(16, 16),
	i_facesRight = false,
	i_requiredEquipment = null,
	i_stats = Stats.new(),
):
	evolutionSaveName = i_evoSaveName
	spriteFrames = i_spriteFrames
	maxSize = i_maxSize
	facesRight = i_facesRight
	requiredEquipment = null
	stats = i_stats

func combatant_can_evolve(combatant: Combatant) -> bool:
	if requiredEquipment == null:
		return false
	
	if (combatant.stats.equippedArmor != null and combatant.stats.equippedArmor.itemName == requiredEquipment.itemName) or \
		(combatant.stats.equippedWeapon != null and combatant.stats.equippedWeapon.itemName == requiredEquipment.itemName):
			return true
	return false
