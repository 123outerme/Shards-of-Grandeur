extends Control
class_name OrbDisplay

signal orb_count_change(change: int)

@export var alignment: BoxContainer.AlignmentMode = BoxContainer.ALIGNMENT_BEGIN
@export var currentOrbs: int = 0
@export var readOnly: bool = true
@export_range(0, Combatant.MAX_ORBS - 1) var minOrbs: int = 0
@export_range(1, Combatant.MAX_ORBS) var maxOrbs: int = Combatant.MAX_ORBS
@export var modifySfx: AudioStream = null
@export var atBoundSfx: AudioStream = null

#const orbUnitDisplayScene: PackedScene = preload('res://prefabs/battle/orb_unit_display.tscn')
const ORB_INTERACT_INTERVAL = 7

var lastInputAccum: int = 0
var focused = false

@onready var hboxContainer: HBoxContainer = get_node('HBoxContainer')
@onready var selectedPanel: Panel = get_node('SelectedPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_orb_display()

func _process(delta):
	selectedPanel.visible = focused
	if not focused:
		return
	lastInputAccum = max(-1, lastInputAccum - delta)
	if Input.is_action_pressed('ui_right') and lastInputAccum <= 0:
		update_orb_count(currentOrbs + 1)
		lastInputAccum = ORB_INTERACT_INTERVAL
	if Input.is_action_pressed('ui_left') and lastInputAccum <= 0:
		update_orb_count(currentOrbs - 1)
		lastInputAccum = ORB_INTERACT_INTERVAL

func load_orb_display():
	focus_mode = Control.FOCUS_NONE if readOnly else Control.FOCUS_ALL 
	hboxContainer.alignment = alignment
	'''
	for i in range(Combatant.MAX_ORBS):
		var orbUnit: OrbUnitDisplay = orbUnitDisplayScene.instantiate()
		hboxContainer.add_child(orbUnit)
	'''
	var orbUnits = hboxContainer.get_children()
	for idx in range(len(orbUnits)):
		var unit: OrbUnitDisplay = orbUnits[idx] as OrbUnitDisplay
		unit.readOnly = readOnly
		unit.index = idx + 1
		unit.orb_clicked.connect(_orb_clicked)
	update_orb_display()

func update_orb_display():
	var orbUnits = hboxContainer.get_children()
	for idx in range(len(orbUnits)):
		var unit: OrbUnitDisplay = orbUnits[idx] as OrbUnitDisplay
		unit.filledOrb = idx < currentOrbs if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx <= currentOrbs
		unit.readOnly = readOnly \
				or (idx if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx - 1) < minOrbs - 1 \
				or (idx if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx - 1) >= maxOrbs
		unit.load_orb_unit_display()

func update_orb_count(orbs: int, playSfx: bool = true):
	var setOrbs = max(minOrbs, min(orbs, maxOrbs)) # bound orbs between min & max
	if setOrbs != currentOrbs:
		orb_count_change.emit(setOrbs)
		if SceneLoader.audioHandler != null:
			SceneLoader.audioHandler.play_sfx(modifySfx)
	elif SceneLoader.audioHandler != null:
		SceneLoader.audioHandler.play_sfx(atBoundSfx)
	currentOrbs = setOrbs
	update_orb_display()
	

func _orb_clicked(index: int):
	# index is [1, Combatant.MAX_ORBS]
	var orbCount = index if alignment != BoxContainer.ALIGNMENT_END else hboxContainer.get_child_count() + 1 - index
	update_orb_count(orbCount)
	#print('clicked on ', orbCount, ' orbs')
	if not selectedPanel.visible:
		selectedPanel.visible = true
		grab_focus()

func _on_focus_entered():
	focused = true

func _on_focus_exited():
	focused = false
