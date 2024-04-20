extends Node2D
class_name StatsMenu

signal attempt_equip_weapon_to(stats: Stats)
signal attempt_equip_armor_to(stats: Stats)
signal back_pressed

@export_category("StatsPanel - Data")
@export var stats: Stats = null
@export var curHp: int = -1
@export var levelUp: bool = false
@export var newLvs: int = 0
@export var readOnly: bool = false
@export var isPlayer: bool = false

@export_category("StatsPanel - Audio")
@export var levelUpMusic: AudioStream = null

var isMinionStats: bool = false
var minion: Combatant = null
var savedStats: Stats = null
var savedCurHp: int = -1
var savedIsPlayer: bool = false
var changingCombatant: bool = false

var previousControl: Control = null
var previousMoveListSlot: int = -1

@onready var animatedCombatantSprite: AnimatedSprite2D = get_node("StatsPanel/Panel/AnimatedCombatantSprite")
@onready var statsTitle: RichTextLabel = get_node("StatsPanel/Panel/StatsTitle")
@onready var levelUpLabel: RichTextLabel = get_node("StatsPanel/Panel/LevelUpLabel")
@onready var statlinePanel: StatLinePanel = get_node("StatsPanel/Panel/StatLinePanel")
@onready var moveListPanel: MoveListPanel = get_node("StatsPanel/Panel/MoveListPanel")
@onready var equipmentPanel: EquipmentPanel = get_node("StatsPanel/Panel/EquipmentPanel")
@onready var minionsPanel: MinionsPanel = get_node("StatsPanel/Panel/MinionsPanel")
@onready var backButton: Button = get_node("StatsPanel/Panel/BackButton")
@onready var editMovesPanel: EditMovesPanel = get_node("StatsPanel/Panel/EditMovesPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline'):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func toggle():
	visible = not visible
	if visible:
		load_stats_panel(true)
		initial_focus()
	else:
		equipmentPanel.itemDetailsPanel.visible = false
		moveListPanel.moveDetailsPanel.visible = false
		editMovesPanel._on_back_button_pressed()
		minionsPanel.end_edit_name(false)
		minionsPanel.reset_reorder_state()
		backButton.disabled = false
		savedStats = null
		minion = null
		back_pressed.emit()

func initial_focus():
	backButton.grab_focus()

func restore_previous_focus():
	if previousControl == null:
		if previousMoveListSlot == -1:
			initial_focus()
		else:
			moveListPanel.get_move_list_item(previousMoveListSlot).detailsButton.grab_focus()
			previousMoveListSlot = -1
	else:
		previousControl.grab_focus()

func load_stats_panel(fromToggle: bool = false):
	if stats == null:
		return
		
	if fromToggle and levelUp and \
			not SceneLoader.audioHandler.is_music_already_playing(levelUpMusic):
		SceneLoader.audioHandler.play_music(levelUpMusic, -1)
	
	var dispName: String = stats.displayName
	if minion != null:
		dispName = minion.disp_name()
	
	var spriteFrames: SpriteFrames = PlayerResources.playerInfo.combatant.spriteFrames
	if minion != null:
		spriteFrames = minion.spriteFrames
	animatedCombatantSprite.sprite_frames = spriteFrames
	animatedCombatantSprite.play('walk')
	
	statsTitle.text = '[center]' + dispName + ' - Stats[/center]'
	levelUpLabel.visible = levelUp
	statlinePanel.stats = stats
	statlinePanel.curHp = curHp
	statlinePanel.readOnly = readOnly
	statlinePanel.levelUp = levelUp
	statlinePanel.newLvs = newLvs
	statlinePanel.load_statline_panel(changingCombatant or fromToggle)
	moveListPanel.moves = stats.moves
	moveListPanel.movepool = stats.movepool.pool
	moveListPanel.readOnly = readOnly
	moveListPanel.showNewMoveIndicator = levelUp and minion.stats.movepool.has_moves_at_level(minion.stats.level) \
			if minion != null else false
	moveListPanel.load_move_list_panel()
	equipmentPanel.weapon = stats.equippedWeapon
	equipmentPanel.armor = stats.equippedArmor
	equipmentPanel.statsPanel = self
	equipmentPanel.load_equipment_panel()
	minionsPanel.minion = minion
	minionsPanel.readOnly = readOnly
	minionsPanel.levelUp = levelUp
	minionsPanel.load_minions_panel()
	minionsPanel.call_deferred('connect_to_top_control', backButton)
	changingCombatant = false

func restore_previous_stats_panel():
	stats = savedStats
	minion = null
	curHp = savedCurHp
	isPlayer = savedIsPlayer
	isMinionStats = false
	changingCombatant = true
	load_stats_panel()
	restore_previous_focus()

func reset_panel_to_player():
	if isMinionStats:
		restore_previous_stats_panel()

func _on_back_button_pressed():
	if not isMinionStats or savedStats == null:
		toggle()
		if SceneLoader.audioHandler.is_music_already_playing(levelUpMusic):
			if SceneLoader.mapLoader != null and SceneLoader.mapLoader.mapEntry != null:
				SceneLoader.audioHandler.cross_fade(SceneLoader.mapLoader.mapEntry.overworldTheme)
			else:
				SceneLoader.audioHandler.cross_fade(null) # fade out the track
	else:
		restore_previous_stats_panel()

func _on_move_list_panel_move_details_visiblity_changed(newVisible: bool, move: Move):
	backButton.disabled = newVisible
	if newVisible:
		previousMoveListSlot = moveListPanel.get_index_of_move(move)
		previousControl = null
	else:
		restore_previous_focus()

func _on_minions_panel_stats_clicked(combatant: Combatant):
	previousControl = minionsPanel.get_stats_button_for(combatant)
	savedStats = stats
	savedCurHp = curHp
	savedIsPlayer = isPlayer
	if combatant != null and combatant.stats != null:
		minion = combatant
		stats = combatant.stats
		curHp = -1
		isPlayer = false
		isMinionStats = true
		changingCombatant = true
		load_stats_panel()
		backButton.grab_focus()

func _on_move_list_panel_edit_moves():
	previousControl = moveListPanel.editMovesButton
	editMovesPanel.moves = stats.moves
	editMovesPanel.movepool = stats.movepool.pool
	editMovesPanel.level = stats.level
	editMovesPanel.levelUp = levelUp
	editMovesPanel.load_edit_moves_panel()
	backButton.disabled = true

func _on_edit_moves_panel_back_pressed():
	backButton.disabled = false
	restore_previous_focus()

func _on_edit_moves_panel_replace_move(slot: int, newMove: Move):
	if slot >= len(stats.moves):
		for i in range(4):
			if slot == i:
				stats.moves.append(newMove)
			elif i >= len(stats.moves):
				stats.moves.append(null)
	else:
		stats.moves[slot] = newMove
	load_stats_panel()

func _on_equipment_panel_attempt_equip_weapon():
	if not readOnly:
		attempt_equip_weapon_to.emit(stats)

func _on_equipment_panel_attempt_equip_armor():
	if not readOnly:
		attempt_equip_armor_to.emit(stats)

func _on_inventory_panel_node_open_stats(combatant: Combatant):
	stats = combatant.stats
	if combatant == PlayerResources.playerInfo.combatant:
		isPlayer = true
		isMinionStats = false
	else:
		isPlayer = false
		isMinionStats = true
		minion = combatant
	curHp = combatant.currentHp
	toggle()
