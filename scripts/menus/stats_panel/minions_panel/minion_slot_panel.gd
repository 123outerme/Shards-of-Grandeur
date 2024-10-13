extends Panel
class_name MinionSlotPanel

signal stats_clicked(combatant: Combatant)
signal reorder_clicked(combatant: Combatant)
signal panel_ready
signal changed_minion_hovered(combatant: Combatant)

@export var combatant: Combatant = null
@export var readOnly: bool = false
@export var showReorderButton: bool = false
@export var reorderButtonIsTarget: bool = false
@export var reorderButtonIsCancel: bool = false
@export var levelUp: bool = false

var readyCallback: Callable

@onready var minionSprite: AnimatedSprite2D = get_node("SpriteControl/MinionSprite")
@onready var minionName: RichTextLabel = get_node("MinionName")
@onready var changedIndicator: Control = get_node("HBoxContainer/VBoxContainer3/ChangedIndicatorControl")
@onready var statPtIndicator: Control = get_node("HBoxContainer/VBoxContainer/StatPtIndicatorControl")
@onready var newMoveIndicator: Control = get_node("HBoxContainer/VBoxContainer2/MoveIndicatorControl")
@onready var reorderButton: Button = get_node('HBoxContainer/ReorderButton')
@onready var statsButton: Button = get_node("HBoxContainer/StatsButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_minion_slot_panel()
	
func load_minion_slot_panel():
	if combatant == null:
		visible = false
		return
	
	minionSprite.sprite_frames = combatant.get_sprite_frames()
	if minionSprite.sprite_frames == null:
		minionSprite.sprite_frames = load('res://graphics/animations/a_missingno.tres') # prevent crashing
	if combatant.get_idle_size().x > 32 and combatant.get_idle_size().y > 32:
		minionSprite.scale = Vector2.ONE
	minionSprite.play('battle_idle')
	minionName.text = combatant.disp_name()
	changedIndicator.visible = not readOnly and PlayerResources.minions.is_minion_marked_changed(combatant.save_name())
	statPtIndicator.visible = not readOnly and combatant.stats.statPts > 0 and not changedIndicator.visible
	reorderButton.visible = showReorderButton
	if reorderButtonIsTarget:
		reorderButton.text = 'Move Here'
	elif reorderButtonIsCancel:
		reorderButton.text = 'Cancel'
	else:
		reorderButton.text = 'Reorder'
	if levelUp:
		newMoveIndicator.visible = combatant.stats.movepool.has_moves_at_level(combatant.stats.level) and not changedIndicator.visible
	else:
		newMoveIndicator.visible = false
	
	panel_ready.emit()

func connect_to_above_panel(abovePanel: MinionSlotPanel, resetBelowFocusNeighbor: bool = false) -> void:
	statsButton.focus_neighbor_top = statsButton.get_path_to(abovePanel.statsButton)
	abovePanel.statsButton.focus_neighbor_bottom = abovePanel.statsButton.get_path_to(statsButton)
	reorderButton.focus_neighbor_top = reorderButton.get_path_to(abovePanel.reorderButton)
	abovePanel.reorderButton.focus_neighbor_bottom = abovePanel.reorderButton.get_path_to(reorderButton)
	
	if resetBelowFocusNeighbor:
		statsButton.focus_neighbor_bottom = ''
		reorderButton.focus_neighbor_bottom = ''

func _on_stats_button_pressed():
	stats_clicked.emit(combatant)

func _on_reorder_button_pressed():
	reorder_clicked.emit(combatant)
	
func _on_reorder_button_focus_exited() -> void:
	if changedIndicator.visible:
		changed_minion_hovered.emit(combatant)
		changedIndicator.visible = false

func _on_stats_button_focus_exited() -> void:
	if changedIndicator.visible:
		changed_minion_hovered.emit(combatant)
		changedIndicator.visible = false
