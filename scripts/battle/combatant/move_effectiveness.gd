extends Resource
class_name MoveEffectiveness
# the information for a combatant's incoming element damage effectiveness, and status effectiveness

# elements that do increased damage
@export var elementWeaknesses: Array[Move.Element] = []
# elements that do reduced damage
@export var elementResistances: Array[Move.Element] = []

# status resistances reduce the chances of getting afflicted by a certain kind of status
@export var statusResistances: Array[StatusEffect.Type] = []
# status immunities mean this combatant can never get this status
@export var statusImmunities: Array[StatusEffect.Type] = []

func _init(
	i_eWeaknesses: Array[Move.Element] = [],
	i_eResistances: Array[Move.Element] = [],
	i_sResistances: Array[StatusEffect.Type] = [],
):
	elementWeaknesses = i_eWeaknesses
	elementResistances = i_eResistances
	statusResistances = i_sResistances

func is_weak_to_element(e: Move.Element) -> bool:
	if e == Move.Element.NONE:
		return false
	
	return e in elementWeaknesses
	
func is_resistant_to_element(e: Move.Element) -> bool:
	if e == Move.Element.NONE:
		return false

	return e in elementResistances

func is_resistant_to_status(t: StatusEffect.Type) -> bool:
	if t == StatusEffect.Type.NONE:
		return false
	
	return t in statusResistances

func is_immune_to_status(t: StatusEffect.Type) -> bool:
	if t == StatusEffect.Type.NONE:
		return false
	
	return t in statusImmunities
