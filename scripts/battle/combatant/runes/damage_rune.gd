extends Rune
class_name DamageRune

# Elemental Damage that triggers the Rune. if None, triggers on any damage type instead.
@export var triggerElement: Move.Element = Move.Element.NONE

@export var isHealRune: bool = false

@export_storage var previousHp: int = -1

func _init(
	i_orbChange: int = 0,
	i_category: Move.DmgCategory = Move.DmgCategory.PHYSICAL,
	i_element: Move.Element = Move.Element.NONE,
	i_power: int = 0,
	i_lifesteal: float = 0,
	i_statChanges: StatChanges = null,
	i_statusEffect: StatusEffect = null,
	i_surgeChanges: SurgeChanges = null,
	i_caster: Combatant = null,
	i_runeSpriteAnim: MoveAnimSprite = null,
	i_triggerAnim: MoveAnimSprite = null,
	i_triggerElement: Move.Element = Move.Element.NONE,
	i_isHealRune: bool = false,
	i_previousHp: int = -1
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	triggerElement = i_triggerElement
	isHealRune = i_isHealRune
	previousHp = i_previousHp

func init_rune_state(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState) -> void:
	super.init_rune_state(combatant, otherCombatants, state)
	if previousHp == -1:
		previousHp = combatant.currentHp

func get_rune_type() -> String:
	if not isHealRune:
		return 'Damage Rune'
	else:
		return 'Heal Rune'

func get_long_rune_type() -> String:
	if triggerElement == Move.Element.NONE:
		return get_rune_type()
	
	if not isHealRune:
		return Move.element_to_string(triggerElement) + ' Damage Rune'
	else:
		return Move.element_to_string(triggerElement) + ' Heal Rune'

func get_rune_trigger_description() -> String:
	var runeDescString: String = 'When '
	if not isHealRune:
		runeDescString += 'Dealt '
		if triggerElement != Move.Element.NONE:
			runeDescString += Move.element_to_string(triggerElement) + ' '
		runeDescString += 'Damage'
	else:
		runeDescString += 'Receiving '
		if triggerElement != Move.Element.NONE:
			runeDescString += Move.element_to_string(triggerElement) + ' '
		runeDescString += 'Healing'
	return runeDescString

func get_rune_tooltip() -> String:
	var tooltipStr: String = "This Rune's effect is triggered when the enchanted combatant "
	if not isHealRune:
		tooltipStr += 'takes '
		if triggerElement != Move.Element.NONE:
			tooltipStr += Move.element_to_string(triggerElement) + ' '
		tooltipStr += 'damage'
	else:
		tooltipStr += 'receives '
		if triggerElement != Move.Element.NONE:
			tooltipStr += Move.element_to_string(triggerElement) + ' '
		tooltipStr += 'healing'
	return tooltipStr + ' from any source.'

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	var triggered: bool = false
	var matchesElementTrigger: bool = triggerElement == Move.Element.NONE
	# catches easy cases such as post-round damage, other runes triggering
	# if previous HP is set: check if the current HP is less (dmg rune) or greater (heal rune)
	if previousHp != -1:
		if not isHealRune:
			triggered = combatant.currentHp < previousHp
		else:
			triggered = combatant.currentHp > previousHp
	previousHp = combatant.currentHp
	
	# not matter what the HP says (maybe a rune triggered healing on this combatant),
	# if the combatant has a damage-dealing status and it has activated after the round:
	if not isHealRune and timing == BattleCommand.ApplyTiming.AFTER_ROUND and combatant.statusEffect != null and \
			(combatant.statusEffect.type == StatusEffect.Type.ELEMENT_BURN or combatant.statusEffect.type == StatusEffect.Type.BLEED):
		triggered = true # that status triggered this Damage (not Heal) rune
	
	if triggered and timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		# if after status effects have triggered this rune, and the combatant has an Element Burn:
		if combatant.statusEffect != null and combatant.statusEffect.type == StatusEffect.Type.ELEMENT_BURN:
			# determine if this burn has triggered this turn, or if it was placed on the combatant after damage from another Rune/Status has occurred
			var elementBurn: ElementBurn = combatant.statusEffect as ElementBurn
			if elementBurn.element == triggerElement and elementBurn.damageTriggered:
				matchesElementTrigger = true
	
	# if the element trigger has not matched yet but runes were triggered:
	if not (triggered and matchesElementTrigger) and len(combatant.triggeredRunes) > 0:
		# check each rune to see if one dealt healing/damage with the matching element
		for triggeredRune: Rune in combatant.triggeredRunes:
			if ((triggeredRune.power > 0 and not isHealRune) or (triggeredRune.power < 0 and isHealRune)):
				triggered = true
				if triggeredRune.element == triggerElement:
					matchesElementTrigger = true
	
	# if the easy case didn't succeed and we're recieving damage:
	if not (triggered and matchesElementTrigger) and timing == BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG and len(otherCombatants) > 0:
		var user: Combatant = otherCombatants[0] if len(otherCombatants) > 0 else null
		# if the user has a command that already completed:
		if user != null and user.command != null and user.command.commandResult != null:
			var targetIdx: int = user.command.targets.find(combatant)
			
			# if this rune only cares about triggering from a certain element, and that element was used for the move:
			if user.command.type == BattleCommand.Type.MOVE and user.command.move.element == triggerElement:
				matchesElementTrigger = true
			
			# if this combatant was a target, the rune is triggered if this command dealt damage
			if targetIdx != -1:
				var dmgDealt: int = user.command.commandResult.damagesDealt[targetIdx]
				triggered = triggered or (dmgDealt > 0 and not isHealRune) or (dmgDealt < 0 and isHealRune)
			else:
				var interceptingIdx: int = user.command.interceptingTargets.find(combatant)
				# if this combatant intercepted, the rune is triggered if this command dealt damage
				if interceptingIdx != -1:
					var dmgDealt: int = user.command.commandResult.damageOnInterceptingTargets[interceptingIdx]
					triggered = triggered or (dmgDealt > 0 and not isHealRune) or (dmgDealt < 0 and isHealRune)
	return triggered and matchesElementTrigger

func copy(copyStorage: bool = false) -> DamageRune:
	var rune: DamageRune = DamageRune.new(
		orbChange,
		category,
		element,
		power,
		lifesteal,
		statChanges.copy() if statChanges != null else null,
		statusEffect.duplicate() if statusEffect != null else null,
		surgeChanges.duplicate() if surgeChanges != null else null,
		caster if copyStorage else null,
		runeSpriteAnim,
		triggerAnim,
		triggerElement,
		isHealRune,
	)
	
	if copyStorage:
		rune.previousHp = previousHp
	
	return rune
