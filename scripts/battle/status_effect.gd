extends Resource
class_name StatusEffect

enum Type {
	NONE = 0, # no effect
	EXHAUSTION = 1, # move-last
	BLEED = 2, # damage over time
	BERSERK = 3, # take recoil damage after every damaging move - other names could be Reckless, Overextertion, etc.
	WEAKNESS = 4, # reduces outgoing physical stat
	CONFUSION = 5, # reduces outgoing magic stat
	JINX = 6, # reduces outgoing affinity stat
	MANIA = 7, # positive; move-first
	REFLECT = 8, # TODO better name; causes recoil damage when hit with attack
	INTERCEPTION = 9, # "attracts" a percentage of damage dealt to allies to self
	GUARD_BREAK = 10,
	ELEMENT_BURN = 11,
	# other ones could be positive effects?
}

enum Potency {
	NONE = 0,
	WEAK = 1,
	STRONG = 2,
	OVERWHELMING = 3,
}

static func status_type_to_string(t: Type) -> String:
	match t:
		Type.NONE:
			return 'None'
		Type.EXHAUSTION:
			return 'Exhaustion'
		Type.BLEED:
			return 'Bleed'
		Type.BERSERK:
			return 'Berserk'
		Type.WEAKNESS:
			return 'Weakness'
		Type.CONFUSION:
			return 'Confusion'
		Type.JINX:
			return 'Jinx'
		Type.MANIA:
			return 'Mania'
		Type.REFLECT:
			return 'Reflect'
		Type.INTERCEPTION:
			return 'Interception'
		Type.GUARD_BREAK:
			return 'Guard Break'
		Type.ELEMENT_BURN:
			return 'Element Burn'
	return 'UNKNOWN'

static func potency_to_string(p: Potency) -> String:
	match p:
		Potency.NONE:
			return 'None'
		Potency.WEAK:
			return 'Slight'
		Potency.STRONG:
			return 'Potent'
		Potency.OVERWHELMING:
			return 'Overwhelming'
	return 'UNKNOWN'

@export var type: Type = Type.NONE
@export var potency: Potency = Potency.NONE
@export var overwritesOtherStatuses: bool = false
@export var turnsLeft: int = 0

func _init(
	i_type: Type = Type.NONE,
	i_potency: Potency = Potency.NONE,
	i_overwrites: bool = false,
	i_turnsLeft = 0,
):
	type = i_type
	potency = i_potency
	overwritesOtherStatuses = i_overwrites
	turnsLeft = i_turnsLeft

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	# each status effect needs to implement this then call super's version
	# returning the combatants dealt damage to as a result of the status
	if timing == BattleCommand.ApplyTiming.AFTER_POST_ROUND:
		turnsLeft -= 1
		if turnsLeft == 0:
			type = Type.NONE
			potency = Potency.NONE
			combatant.statusEffect = null
	return []

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	return '' # each status effect needs to implement this separately

func get_status_effect_tooltip():
	return '' # each status effect needs to implement separately

func get_icon() -> Texture2D:
	return null

func status_effect_to_string() -> String:
	return StatusEffect.potency_to_string(potency) + ' ' + get_status_type_string()

func get_status_type_string() -> String:
	return StatusEffect.status_type_to_string(type)

func copy() -> StatusEffect:
	return StatusEffect.new(
		type,
		potency,
		turnsLeft
	)
