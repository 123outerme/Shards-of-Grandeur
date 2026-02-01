extends Panel
class_name BattleStatsPanel

@export var combatant: Combatant = null
@export var battlePosition: String = ''
@export var combatantNode: CombatantNode
@export var allCombatantNodes: Array[CombatantNode]

@onready var combatantName: RichTextLabel = get_node("CombatantName")
@onready var statusSprite: Sprite2D = get_node('HBoxContainer/StatusIconControl/StatusSprite')
@onready var statusEffectText: RichTextLabel = get_node("HBoxContainer/StatusEffect")
@onready var statusHelpButton: Button = get_node('HBoxContainer/StatusHelpButton')
@onready var runesButton: Button = get_node('RunesButton')
@onready var orbDisplay: OrbDisplay = get_node('OrbDisplay')
@onready var statLinePanel: StatLinePanel = get_node("StatLinePanel")
@onready var elementWeaknessesText: RichTextLabel = get_node('ElementEffectivenessPanel/ElementWeaknessesText')
@onready var elementResistancesText: RichTextLabel = get_node('ElementEffectivenessPanel/ElementResistancesText')
@onready var elementDmgMultText: RichTextLabel = get_node('DmgBoostsMultPanel/HBoxContainer/ElementDmgMultText')
@onready var keywordDmgMultText: RichTextLabel = get_node('DmgBoostsMultPanel/HBoxContainer/KeywordDmgMultText')
@onready var equipmentIconsPanel: EquipmentIconsPanel = get_node("EquipmentIconsPanel")
@onready var battleRunesPanel: BattleRunesPanel = get_node('BattleRunesPanel')
@onready var tooltipPanel: TooltipPanel = get_node('TooltipPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_battle_stats_panel()

func load_battle_stats_panel():
	if combatant == null or combatantNode == null:
		visible = false
		return
	
	visible = true
	name = combatant.disp_name() + ' (' + battlePosition + ')'
	combatantName.text = '[center]' + combatant.disp_name() + '[/center]'
	orbDisplay.currentOrbs = combatant.orbs
	orbDisplay.update_orb_display()
	statLinePanel.stats = combatant.stats
	statLinePanel.readOnly = true
	statLinePanel.battleStats = true
	statLinePanel.curHp = combatant.currentHp
	statLinePanel.statChanges = combatant.statChanges
	statLinePanel.showExp = battlePosition == 'You' or battlePosition == 'Ally'
	statLinePanel.load_statline_panel()
	if combatant.statusEffect != null:
		statusSprite.texture = combatant.statusEffect.get_icon()
		statusSprite.visible = true
		statusEffectText.text = '[center]Experiencing ' + combatant.statusEffect.status_effect_to_string() + '[/center]'
		statusHelpButton.visible = true
	else:
		statusSprite.visible = false
		statusEffectText.text = ''
		statusHelpButton.visible = false
	
	runesButton.visible = len(combatant.runes) > 0
	
	equipmentIconsPanel.weapon = combatant.stats.equippedWeapon
	equipmentIconsPanel.armor = combatant.stats.equippedArmor
	equipmentIconsPanel.accessory = combatant.stats.equippedAccessory
	
	if combatant.statChanges != null:
		var elMultTexts: Array[StatMultiplierText] = combatant.statChanges.get_element_multiplier_texts()
		elementDmgMultText.text = '[center]' \
			+ StatMultiplierText.multiplier_text_list_to_newlined_string(elMultTexts) + '[/center]'
		var keywordMultTexts: Array[StatMultiplierText] = combatant.statChanges.get_keyword_multiplier_texts()
		keywordDmgMultText.text ='[center]' \
			+ StatMultiplierText.multiplier_text_list_to_newlined_string(keywordMultTexts) + '[/center]'
	
	var evolution: Evolution = combatant.get_evolution()
	var hasBeatenStoryReq: StoryRequirements = StoryRequirements.new()
	if evolution != null:
		hasBeatenStoryReq.prereqDefeatedEnemies = [combatant.save_name() + '#' + evolution.evolutionSaveName]
	else:
		hasBeatenStoryReq.prereqDefeatedEnemies = [combatant.save_name()]
	
	if hasBeatenStoryReq.is_valid() or combatantNode.role == CombatantNode.Role.ALLY or combatant.save_name() == 'player':
		elementWeaknessesText.text = '[center]'
		var elementWeaknesses: Array[Move.Element] = combatant.get_element_weaknesses()
		if len(elementWeaknesses) > 0:
			elementWeaknessesText.text += 'Weak to '
			for idx in range(len(elementWeaknesses)):
				elementWeaknessesText.text += Move.element_to_string(elementWeaknesses[idx])
				if idx < len(elementWeaknesses) - 1:
					elementWeaknessesText.text += ', '
			elementWeaknessesText.text += '[/center]'
		else:
			elementWeaknessesText.text = '[center]No Weaknesses[/center]'
		elementResistancesText.text = '[center]'
		var elementResistances: Array[Move.Element] = combatant.get_element_resistances()
		if len(elementResistances) > 0:
			elementResistancesText.text += 'Resistant to '
			for idx in range(len(elementResistances)):
				elementResistancesText.text += Move.element_to_string(elementResistances[idx])
				if idx < len(elementResistances) - 1:
					elementResistancesText.text += ', '
			elementResistancesText.text += '[/center]'
		else:
			elementResistancesText.text = '[center]No Resistances[/center]'
	else:
		elementWeaknessesText.text = '[center]Weak to ???[/center]'
		elementResistancesText.text = '[center]Resistant to ???[/center]'
	
	equipmentIconsPanel.load_equipment_icons_panel()

func _on_status_help_button_pressed():
	if combatant.statusEffect != null:
		tooltipPanel.title = combatant.statusEffect.get_status_type_string()
		tooltipPanel.details = combatant.statusEffect.get_status_effect_tooltip()
		tooltipPanel.load_tooltip_panel()

func _on_tooltip_panel_ok_pressed():
	statusHelpButton.grab_focus()

func _on_runes_button_pressed() -> void:
	battleRunesPanel.combatantNode = combatantNode
	battleRunesPanel.allCombatantNodes = allCombatantNodes
	battleRunesPanel.load_battle_runes_panel()
	battleRunesPanel.initial_focus()

func _on_battle_runes_panel_back_pressed() -> void:
	runesButton.grab_focus()
