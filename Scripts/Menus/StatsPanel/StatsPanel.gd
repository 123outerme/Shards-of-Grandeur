extends Node2D
class_name StatsMenu

@export var stats: Stats = null
@export var curHp: int = -1
@export var readOnly: bool = false

@onready var statsTitle: RichTextLabel = get_node("StatsPanel/Panel/StatsTitle")
@onready var statlinePanel: StatLinePanel = get_node("StatsPanel/Panel/StatLinePanel")
@onready var moveListPanel: MoveListPanel = get_node("StatsPanel/Panel/MoveListPanel")
@onready var equipmentPanel: EquipmentPanel = get_node("StatsPanel/Panel/EquipmentPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle():
	visible = not visible
	if visible:
		load_stats_panel()
		
func load_stats_panel():
	if stats == null:
		return
	
	statsTitle.text = '[center]' + stats.displayName + ' - Stats[/center]'
	statlinePanel.stats = stats
	statlinePanel.curHp = curHp
	statlinePanel.readOnly = readOnly
	statlinePanel.load_statline_panel()
	moveListPanel.moves = stats.moves
	moveListPanel.movepool = stats.movepool
	moveListPanel.load_move_list_panel()
	equipmentPanel.weapon = stats.equippedWeapon
	equipmentPanel.armor = stats.equippedArmor
	equipmentPanel.load_equipment_panel()

func _on_back_button_pressed():
	toggle()
