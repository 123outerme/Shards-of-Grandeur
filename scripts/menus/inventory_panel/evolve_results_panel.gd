extends TooltipPanel
class_name EvolveResultsPanel

@export var combatant: Combatant
@export var newEvolution: Evolution
@export var prevEvolution: Evolution
@export var equipment: Item
@export var switchEvolutionFlags: int = 0
@export var combatantLosingEvolving: Combatant = null

@onready var combatantSprite: AnimatedSprite2D = get_node('Panel/CombatantSpriteControl/CombatantSprite')

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
		details += '\n' + combatantLosingEvolving.disp_name() + ' unequipped the ' + equipment.itemName + ' and reverted back to base form.'
	
	# if stats were changed, tell the player
	if switchEvolutionFlags != 0:
		details += ' This form has grown since it has last seen battle:'
		var changesStrings: Array[String] = []
		if switchEvolutionFlags & 1 == 1: # 0b0001
			changesStrings.append('It may have Stat Points to allocate!')
		if (switchEvolutionFlags >> 1) & 1 == 1: # 0b0010
			changesStrings.append('It has different moves in this form.')
		if (switchEvolutionFlags >> 2) & 1 == 1: # 0b0100
			var forgotStr: String = 'It forgot how to use some moves'
			if (switchEvolutionFlags >> 3) & 1 == 1: # 0b1000
				forgotStr += ', so it completely changed up its moveset!'
			else:
				forgotStr += '.'
			changesStrings.append(forgotStr)
		for change in changesStrings:
			details += '\n' + change
	
	combatantSprite.sprite_frames = combatant.get_sprite_frames()
	if combatant.get_idle_size().x <= 16 and combatant.get_idle_size().y <= 16:
		combatantSprite.scale = Vector2(3, 3)
	elif combatant.get_idle_size().x < 48 and combatant.get_idle_size().y < 48:
		combatantSprite.scale = Vector2(2, 2)
	else:
		combatantSprite.scale = Vector2(2, 2)
	combatantSprite.play('battle_idle')
	load_tooltip_panel()
