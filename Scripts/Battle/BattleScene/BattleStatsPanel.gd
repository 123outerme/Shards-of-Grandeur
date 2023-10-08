extends Panel
class_name BattleStatsPanel

@export var combatant: Combatant = null
@export var battlePosition: String = ''

@onready var combatantName: RichTextLabel = get_node("CombatantName")
@onready var statLinePanel: StatLinePanel = get_node("StatLinePanel")

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
	statLinePanel.stats = combatant.stats
	statLinePanel.readOnly = true
	statLinePanel.battleStats = true
	statLinePanel.curHp = combatant.currentHp
	statLinePanel.statChanges = combatant.statChanges
	statLinePanel.load_statline_panel()
