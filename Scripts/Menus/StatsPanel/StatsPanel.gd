extends Node2D
class_name StatsMenu

signal back_pressed

@export var stats: Stats = null
@export var curHp: int = -1
@export var levelUp: bool = false
@export var readOnly: bool = false
@export var isPlayer: bool = false

var isMinionStats: bool = false
var savedStats: Stats = null
var savedCurHp: int = -1
var savedLvUp: bool = false
var savedIsPlayer: bool = false

@onready var statsTitle: RichTextLabel = get_node("StatsPanel/Panel/StatsTitle")
@onready var levelUpLabel: RichTextLabel = get_node("StatsPanel/Panel/LevelUpLabel")
@onready var statlinePanel: StatLinePanel = get_node("StatsPanel/Panel/StatLinePanel")
@onready var moveListPanel: MoveListPanel = get_node("StatsPanel/Panel/MoveListPanel")
@onready var equipmentPanel: EquipmentPanel = get_node("StatsPanel/Panel/EquipmentPanel")
@onready var minionsPanel: MinionsPanel = get_node("StatsPanel/Panel/MinionsPanel")
@onready var backButton: Button = get_node("StatsPanel/Panel/BackButton")

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
	levelUpLabel.visible = levelUp
	statlinePanel.stats = stats
	statlinePanel.curHp = curHp
	statlinePanel.readOnly = readOnly
	statlinePanel.load_statline_panel()
	moveListPanel.moves = stats.moves
	moveListPanel.movepool = stats.movepool
	moveListPanel.readOnly = readOnly
	moveListPanel.load_move_list_panel()
	equipmentPanel.weapon = stats.equippedWeapon
	equipmentPanel.armor = stats.equippedArmor
	equipmentPanel.statsPanel = self
	equipmentPanel.load_equipment_panel()
	if isPlayer:
		minionsPanel.readOnly = readOnly
		minionsPanel.visible = true
		minionsPanel.load_minions_panel()
	else:
		minionsPanel.visible = false

func _on_back_button_pressed():
	if not isMinionStats:
		toggle()
		back_pressed.emit()
	else:
		restore_previous_stats_panel()

func restore_previous_stats_panel():
	stats = savedStats
	curHp = savedCurHp
	levelUp = savedLvUp
	isPlayer = savedIsPlayer
	isMinionStats = false
	load_stats_panel()

func _on_move_list_panel_move_details_visiblity_changed(newVisible: bool):
	backButton.disabled = newVisible

func _on_minions_panel_stats_clicked(combatant: Combatant):
	savedStats = stats
	savedCurHp = curHp
	savedLvUp = levelUp
	savedIsPlayer = isPlayer
	if combatant != null and combatant.stats != null:
		stats = combatant.stats
		curHp = -1
		levelUp = false
		isPlayer = false
		isMinionStats = true
		load_stats_panel()
