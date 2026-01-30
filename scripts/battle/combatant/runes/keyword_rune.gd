extends Rune
class_name KeywordRune

@export var keyword: String = ''

@export var mustDealDamage: bool = false

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
	i_triggerAnims: Array[MoveAnimSprite] = [],
	i_keyword: String = '',
	i_mustDealDamage: bool = false,
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnims)
	keyword = i_keyword
	mustDealDamage = i_mustDealDamage

func get_rune_type() -> String:
	return 'Keyword Rune'

func get_long_rune_type() -> String:
	return keyword + ' Rune'

func get_rune_trigger_description() -> String:
	var singularArticle: String = 'A'
	if not mustDealDamage:
		var keywordLower: String = keyword.to_lower()
		if keywordLower.begins_with('a') or \
				keywordLower.begins_with('e') or \
				keywordLower.begins_with('i') or \
				keywordLower.begins_with('o') or \
				keywordLower.begins_with('u'):
			singularArticle = 'An'
	
	return 'When ' + singularArticle + ' ' + \
			('Damaging ' if mustDealDamage else '') + \
			keyword + ' Move is Used'

func get_rune_tooltip() -> String:
	var singularArticle: String = 'a'
	if not mustDealDamage:
		var keywordLower: String = keyword.to_lower()
		if keywordLower.begins_with('a') or \
				keywordLower.begins_with('e') or \
				keywordLower.begins_with('i') or \
				keywordLower.begins_with('o') or \
				keywordLower.begins_with('u'):
			singularArticle = 'an'
	
	return "This Rune's effect triggers when " + singularArticle + " " + \
			("Damaging " if mustDealDamage else "") + \
			keyword + " Move is used on the enchanted combatant."

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC and combatant.command != null and combatant.command.type == BattleCommand.Type.MOVE:
		var moveEffect: MoveEffect = combatant.command.move.get_effect_of_type(combatant.command.moveEffectType)
		if moveEffect != null:
			return keyword in moveEffect.keywords and (not mustDealDamage or moveEffect.power > 0)
		
	return false

func copy(copyStorage: bool = false) -> KeywordRune:
	var rune: KeywordRune = KeywordRune.new(
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
		triggerAnims,
		keyword,
		mustDealDamage,
	)
	
	return rune
