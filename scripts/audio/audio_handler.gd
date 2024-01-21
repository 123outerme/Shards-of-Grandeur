extends Node
class_name AudioHandler

var musicLoops: int = 0
var sfxLoops: int = 0
var musicFadeTween: Tween = null

@onready var musicStreamPlayer: AudioStreamPlayer = get_node('MusicStreamPlayer')
@onready var sfxStreamPlayer: AudioStreamPlayer = get_node('SfxStreamPlayer')

# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred('load_audio_settings')
	
func load_audio_settings():
	set_music_volume(SettingsHandler.gameSettings.musicVolume)
	set_sfx_volume(SettingsHandler.gameSettings.sfxVolume)

func set_music_volume(vol: float):
	musicStreamPlayer.volume_db = vol_percent_to_db(vol) - 3

func set_sfx_volume(vol: float):
	sfxStreamPlayer.volume_db = vol_percent_to_db(vol)

func vol_percent_to_db(percent: float) -> float: # percent as a float between 0 and 1
	if percent < 0.06:
		return -40 # less than 0.06% is below -40 db
	
	# ~-40 db = 0% volume
	# ~10 db = 50%
	# 0 db = 100% volume?
	return 33.22 * log(percent) / log(10) ## 33.22 * log10(percent)

func play_music(stream: AudioStream, loops: int = 0):
	musicStreamPlayer.stream = stream
	musicLoops = loops
	musicStreamPlayer.play()

func play_sfx(stream: AudioStream, loops: int = 0):
	sfxStreamPlayer.stream = stream
	sfxLoops = loops
	sfxStreamPlayer.play()

func fade_to_new_music(stream: AudioStream, msFadeOut: float = 0.5, msFadeIn: float = 0.5):
	fade_out_music(msFadeOut)
	musicFadeTween.finished.disconnect(_fade_music_callback.bind(true)) # replace callback with new music callback
	musicFadeTween.finished.connect(_fade_to_new_callback.bind(stream, msFadeIn))

func fade_out_music(ms: float = 0.5):
	if musicFadeTween != null and musicFadeTween.is_valid():
		musicFadeTween.kill()
	musicFadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	musicFadeTween.tween_method(set_music_volume, SettingsHandler.gameSettings.musicVolume, 0, ms)
	musicFadeTween.finished.connect(_fade_music_callback.bind(true))

func fade_in_music(ms: float = 0.5):
	if musicFadeTween != null and musicFadeTween.is_valid():
		musicFadeTween.kill()
	musicFadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	musicFadeTween.tween_method(set_music_volume, 0, SettingsHandler.gameSettings.musicVolume, ms)
	musicFadeTween.finished.connect(_fade_music_callback.bind(false))

func _fade_music_callback(killMusic: bool):
	musicFadeTween = null
	if killMusic:
		musicStreamPlayer.stream = null
	load_audio_settings()

func _fade_to_new_callback(stream: AudioStream, ms: float):
	musicFadeTween = null
	musicStreamPlayer.stream = stream
	fade_in_music(ms)

func _on_music_stream_player_finished():
	if musicLoops > 0:
		musicLoops -= 1
	
	if musicLoops != 0:
		musicStreamPlayer.play()

func _on_sfx_stream_player_finished():
	if sfxLoops > 0:
		sfxLoops -= 1
	
	if sfxLoops != 0:
		sfxStreamPlayer.play()
