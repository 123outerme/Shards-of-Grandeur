extends Resource
class_name StatusEffect

enum Type {
	NONE = 0, # no effect
	EXHAUSTION = 1, # move-last
	BLEED = 2, # damage over time
	BERSERK = 3, # take recoil damage after every damaging move - other names could be Reckless, Overextertion, etc.
	WEAKNESS = 4, # reduces outgoing physical damage
	NEGATED = 5, # reduces outgoing magic damage
	JINXED = 6, # reduces outgoing affinity damage
	MANIC = 7, # positive; move-first
	REFLECT = 8, # TODO better name; causes recoil damage when hit with attack
	INTERCEPTION = 9, # TODO better name; "attracts" a percentage of damage dealt to allies to self
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
		Type.NEGATED:
			return 'Negated'
		Type.JINXED:
			return 'Jinxed'
		Type.MANIC:
			return 'Manic'
		Type.REFLECT:
			return 'Reflect'
		Type.INTERCEPTION:
			return 'Interception'
	return 'UNKNOWN'

static func potency_to_string(p: Potency) -> String:
	match p:
		Potency.NONE:
			return 'None'
		Potency.WEAK:
			return 'Weak'
		Potency.STRONG:
			return 'Strong'
		Potency.OVERWHELMING:
			return 'Overwhelming'
	return 'UNKNOWN'

@export var type: Type = Type.NONE
@export var potency: Potency = Potency.NONE
@export var turnsLeft: int = 0

func _init(
	i_type: Type = Type.NONE,
	i_potency: Potency = Potency.NONE,
	i_turnsLeft = 0,
):
	type = i_type
	potency = i_potency
	turnsLeft = i_turnsLeft

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming): # each status effect needs to implement this then call super's version
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		turnsLeft -= 1
		if turnsLeft == 0:
			type = Type.NONE
			potency = Potency.NONE
			combatant.statusEffect = null

func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	return '' # each status effect needs to implement this separately

func status_effect_to_string() -> String:
	return StatusEffect.potency_to_string(potency) + ' ' + StatusEffect.status_type_to_string(type)

func copy() -> StatusEffect:
	return StatusEffect.new(
		type,
		potency,
		turnsLeft
	)
