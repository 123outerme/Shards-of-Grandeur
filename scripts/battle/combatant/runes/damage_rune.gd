extends Rune
class_name DamageRune

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
	i_isHealRune: bool = false,
	i_previousHp: int = -1
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	isHealRune = i_isHealRune
	previousHp = i_previousHp

func init_rune_state(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState) -> void:
	super.init_rune_state(combatant, otherCombatants, state)
	if previousHp == -1:
		previousHp = combatant.currentHp

func get_rune_type() -> String:
	return 'Damage Rune'

func get_rune_trigger_description() -> String:
	if not isHealRune:
		return 'When Dealt Damage'
	else:
		return 'When Recieving Healing'

func get_rune_tooltip() -> String:
	if not isHealRune:
		return "This Rune's effect is triggered when the enchanted combatant takes damage from any source."
	else:
		return "This Rune's effect is triggered when the enchanted combatant is healed from any source."

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	var triggered = false
	
	# catches easy cases such as post-round damage, other runes triggering
	if previousHp != -1:
		if not isHealRune:
			triggered = combatant.currentHp < previousHp
		else:
			triggered = combatant.currentHp > previousHp
	previousHp = combatant.currentHp
	
	# if the easy case didn't succeed and we're recieving damage:
	if not triggered and timing == BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG and len(otherCombatants) > 0:
		var user: Combatant = otherCombatants[0] if len(otherCombatants) > 0 else null
		# if the user has a command that already completed:
		if user != null and user.command != null and user.command.commandResult != null:
			var targetIdx: int = user.command.targets.find(combatant)
			# if this combatant was a target, the rune is triggered if this command dealt damage
			if targetIdx != -1:
				var dmgDealt: int = user.command.commandResult.damagesDealt[targetIdx]
				triggered = (dmgDealt > 0 and not isHealRune) or (dmgDealt < 0 and isHealRune)
			else:
				var interceptingIdx: int = user.command.interceptingTargets.find(combatant)
				# if this combatant intercepted, the rune is triggered if this command dealt damage
				if interceptingIdx != -1:
					var dmgDealt: int = user.command.commandResult.damageOnInterceptingTargets[interceptingIdx]
					triggered = (dmgDealt > 0 and not isHealRune) or (dmgDealt < 0 and isHealRune)
	return triggered

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
		isHealRune,
	)
	
	if copyStorage:
		rune.previousHp = previousHp
	
	return rune
