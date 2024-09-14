extends Control
class_name OrbDisplay

enum OrbParticlesMode {
	OFF = 0, ## don't play particles on orb count change
	ONLY_GAIN = 1, ## play the "gain" particles on both orb count increase and decrease
	ALL = 2 ## play the "gain" particles on orb count increase, play the "spend" animation on decrease
}

signal orb_count_change(change: int)

@export var alignment: BoxContainer.AlignmentMode = BoxContainer.ALIGNMENT_BEGIN
@export var currentOrbs: int = 0
@export var readOnly: bool = true
@export_range(0, Combatant.MAX_ORBS - 1) var minOrbs: int = 0
@export_range(1, Combatant.MAX_ORBS) var maxOrbs: int = Combatant.MAX_ORBS
@export var modifySfx: AudioStream = null
@export var atBoundSfx: AudioStream = null
@export var gainParticlePreset: ParticlePreset = null
@export var spendParticlePreset: ParticlePreset = null
@export var particlesMode: OrbParticlesMode = OrbParticlesMode.OFF
@export var firstOrbParticlePos: Vector2 = Vector2(6, 6)

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
@onready var particleEmitter: Particles = get_node('ParticleEmitter')

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
		unit.readOnly = readOnly \
				or (idx if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx - 1) < minOrbs - 1 \
				or (idx if alignment != BoxContainer.ALIGNMENT_END else len(orbUnits) - idx - 1) >= maxOrbs
		unit.load_orb_unit_display()

func update_orb_count(orbs: int, playSfx: bool = true, playParticles: bool = true):
	var setOrbs = max(minOrbs, min(orbs, maxOrbs)) # bound orbs between min & max
	if setOrbs != currentOrbs:
		orb_count_change.emit(setOrbs)
		if playSfx and SceneLoader.audioHandler != null and Time.get_unix_time_from_system() - lastSfxTriggered > ORB_SFX_INTERVAL:
			SceneLoader.audioHandler.play_sfx(modifySfx)
			lastSfxTriggered = Time.get_unix_time_from_system()
		if playParticles and ((setOrbs > currentOrbs and particlesMode == OrbParticlesMode.ALL) or particlesMode == OrbParticlesMode.ONLY_GAIN):
			update_particle_emitter_pos(setOrbs)
			particleEmitter.preset = gainParticlePreset
			particleEmitter.set_make_particles(true)
		elif playParticles and setOrbs < currentOrbs and particlesMode == OrbParticlesMode.ALL:
			# if particles mode is ALL: only play the gain particles if the amount has increased
			# if particles mode is ONLY_GAIN: play the gain particles if the amount has changed in any way
			update_particle_emitter_pos(currentOrbs)
			var spendPresetCopy: ParticlePreset = spendParticlePreset.duplicate(true)
			# 0.2s lifetime per orb being spent
			spendPresetCopy.lifetime = (currentOrbs - setOrbs) * 0.2
			# if orbs spent is less than 3:
			if currentOrbs - setOrbs < 3:
				# new particle count is 1 spent => 2, or 2 spent => 3 
				spendPresetCopy.count = 1 + (currentOrbs - setOrbs)
			if alignment == BoxContainer.AlignmentMode.ALIGNMENT_END:
				spendPresetCopy.processMaterial.direction.x *= -1
				spendPresetCopy.processMaterial.emission_shape_offset.x = -2
			particleEmitter.preset = spendPresetCopy
			particleEmitter.set_make_particles(true)
	elif playSfx and SceneLoader.audioHandler != null:
		SceneLoader.audioHandler.play_sfx(atBoundSfx)
	currentOrbs = setOrbs
	update_orb_display()

func update_particle_emitter_pos(orb: int):
	if orb < 1 or orb > Combatant.MAX_ORBS:
		return
	if alignment == BoxContainer.AlignmentMode.ALIGNMENT_END:
		orb = Combatant.MAX_ORBS - orb
	else:
		orb -= 1
	const ORB_WIDTH_PLUS_OFFSET: int = 9 # 8px orb width, plus 1 for the HBoxContainer offset
	particleEmitter.position = firstOrbParticlePos + Vector2(ORB_WIDTH_PLUS_OFFSET * orb, 0)

func _orb_clicked(index: int):
	# index is [1, Combatant.MAX_ORBS]
	lastOrbClicked = index
	var orbCount = index if alignment != BoxContainer.ALIGNMENT_END else hboxContainer.get_child_count() + 1 - index
	update_orb_count(orbCount)
	#print('clicked on ', orbCount, ' orbs')
	if not selectedPanel.visible:
		selectedPanel.visible = true
		grab_focus()

func _orb_hovered(index: int):
	lastOrbHovered = index

func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and lastOrbHovered != lastOrbClicked and lastOrbHovered != -1:
			_orb_clicked(lastOrbHovered)

func _on_focus_entered():
	focused = true

func _on_focus_exited():
	focused = false
