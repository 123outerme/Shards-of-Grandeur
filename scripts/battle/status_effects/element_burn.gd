extends StatusEffect
class_name ElementBurn

const PERCENT_DAMAGE_DICT: Dictionary[Potency, float] = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.5,
	Potency.STRONG: 0.75,
	Potency.OVERWHELMING: 1.1
}

const _element_burn_icon: Texture2D = preload('res://graphics/ui/element_burn.png')
const _burn_icon: Texture2D = preload('res://graphics/ui/burn.png')
const _soak_icon: Texture2D = preload('res://graphics/ui/soak.png')
const _jolt_icon: Texture2D = preload('res://graphics/ui/jolt.png')
const _gust_icon: Texture2D = preload('res://graphics/ui/gust.png')
const _crush_icon: Texture2D = preload('res://graphics/ui/crush.png')
const _poison_icon: Texture2D = preload('res://graphics/ui/poison.png')
const _fear_icon: Texture2D = preload('res://graphics/ui/fear.png')
const _nova_icon: Texture2D = preload('res://graphics/ui/nova.png')

## "None" element is placeholder'd with the generic name Element Burn and generic icon, but I currently have no plans to use it
@export var element: Move.Element = Move.Element.NONE

## when setting in a MoveEffect, if setting this to be >0, that will be the power used to calculate the DoT. If left <=0, will use the move's final calculated power instead
@export var power: float = 0

## setting in a MoveEffect is useless; it's always overwritten
@export var attackerStat: float = 0

## setting in a MoveEffect is useless; it's always overwritten
@export var attackerLv: int = 1

## used for determining if a Damage Rune should trigger on the AFTER_ROUND step of status checking
@export_storage var damageTriggered: bool = false
# further information: Without this check, if a Rune(s) applies this Status Effect,
# and deals damage not matching the element of an applied Elemental Damage Rune,
# this Rune would trigger when the Status Effect never actually dealt damage
# > i.e. if Fear is put on a combatant and Lightning Damage dealt from a previous Rune(s) triggering,
# > during the AFTER_ROUND step, if this combatant has a Dark Damage Rune, that would then trigger mistakenly

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0,
	i_element = Move.Element.NONE,
	i_power: float = 0,
	i_attackerStat: float = 0,
	i_attackerLv: int = 1,
	i_damageTriggered: bool = false,
):
	super(Type.ELEMENT_BURN, i_potency, i_overwrites, i_turnsLeft)
	element = i_element
	power = i_power
	attackerStat = i_attackerStat
	attackerLv = i_attackerLv
	damageTriggered = i_damageTriggered

func get_burn_damage(combatant: Combatant) -> int:
	var targetStatChanges = StatChanges.new()
	targetStatChanges.stack(combatant.statChanges)
	var elEffectivenessMultiplier: float = combatant.get_element_effectiveness_multiplier(element)
	var targetStats: Stats = targetStatChanges.apply(combatant.stats)
	if combatant.statusEffect != null and combatant.statusEffect.is_stat_altering():
		targetStats = combatant.statusEffect.apply_stat_change(targetStats)

	return BattleCommand.damage_formula(power * PERCENT_DAMAGE_DICT[potency], attackerStat, targetStats.resistance, attackerLv, combatant.stats.level, elEffectivenessMultiplier)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.BEFORE_ROUND:
		damageTriggered = false
	
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		combatant.currentHp = max(combatant.currentHp - get_burn_damage(combatant), 0)
		dealtDmgCombatants = [combatant]
		damageTriggered = true
	dealtDmgCombatants.append_array(super.apply_status(combatant, allCombatants, timing))
	return dealtDmgCombatants
	
func get_status_type_string() -> String:
	match element:
		Move.Element.NONE:
			return 'Element Burn'
		Move.Element.FIRE:
			return 'Burn'
		Move.Element.WATER:
			return 'Soak'
		Move.Element.LIGHTNING:
			return 'Jolt'
		Move.Element.WIND:
			return 'Gust'
		Move.Element.EARTH:
			return 'Crush'
		Move.Element.NATURE:
			return 'Poison'
		Move.Element.DARK:
			return 'Fear'
		Move.Element.ASTRAL:
			return 'Nova'
	return 'UNKNOWN'

func set_burn_damage_parameters(pPower: float, pAttackerStat: float, pAttackerLv: int):
	power = pPower
	attackerStat = pAttackerStat
	attackerLv = pAttackerLv

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		return combatant.disp_name() + ' takes ' + str(get_burn_damage(combatant)) + ' ' + Move.element_to_string(element) + ' damage from ' + status_effect_to_string() + '!'
	return ''

func get_status_effect_tooltip():
	return 'A combatant with ' + get_status_type_string() + ' takes ' + Move.element_to_string(element) + ' damage at the end of a battle round, relative to the Power of the move used to inflict it.' 

func get_status_effect_damage(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> int:
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		return get_burn_damage(combatant)
	return 0

func get_status_effect_damage_effectiveness(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> float:
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		return combatant.get_element_effectiveness_multiplier(element)
	return Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.effective

func get_icon() -> Texture2D:
	match element:
		Move.Element.NONE:
			return _element_burn_icon
		Move.Element.FIRE:
			return _burn_icon
		Move.Element.WATER:
			return _soak_icon
		Move.Element.LIGHTNING:
			return _jolt_icon
		Move.Element.WIND:
			return _gust_icon
		Move.Element.EARTH:
			return _crush_icon
		Move.Element.NATURE:
			return _poison_icon
		Move.Element.DARK:
			return _fear_icon
		Move.Element.ASTRAL:
			return _nova_icon
	return null

func copy() -> StatusEffect:
	return ElementBurn.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft,
		element,
		power,
		attackerStat,
		attackerLv,
	)
