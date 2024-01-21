extends Node
class_name AudioHandler

var musicLoops: int = 0
var sfxLoops: int = 0
var musicFadeTween: Tween = null

var crossFadeTime: float = -1
var crossFadeAccum: float = 0
var musicPlayingOnStream2: bool = false

@onready var musicStreamPlayer1: AudioStreamPlayer = get_node('MusicStreamPlayer1')
@onready var musicStreamPlayer2: AudioStreamPlayer = get_node('MusicStreamPlayer2')
@onready var sfxStreamPlayer: AudioStreamPlayer = get_node('SfxStreamPlayer')

# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred('load_audio_settings')

func _process(delta):
	if crossFadeTime > -1:
		crossFadeAccum += delta
		var curStreamPlayer: AudioStreamPlayer = musicStreamPlayer1
		var prevStreamPlayer: AudioStreamPlayer = musicStreamPlayer1
		if musicPlayingOnStream2:
			curStreamPlayer = musicStreamPlayer2
		else:
			prevStreamPlayer = musicStreamPlayer2
		curStreamPlayer.volume_db = vol_percent_to_db(lerpf(0, SettingsHandler.gameSettings.musicVolume, crossFadeAccum / crossFadeTime)) - 3
		prevStreamPlayer.volume_db = vol_percent_to_db(lerpf(SettingsHandler.gameSettings.musicVolume, 0, crossFadeAccum / crossFadeTime)) - 3
		if crossFadeAccum > crossFadeTime:
			crossFadeTime = -1

func load_audio_settings():
	set_music_1_volume(SettingsHandler.gameSettings.musicVolume)
	set_music_2_volume(SettingsHandler.gameSettings.musicVolume)
	set_sfx_volume(SettingsHandler.gameSettings.sfxVolume)

func set_cur_music_volume(vol: float):
	get_cur_music_player().volume_db = vol_percent_to_db(vol) - 3

func set_music_1_volume(vol: float):
	musicStreamPlayer1.volume_db = vol_percent_to_db(vol) - 3

func set_music_2_volume(vol: float):
	musicStreamPlayer2.volume_db = vol_percent_to_db(vol) - 3

func set_sfx_volume(vol: float):
	sfxStreamPlayer.volume_db = vol_percent_to_db(vol)

func vol_percent_to_db(percent: float) -> float: # percent as a float between 0 and 1
	if percent < 0.06:
		return -40 # less than 0.06% is below -40 db
	
	# ~-40 db = 0% volume
	# ~-10 db = 50%
	# 0 db = 100% volume?
	return 33.22 * log(percent) / log(10) ## 33.22 * log10(percent)

func play_music(stream: AudioStream, loops: int = 0):
	get_cur_music_player().stream = stream
	musicLoops = loops
	get_cur_music_player().play()

func get_cur_music_player() -> AudioStreamPlayer:
	if musicPlayingOnStream2:
		return musicStreamPlayer2
	return musicStreamPlayer1

func play_sfx(stream: AudioStream, loops: int = 0):
	sfxStreamPlayer.stream = stream
	sfxLoops = loops
	sfxStreamPlayer.play()

func stop_sfx(stream: AudioStream):
	if sfxStreamPlayer.stream == stream:
		sfxStreamPlayer.stop()

func cross_fade(newStream: AudioStream, sec: float):
	if newStream == null:
		return
	
	if musicPlayingOnStream2:
		musicStreamPlayer1.stream = newStream
		set_music_1_volume(0)
		musicStreamPlayer1.play()
	else:
		musicStreamPlayer2.stream = newStream
		set_music_2_volume(0)
		musicStreamPlayer2.play()
	
	musicPlayingOnStream2 = not musicPlayingOnStream2
	crossFadeTime = sec
	crossFadeAccum = 0

func _cross_fade_finished():
	if musicPlayingOnStream2:
		musicStreamPlayer1.stop()
	else:
		musicStreamPlayer2.stop()
	load_audio_settings()
	

func fade_to_new_music(stream: AudioStream, secFadeOut: float = 0.5, secFadeIn: float = 0.5):
	fade_out_music(secFadeOut)
	musicFadeTween.finished.disconnect(_fade_music_callback.bind(true)) # replace callback with new music callback
	musicFadeTween.finished.connect(_fade_to_new_callback.bind(stream, secFadeIn))

func fade_out_music(sec: float = 0.5):
	if musicFadeTween != null and musicFadeTween.is_valid():
		musicFadeTween.kill()
	musicFadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	musicFadeTween.tween_method(set_cur_music_volume, SettingsHandler.gameSettings.musicVolume, 0, sec)
	musicFadeTween.finished.connect(_fade_music_callback.bind(true))

func fade_in_music(sec: float = 0.5):
	if musicFadeTween != null and musicFadeTween.is_valid():
		musicFadeTween.kill()
	musicFadeTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	musicFadeTween.tween_method(set_cur_music_volume, 0, SettingsHandler.gameSettings.musicVolume, sec)
	musicFadeTween.finished.connect(_fade_music_callback.bind(false))

func _fade_music_callback(killMusic: bool):
	musicFadeTween = null
	if killMusic:
		musicStreamPlayer1.stream = null
	load_audio_settings()

func _fade_to_new_callback(stream: AudioStream, ms: float):
	musicFadeTween = null
	get_cur_music_player().stream = stream
	fade_in_music(ms)

func _on_music_stream_player_1_finished():
	if musicPlayingOnStream2:
		return
	
	if musicLoops > 0:
		musicLoops -= 1
	if musicLoops != 0:
		musicStreamPlayer1.play()

func _on_music_stream_player_2_finished():
	if not musicPlayingOnStream2:
		return
	
	if musicLoops > 0:
		musicLoops -= 1
	if musicLoops != 0:
		musicStreamPlayer2.play()

func _on_sfx_stream_player_finished():
	if sfxLoops > 0:
		sfxLoops -= 1
	
	if sfxLoops != 0:
		sfxStreamPlayer.play()
