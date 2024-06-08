extends Panel
class_name BattleStatsPanel

@export var combatant: Combatant = null
@export var battlePosition: String = ''

@onready var combatantName: RichTextLabel = get_node("CombatantName")
@onready var statusSprite: Sprite2D = get_node('HBoxContainer/StatusIconControl/StatusSprite')
@onready var statusEffectText: RichTextLabel = get_node("HBoxContainer/StatusEffect")
@onready var statusHelpButton: Button = get_node('HBoxContainer/StatusHelpButton')
@onready var orbDisplay: OrbDisplay = get_node('OrbDisplay')
@onready var statLinePanel: StatLinePanel = get_node("StatLinePanel")
@onready var elementEffectivenessText: RichTextLabel = get_node('ElementEffectivenessPanel/ElementEffectivenessText')
@onready var elementDmgMultText: RichTextLabel = get_node('ElementDmgMultPanel/ElementDmgMultText')
@onready var equipmentPanel: EquipmentPanel = get_node("EquipmentPanel")
@onready var tooltipPanel: TooltipPanel = get_node('TooltipPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_battle_stats_panel()

func load_battle_stats_panel():
	if combatant == null:
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
	
	equipmentPanel.weapon = combatant.stats.equippedWeapon
	equipmentPanel.armor = combatant.stats.equippedArmor
	
	var elMultTexts: Array[StatMultiplierText] = []
	if combatant.statChanges != null:
		elMultTexts = combatant.statChanges.get_element_multiplier_texts()
	elementDmgMultText.text = '[center]Element Damage Boosts:\n' \
			+ StatMultiplierText.multiplier_text_list_to_string(elMultTexts) + '[/center]'
	
	var hasBeatenStoryReq: StoryRequirements = StoryRequirements.new()
	hasBeatenStoryReq.prereqDefeatedEnemies = [combatant.save_name()]
	if hasBeatenStoryReq.is_valid() or combatant.save_name() == 'player':
		elementEffectivenessText.text = '[center]'
		var hasText: bool = false
		var elementWeaknesses: Array[Move.Element] = combatant.get_element_weaknesses()
		if len(elementWeaknesses) > 0:
			hasText = true
			elementEffectivenessText.text += 'Weak to '
			for idx in range(len(elementWeaknesses)):
				elementEffectivenessText.text += Move.element_to_string(elementWeaknesses[idx])
				if idx < len(elementWeaknesses) - 1:
					elementEffectivenessText.text += ', '
			elementEffectivenessText.text += '\n'
		var elementResistances: Array[Move.Element] = combatant.get_element_resistances()
		if len(elementResistances) > 0:
			hasText = true
			elementEffectivenessText.text += 'Resistant to '
			for idx in range(len(elementWeaknesses)):
				elementEffectivenessText.text += Move.element_to_string(elementResistances[idx])
				if idx < len(elementResistances) - 1:
					elementEffectivenessText.text += ', '
			elementEffectivenessText.text += '\n'
		
		if not hasText:
			elementEffectivenessText.text += 'No Weaknesses or Resistances'
		
		elementEffectivenessText.text += '[/center]'
	else:
		elementEffectivenessText.text = '[center]Weak to ???\nResistant to ???[/center]'
	
	equipmentPanel.load_equipment_panel()

func _on_status_help_button_pressed():
	if combatant.statusEffect != null:
		tooltipPanel.title = combatant.statusEffect.get_status_type_string()
		tooltipPanel.details = combatant.statusEffect.get_status_effect_tooltip()
		tooltipPanel.load_tooltip_panel()

func _on_tooltip_panel_ok_pressed():
	statusHelpButton.grab_focus()
