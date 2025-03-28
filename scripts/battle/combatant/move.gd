extends Resource
class_name Move

enum DmgCategory {
	PHYSICAL = 0, ## Physical
	MAGIC = 1, ## Magic
	AFFINITY = 2, ## Affinity
	ANY = -1, ## only for use in movepool.gd Preferences and damage_rune.gd
}

enum Element {
	NONE = 0, ## No element
	WATER = 1, ## Water
	FIRE = 2, ## Fire
	LIGHTNING = 3, ## Lightning
	WIND = 4, ## Wind
	EARTH = 5, ## Earth
	NATURE = 6, ## Nature
	DARK = 7, ## Dark
	ASTRAL = 8 ## Astral
}
const NUM_ELEMENTS = 8

enum MoveEffectType {
	NONE = 0, ## For use in move-selecting AI only
	CHARGE = 1, ## Charge
	SURGE = 2, ## Surge
	BOTH = 3, ## For use in move-selecting AI only
}

@export var moveName: String = ''
@export var requiredLv: int = 1
@export var category: DmgCategory = DmgCategory.PHYSICAL
@export var element: Element = Element.NONE
@export var chargeEffect: MoveEffect = null
@export var surgeEffect: MoveEffect = null
@export_multiline var description: String = ''
@export_multiline var moveLearnedText: String = ''
@export var moveAnimation: MoveAnimation = null

static func dmg_category_to_string(c: DmgCategory) -> String:
	match c:
		DmgCategory.PHYSICAL:
			return 'Physical'
		DmgCategory.MAGIC:
			return 'Magic'
		DmgCategory.AFFINITY:
			return 'Affinity'
	return 'UNKNOWN'

static func element_to_string(e: Element) -> String:
	match e:
		Element.NONE:
			return 'None'
		Element.WATER:
			return 'Water'
		Element.FIRE:
			return 'Fire'
		Element.LIGHTNING:
			return 'Lightning'
		Element.WIND:
			return 'Wind'
		Element.EARTH:
			return 'Earth'
		Element.NATURE:
			return 'Nature'
		Element.DARK:
			return 'Dark'
		Element.ASTRAL:
			return 'Astral'
	return 'UNKNOWN'

static func move_effect_type_to_string(t: MoveEffectType) -> String:
	match t:
		MoveEffectType.NONE:
			return 'None'
		MoveEffectType.CHARGE:
			return 'Charge'
		MoveEffectType.SURGE:
			return 'Surge'
		MoveEffectType.BOTH:
			return 'Both'
	return 'UNKNOWN'

func _init(
	i_moveName = '',
	i_requiredLv = 1,
	i_category = DmgCategory.PHYSICAL,
	i_element = Element.NONE,
	i_chargeEffect = null,
	i_surgeEffect = null,
	i_description = '',
	i_moveLearnedText = '',
	i_moveAnim: MoveAnimation = null,
	
):
	moveName = i_moveName
	requiredLv = i_requiredLv
	category = i_category
	element = i_element
	chargeEffect = i_chargeEffect
	surgeEffect = i_surgeEffect
	description = i_description
	moveLearnedText = i_moveLearnedText
	moveAnimation = i_moveAnim

func get_effect_of_type(t: MoveEffectType) -> MoveEffect:
	if t == MoveEffectType.CHARGE:
		return chargeEffect
	
	if t == MoveEffectType.SURGE:
		return surgeEffect
	
	return null

func effects_with_status() -> MoveEffectType:
	var chargeStatus: bool = chargeEffect.statusEffect != null
	var surgeStatus: bool = surgeEffect.statusEffect != null
	
	if chargeStatus and surgeStatus:
		return MoveEffectType.BOTH
	
	if chargeStatus:
		return MoveEffectType.CHARGE
	
	if surgeStatus:
		return MoveEffectType.SURGE
	
	return MoveEffectType.NONE

func has_effect_with_role(role: MoveEffect.Role) -> bool:
	return chargeEffect.role == role or surgeEffect.role == role

func effects_with_role(role: MoveEffect.Role) -> MoveEffectType:
	var chargeHasEffect: bool = chargeEffect.role == role
	var surgeHasEffect: bool = surgeEffect.role == role
	
	if chargeHasEffect and surgeHasEffect:
		return MoveEffectType.BOTH
	
	if chargeHasEffect:
		return MoveEffectType.CHARGE
	
	if surgeHasEffect:
		return MoveEffectType.SURGE
	
	return MoveEffectType.NONE
