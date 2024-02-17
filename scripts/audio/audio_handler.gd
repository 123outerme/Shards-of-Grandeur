extends Node
class_name AudioHandler

var musicLoops: int = 0
var sfxLoops: Array[int] = []
var musicFadeTween: Tween = null

var crossFadeTime: float = -1
var crossFadeAccum: float = 0
var musicPlayingOnStream2: bool = false

var openSfxPlayers: Array[bool] = []
var lastSfxIdx: int = -1

@onready var musicStreamPlayer1: AudioStreamPlayer = get_node('MusicStreamPlayer1')
@onready var musicStreamPlayer2: AudioStreamPlayer = get_node('MusicStreamPlayer2')
@onready var sfxStreamPlayers: Array[AudioStreamPlayer] = [
	get_node('SfxStreamPlayer1'),
	get_node('SfxStreamPlayer2'),
	get_node('SfxStreamPlayer3')
]

# Called when the node enters the scene tree for the first time.
func _ready():
	for idx in range(len(sfxStreamPlayers)):
		sfxLoops.append(0)
		openSfxPlayers.append(true)
		
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
			prevStreamPlayer.stop()
			prevStreamPlayer.stream = null

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
	for player in sfxStreamPlayers:
		player.volume_db = vol_percent_to_db(vol)

func vol_percent_to_db(percent: float) -> float: # percent as a float between 0 and 1
	if percent < 0.01:
		return -70 # less than 1% is below -60 db
	
	# ~-70 db = 0% volume
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

func get_cur_music() -> AudioStream:
	return get_cur_music_player().stream

func is_music_already_playing(stream: AudioStream):
	return get_cur_music() == stream and get_cur_music_player().playing

func play_sfx(stream: AudioStream, loops: int = 0, sfxPlayerIdx: int = -1):
	if stream == null:
		return
	
	var idx: int = get_first_open_sfx_player_idx()
	if sfxPlayerIdx != -1:
		idx = sfxPlayerIdx
	sfxStreamPlayers[idx].stream = stream
	sfxLoops[idx] = loops
	openSfxPlayers[idx] = false
	sfxStreamPlayers[idx].play()
	lastSfxIdx = idx

func stop_sfx(stream: AudioStream):
	for idx in range(len(sfxStreamPlayers)):
		if sfxStreamPlayers[idx].stream == stream:
			sfxStreamPlayers[idx].stop()
			openSfxPlayers[idx] = true

func cross_fade(newStream: AudioStream, sec: float = 2.5):
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
	else:
		musicStreamPlayer1.stop()

func _on_music_stream_player_2_finished():
	if not musicPlayingOnStream2:
		return
	
	if musicLoops > 0:
		musicLoops -= 1
	if musicLoops != 0:
		musicStreamPlayer2.play()
	else:
		musicStreamPlayer2.stop()

func _on_sfx_stream_player_finished(idx):
	if sfxLoops[idx] > 0:
		sfxLoops[idx] -= 1
	
	if sfxLoops[idx] != 0:
		sfxStreamPlayers[idx].play()
	else:
		sfxStreamPlayers[idx].stop()
		openSfxPlayers[idx] = true

func get_first_open_sfx_player_idx() -> int:
	for idx in range(len(sfxStreamPlayers)):
		if openSfxPlayers[idx]:
			return idx
	
	if lastSfxIdx != -1:
		return (lastSfxIdx + 1) % len(sfxStreamPlayers) 
	
	return 0 # play on the first player if they're all taken
