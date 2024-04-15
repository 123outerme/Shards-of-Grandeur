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
	equipmentPanel.load_equipment_panel()

func _on_status_help_button_pressed():
	if combatant.statusEffect != null:
		tooltipPanel.title = StatusEffect.status_type_to_string(combatant.statusEffect.type)
		tooltipPanel.details = combatant.statusEffect.get_status_effect_tooltip()
		tooltipPanel.load_tooltip_panel()

func _on_tooltip_panel_ok_pressed():
	statusHelpButton.grab_focus()
