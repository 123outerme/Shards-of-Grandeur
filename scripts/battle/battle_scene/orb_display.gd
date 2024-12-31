extends Control
class_name OrbDisplay

enum OrbParticlesMode {
	OFF = 0, ## don't play particles on orb count change
	AS_CONTROL = 1, ## play the "gain" particles on both orb count increase and decrease, but only play it for the highest orb after update
	ALL = 2 ## play the "gain" particles on orb count increase, play the "spend" animation on decrease
}

signal orb_count_change(change: int)

@export var alignment: BoxContainer.AlignmentMode = BoxContainer.ALIGNMENT_BEGIN
@export var currentOrbs: int = 0
@export var readOnly: bool = true
@export_range(0, Combatant.MAX_ORBS - 1) var minOrbs: int = 0
@export_range(1, Combatant.MAX_ORBS) var maxOrbs: int = Combatant.MAX_ORBS
@export_range(1, Combatant.MAX_ORBS) var softMaxOrbs: int = Combatant.MAX_ORBS
@export var modifySfx: AudioStream = null
@export var atBoundSfx: AudioStream = null
@export var particlesMode: OrbParticlesMode = OrbParticlesMode.OFF

#const orbUnitDisplayScene: PackedScene = preload('res://prefabs/battle/orb_unit_display.tscn')
const ORB_INTERACT_INTERVAL = 7
const ORB_SFX_INTERVAL = 0.09

var lastInputAccum: int = 0
var lastSfxTriggered: float = 0
var focused: bool = false
var lastOrbClicked: int = -1
var lastOrbHovered: int = -1

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
	if (Input.is_action_pressed('ui_right') or Input.is_action_pressed('ui_repeat_right')) and lastInputAccum <= 0:
		update_orb_count(currentOrbs + 1)
		lastInputAccum = ORB_INTERACT_INTERVAL
	if (Input.is_action_pressed('ui_left') or Input.is_action_pressed('ui_repeat_left')) and lastInputAccum <= 0:
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
		unit.being_hovered.connect(_orb_hovered)
	update_orb_display()

func update_orb_display():
	var orbUnits = hboxContainer.get_children()
	for idx in range(len(orbUnits)):
		var unit: OrbUnitDisplay = orbUnits[idx] as OrbUnitDisplay
		unit.filledOrb = idx < currentOrbs if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx <= currentOrbs
		unit.cannotSpend = (idx >= softMaxOrbs if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx > softMaxOrbs) and not readOnly
		unit.readOnly = readOnly \
				or (idx if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx - 1) < minOrbs - 1 \
				or (idx if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx - 1) >= maxOrbs
		unit.load_orb_unit_display()

func get_orb_unit_at_count(orbCount: int) -> OrbUnitDisplay:
	if orbCount < 1 or orbCount > Combatant.MAX_ORBS:
		return null
	var orbIdx: int = orbCount
	if alignment == BoxContainer.AlignmentMode.ALIGNMENT_END:
		orbIdx = Combatant.MAX_ORBS - orbIdx
	else:
		orbIdx -= 1
	# orbIdx is now a number in the range [0, MAX_ORBS - 1]
	var orbUnits = hboxContainer.get_children()
	return orbUnits[orbIdx]

func update_orb_count(orbs: int, playSfx: bool = true, playParticles: bool = true) -> void:
	var setOrbs: int = max(minOrbs, min(orbs, maxOrbs)) # bound orbs between min & max
	if setOrbs != currentOrbs:
		orb_count_change.emit(setOrbs)
		if playSfx and SceneLoader.audioHandler != null and Time.get_unix_time_from_system() - lastSfxTriggered > ORB_SFX_INTERVAL:
			SceneLoader.audioHandler.play_sfx(modifySfx)
			lastSfxTriggered = Time.get_unix_time_from_system()
		if playParticles and ((setOrbs > currentOrbs and particlesMode == OrbParticlesMode.ALL) or particlesMode == OrbParticlesMode.AS_CONTROL):
			if particlesMode == OrbParticlesMode.ALL:
				# if playing all: play the gain particles for each new orb
				for orbCount: int in range(currentOrbs + 1, setOrbs + 1):
					var orbUnit: OrbUnitDisplay = get_orb_unit_at_count(orbCount)
					if orbUnit != null:
						orbUnit.play_gain_particles()
			else:
				# if playing particles in "Control" mode: only play a particle at the highest post-update orb
				var orbUnit: OrbUnitDisplay = get_orb_unit_at_count(setOrbs)
				if orbUnit != null:
					orbUnit.play_gain_particles()
		elif playParticles and setOrbs < currentOrbs and particlesMode == OrbParticlesMode.ALL:
			# if the particles mode is ALL and orbs have decreased: play the spend particles on the previous highest orb
			# 0.2s lifetime per orb being spent
			var duration: float = (currentOrbs - setOrbs) * 0.2
			var count: int = 4
			if currentOrbs - setOrbs < 3:
				# new particle count is 1 spent => 2, or 2 spent => 3, else use 4 particles
				count = 1 + (currentOrbs - setOrbs)
			var orbUnit: OrbUnitDisplay = get_orb_unit_at_count(currentOrbs)
			if orbUnit != null:
				orbUnit.play_spend_particles(duration, count, alignment == BoxContainer.AlignmentMode.ALIGNMENT_END)
	elif playSfx and SceneLoader.audioHandler != null:
		SceneLoader.audioHandler.play_sfx(atBoundSfx)
	currentOrbs = setOrbs
	update_orb_display()

func _orb_clicked(index: int) -> void:
	# index is [1, Combatant.MAX_ORBS]
	lastOrbClicked = index
	var orbCount = index if alignment != BoxContainer.ALIGNMENT_END else hboxContainer.get_child_count() + 1 - index
	update_orb_count(orbCount)
	#print('clicked on ', orbCount, ' orbs')
	if not selectedPanel.visible:
		selectedPanel.visible = true
		grab_focus()

func _orb_hovered(index: int) -> void:
	lastOrbHovered = index

func _input(event) -> void:
	if focused and event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and lastOrbHovered != lastOrbClicked and lastOrbHovered != -1:
			_orb_clicked(lastOrbHovered)

func _on_focus_entered() -> void:
	focused = true

func _on_focus_exited() -> void:
	focused = false
