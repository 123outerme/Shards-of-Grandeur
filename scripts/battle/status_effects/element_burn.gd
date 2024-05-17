extends StatusEffect
class_name ElementBurn

const PERCENT_DAMAGE_DICT: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.5,
	Potency.STRONG: 0.75,
	Potency.OVERWHELMING: 1.1
}

const _element_burn_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _burn_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _soaking_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _jolt_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _gust_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _crush_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _poison_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _frighten_icon: Texture2D = preload('res://graphics/ui/bleed.png')
const _nova_icon: Texture2D = preload('res://graphics/ui/bleed.png')

@export var element: Move.Element = Move.Element.NONE
@export var power: float = 0
@export var attackerStat: float = 0
@export var attackerLv: int = 1

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0,
	i_element = Move.Element.NONE,
	i_power = 0,
	i_attackerStat = 0,
	i_attackerLv = 1,
):
	super(Type.ELEMENT_BURN, i_potency, i_turnsLeft)
	element = i_element
	power = i_power
	attackerStat = i_attackerStat
	attackerLv = i_attackerLv

func get_burn_damage(combatant: Combatant) -> int:
	var targetStatChanges = StatChanges.new()
	targetStatChanges.stack(combatant.statChanges)
	var elEffectivenessMultiplier: float = combatant.get_element_effectiveness_multiplier(element)
	var targetStats: Stats = targetStatChanges.apply(combatant.stats)
	return BattleCommand.damage_formula(power * PERCENT_DAMAGE_DICT[potency], attackerStat, targetStats.resistance, attackerLv, combatant.stats.level, elEffectivenessMultiplier)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		combatant.currentHp = max(combatant.currentHp - get_burn_damage(combatant), 0)
		dealtDmgCombatants = [combatant]
	dealtDmgCombatants.append_array(super.apply_status(combatant, allCombatants, timing))
	return dealtDmgCombatants
	
func get_burn_type() -> String:
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
		return combatant.disp_name() + ' takes ' + str(get_burn_damage(combatant)) + ' damage from ' + status_effect_to_string() + '!'
	return ''

func get_status_effect_tooltip():
	return 'A combatant with ' + get_burn_type() + ' takes damage at the end of a battle round, relative to the Power of the move used to inflict it.' 

func status_effect_to_string() -> String:
	return StatusEffect.potency_to_string(potency) + ' ' + get_burn_type()

func get_icon() -> Texture2D:
	match element:
		Move.Element.NONE:
			return _element_burn_icon
		Move.Element.FIRE:
			return _burn_icon
		Move.Element.WATER:
			return _soaking_icon
		Move.Element.LIGHTNING:
			return _jolt_icon
		Move.Element.WIND:
			return _gust_icon
		Move.Element.EARTH:
			return _crush_icon
		Move.Element.NATURE:
			return _poison_icon
		Move.Element.DARK:
			return _frighten_icon
		Move.Element.ASTRAL:
			return _nova_icon
	return null

func copy() -> StatusEffect:
	return ElementBurn.new(
		potency,
		turnsLeft,
		element,
		power,
		attackerStat,
		attackerLv,
	)
