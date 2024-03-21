extends Panel
class_name BattleStatsPanel

@export var combatant: Combatant = null
@export var battlePosition: String = ''

@onready var combatantName: RichTextLabel = get_node("CombatantName")
@onready var statusEffectText: RichTextLabel = get_node("StatusEffect")
@onready var orbDisplay: OrbDisplay = get_node('OrbDisplay')
@onready var statLinePanel: StatLinePanel = get_node("StatLinePanel")
@onready var equipmentPanel: EquipmentPanel = get_node("EquipmentPanel")

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
		statusEffectText.text = '[center]Experiencing ' + combatant.statusEffect.status_effect_to_string() + '[/center]'
	else:
		statusEffectText.text = ''
	
	equipmentPanel.weapon = combatant.stats.equippedWeapon
	equipmentPanel.armor = combatant.stats.equippedArmor
	equipmentPanel.load_equipment_panel()
