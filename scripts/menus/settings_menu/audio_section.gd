extends Control
class_name AudioSection

@export var sfxIncreaseTestSound: AudioStream = null

const SFX_COOLDOWN: float = 0.15
var firstSfxValueChange: bool = true
var sfxPlayTimer: float = SFX_COOLDOWN

@onready var musicVolumeLabel: RichTextLabel = get_node('Control/MusicVolumeControl/MusicVolumeLabel')
@onready var musicVolumeSlider: HSlider = get_node('Control/MusicVolumeControl/MusicVolumeSlider')
@onready var sfxVolumeLabel: RichTextLabel = get_node('Control/SfxVolumeControl/SfxVolumeLabel')
@onready var sfxVolumeSlider: HSlider = get_node('Control/SfxVolumeControl/SfxVolumeSlider')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if sfxPlayTimer < SFX_COOLDOWN:
		sfxPlayTimer += delta

func toggle_section(showing: bool):
	visible = showing
	if showing:
		firstSfxValueChange = true
		# play SFX the first time the slider is changed
		sfxPlayTimer = SFX_COOLDOWN
		musicVolumeSlider.value = SettingsHandler.gameSettings.musicVolume
		sfxVolumeSlider.value = SettingsHandler.gameSettings.sfxVolume
		update_texts()

func connect_top_setting_to(control: Control):
	musicVolumeSlider.focus_neighbor_top = musicVolumeSlider.get_path_to(control)

func update_texts():
	musicVolumeLabel.text = '[center]Music Volume:[/center]\n[center]' + \
			String.num_int64(roundi(SettingsHandler.gameSettings.musicVolume * 100)) + '%[/center]'
	sfxVolumeLabel.text = '[center]SFX Volume:[/center]\n[center]' + \
			String.num_int64(roundi(SettingsHandler.gameSettings.sfxVolume * 100)) + '%[/center]'

func _on_music_volume_slider_value_changed(value):
	SettingsHandler.gameSettings.musicVolume = value
	SceneLoader.audioHandler.load_audio_settings()
	update_texts()

func _on_sfx_volume_slider_value_changed(value):
	SettingsHandler.gameSettings.sfxVolume = value
	SceneLoader.audioHandler.load_audio_settings()
	update_texts()
	if sfxIncreaseTestSound != null and not firstSfxValueChange and sfxPlayTimer >= SFX_COOLDOWN:
		SceneLoader.audioHandler.play_sfx(sfxIncreaseTestSound)
		sfxPlayTimer = 0
	firstSfxValueChange = false
