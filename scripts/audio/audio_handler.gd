extends Node
class_name AudioHandler

signal music_playback_complete
signal music_fade_completed

const MUSIC_DB_HEAD_ROOM = 5

var musicLoops: int = 0
var sfxLoops: Array[int] = []
var musicFadeOutTween: Tween = null
var musicFadeInTween: Tween = null

var crossFadeTime: float = -1
var crossFadeAccum: float = 0
var musicPlayingOnStream2: bool = false

var fadingOutMusic: bool = false

var openSfxPlayers: Array[bool] = []
var lastSfxIdx: int = -1

@onready var musicStreamPlayer1: AudioStreamPlayer = get_node('MusicStreamPlayer1')
@onready var musicStreamPlayer2: AudioStreamPlayer = get_node('MusicStreamPlayer2')
@onready var sfxStreamPlayers: Array[AudioStreamPlayer] = [
	get_node('SfxStreamPlayer1'),
	get_node('SfxStreamPlayer2'),
	get_node('SfxStreamPlayer3'),
	get_node('SfxStreamPlayer4'),
	get_node('SfxStreamPlayer5'),
	get_node('SfxStreamPlayer6')
]

# Called when the node enters the scene tree for the first time.
func _ready():
	if SceneLoader.audioHandler == null:
		SceneLoader.audioHandler = self
	
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
	get_cur_music_player().volume_db = vol_percent_to_db(vol) - MUSIC_DB_HEAD_ROOM

func set_music_1_volume(vol: float):
	musicStreamPlayer1.volume_db = vol_percent_to_db(vol) - MUSIC_DB_HEAD_ROOM

func set_music_2_volume(vol: float):
	musicStreamPlayer2.volume_db = vol_percent_to_db(vol) - MUSIC_DB_HEAD_ROOM

func set_sfx_volume(vol: float):
	for player in sfxStreamPlayers:
		player.volume_db = vol_percent_to_db(vol)

func vol_percent_to_db(percent: float) -> float: # percent as a float between 0 and 1
	if percent < 0.01:
		return -70 # less than 1% is below -60 db
	
	# ~-70 db = 0% volume
	# ~-10 db = 50%
	# 0 db = 100% volume?
	return 33.22 * log(percent) / log(10) # 33.22 * log10(percent)

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
	return get_cur_music() == stream

func which_sfx_channel_playing(stream: AudioStream) -> int:
	for idx: int in range(len(sfxStreamPlayers)):
		if not openSfxPlayers[idx] and sfxStreamPlayers[idx].stream == stream:
			return idx
	return -1

## plays the specified stream on the `sfx` audio bus. Returns the SFX stream player idx
func play_sfx(stream: AudioStream, loops: int = 0, varyPitch: bool = false, sfxPlayerIdx: int = -1, forceNewInstance: bool = false) -> int:
	if stream == null:
		return -1
	
	var idx: int = sfxPlayerIdx
	if sfxPlayerIdx == -1:
		idx = which_sfx_channel_playing(stream)
		if idx == -1 or forceNewInstance:
			idx = get_first_open_sfx_player_idx()
	
	if idx != -1:
		sfxStreamPlayers[idx].pitch_scale = 1.0 if not varyPitch else randf_range(0.95, 1.05)
		sfxStreamPlayers[idx].stream = stream
		sfxLoops[idx] = loops
		openSfxPlayers[idx] = false
		sfxStreamPlayers[idx].play()
		lastSfxIdx = idx
		#print('Playing sfx ', stream.resource_path, ' on channel ', idx)
	#else:
		#print('Warning: No open sfx players for audio ', stream.resource_path)
	return idx

func stop_sfx(stream: AudioStream):
	for idx in range(len(sfxStreamPlayers)):
		if sfxStreamPlayers[idx].stream == stream:
			sfxStreamPlayers[idx].stop()
			openSfxPlayers[idx] = true

func cross_fade(newStream: AudioStream, loopsNew: int = 0, sec: float = 2.5):
	musicLoops = loopsNew
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
	
func fade_to_new_music(stream: AudioStream, loops: int = -1, secFadeOut: float = 0.5, secFadeIn: float = 0.5):
	fade_out_music(secFadeOut)
	await music_fade_completed
	fade_in_new_music(stream, loops, secFadeIn)

func fade_out_music(sec: float = 0.5):
	if musicFadeOutTween != null and musicFadeOutTween.is_valid():
		musicFadeOutTween.kill()
	musicFadeOutTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	musicFadeOutTween.tween_method(set_cur_music_volume, SettingsHandler.gameSettings.musicVolume, 0, sec)
	musicFadeOutTween.finished.connect(_fade_music_callback.bind(true, get_cur_music_player()))
	musicFadeOutTween.finished.connect(_fade_out_callback)
	fadingOutMusic = true

func _fade_out_callback() -> void:
	musicFadeOutTween = null

func fade_in_music(sec: float = 0.5, loops: int = -1):
	if musicFadeInTween != null and musicFadeInTween.is_valid():
		musicFadeInTween.kill()
	musicLoops = loops
	if sec <= 0:
		# don't bother with a tween, just do it
		set_cur_music_volume(SettingsHandler.gameSettings.musicVolume)
		_fade_music_callback(false)
		return
	musicFadeInTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	musicFadeInTween.tween_method(set_cur_music_volume, 0, SettingsHandler.gameSettings.musicVolume, sec)
	musicFadeInTween.finished.connect(_fade_music_callback.bind(false))
	musicFadeInTween.finished.connect(_fade_in_callback)

func _fade_in_callback() -> void:
	musicFadeInTween = null

func _fade_music_callback(killMusic: bool, musicPlayer: AudioStreamPlayer = null):
	if killMusic:
		var killPlayer: AudioStreamPlayer = get_cur_music_player() if musicPlayer == null else musicPlayer
		killPlayer.stream = null
	load_audio_settings()
	fadingOutMusic = false
	music_fade_completed.emit()

func fade_in_new_music(stream: AudioStream, loops: int, sec: float):
	if fadingOutMusic:
		musicPlayingOnStream2 = not musicPlayingOnStream2
	get_cur_music_player().stream = stream
	get_cur_music_player().play()
	fade_in_music(sec, loops)

func _on_music_stream_player_1_finished():
	if musicPlayingOnStream2:
		return
	
	if musicLoops > 0:
		musicLoops -= 1
	if musicLoops != 0:
		musicStreamPlayer1.play()
	else:
		musicStreamPlayer1.stop()
		music_playback_complete.emit()

func _on_music_stream_player_2_finished():
	if not musicPlayingOnStream2:
		return
	
	if musicLoops > 0:
		musicLoops -= 1
	if musicLoops != 0:
		musicStreamPlayer2.play()
	else:
		musicStreamPlayer2.stop()
		music_playback_complete.emit()

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
	
	return -1 # don't play if they're all taken up
