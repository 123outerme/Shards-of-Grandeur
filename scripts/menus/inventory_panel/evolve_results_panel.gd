extends TooltipPanel
class_name EvolveResultsPanel

@export var combatant: Combatant
@export var newEvolution: Evolution
@export var prevEvolution: Evolution
@export var equipment: Item
@export var switchEvolutionFlags: int = 0
@export var combatantLosingEvolving: Combatant = null

@onready var combatantSprite: AnimatedSprite2D = get_node('Panel/CombatantSpriteControl/CombatantSprite')
@onready var evolveChangesText: RichTextLabel = get_node('Panel/EvolveChangesText')
@onready var evolveChangesUnderline: Line2D = get_node('Panel/EvolveChangesText/Line2D')

func load_evolve_results_panel():
	var prevEvolutionStats: Stats = combatant.get_evolution_stats(prevEvolution)
	var nickNameOrPrevDispName: String = combatant.nickname if combatant.nickname != '' else prevEvolutionStats.displayName
	
	if newEvolution != null:
		title = nickNameOrPrevDispName + ' Evolved Into ' + newEvolution.stats.displayName + '!'
		details = 'By equipping the ' + equipment.itemName \
				+ ', ' + nickNameOrPrevDispName + ' has become ' + newEvolution.stats.displayName + '!'
	else:
		title = combatant.disp_name() + ' Reverted to Base'
		details = 'By unequipping the ' + equipment.itemName \
				+ ', ' + nickNameOrPrevDispName + ' has reverted back to base form.'
	
	if combatantLosingEvolving != null:
		var combatantLosingEvolution: Evolution = combatantLosingEvolving.get_evolution()
		var combatantLosingForm: String = 'base form' if combatantLosingEvolution == null else combatantLosingEvolving.stats.displayName
		details += '\n' + combatantLosingEvolving.disp_name() + ' unequipped the ' + equipment.itemName + ' and reverted back to ' + combatantLosingForm + '.'
	
	# if stats were changed, tell the player
	if switchEvolutionFlags != 0:
		var pronounSingularCap: String = 'It'
		var pronounSingular: String = 'it'
		var pronounPossesive: String = 'its'
		var toHaveConjugation: String = 'has'
		if combatant.save_name() == 'player':
			pronounSingularCap = 'You'
			pronounSingular = 'you'
			pronounPossesive = 'your'
			toHaveConjugation = 'have'
		
		evolveChangesText.text = '[center]This form has changed since it last saw battle:'
		var changesStrings: Array[String] = []
		if switchEvolutionFlags & 1 == 1: # 0b00001
			if (switchEvolutionFlags >> 4) & 1 == 1: # 0b10000
				changesStrings.append(pronounSingularCap + ' auto-allocated some Stat Points!')
			else:
				changesStrings.append(pronounSingularCap + ' may have Stat Points to allocate!')
		if (switchEvolutionFlags >> 1) & 1 == 1: # 0b00010
			changesStrings.append(pronounSingularCap + ' now ' + toHaveConjugation + ' different moves in this form.')
		if (switchEvolutionFlags >> 2) & 1 == 1: # 0b00100
			var forgotStr: String = pronounSingularCap + ' forgot how to use some moves'
			if (switchEvolutionFlags >> 3) & 1 == 1: # 0b01000
				forgotStr += ', so ' + pronounSingular + ' completely changed up ' + pronounPossesive + ' moveset!'
			else:
				forgotStr += '.'
			changesStrings.append(forgotStr)
		for change in changesStrings:
			evolveChangesText.text += '\n' + change
		evolveChangesText.text += '[/center]'
		evolveChangesUnderline.visible = true
	else:
		evolveChangesText.text = ''
		evolveChangesUnderline.visible = false
	
	combatantSprite.sprite_frames = combatant.get_sprite_frames()
	if combatant.get_idle_size().y <= 32:
		combatantSprite.scale = Vector2(3, 3)
	elif combatant.get_idle_size().y < 48:
		combatantSprite.scale = Vector2(2, 2)
	else:
		combatantSprite.scale = Vector2(2, 2)
	combatantSprite.play('battle_idle')
	load_tooltip_panel()
