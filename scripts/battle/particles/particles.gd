@tool
extends Node2D
class_name Particles

@export var preset: ParticlePreset:
	get:
		return _preset
	set(value):
		_preset = value
		load_preset()
var _preset: ParticlePreset = null

@export var lifetime: float = 0.5

@export var particles: int:
	get:
		return _particles
	set(value):
		set_num_particles(value)
var _particles: int = 4

@export var waves: float:
	get:
		return _waves
	set(value):
		_waves = value
var _waves: float = 5.0

@export var duration: float:
	get:
		if _waves > 0:
			return _waves * lifetime
		return -1
	set(value):
		if value >= 0:
			_waves = value / lifetime
		else:
			_waves = -1

var startTime: float = 0

@export var makeParticles: bool:
	get:
		return _makeParticles
	set(value):
		set_make_particles(value)
var _makeParticles: bool = false

func _init():
	makeParticles = false
	
func _process(_delta):
	if waves > 0 and Time.get_unix_time_from_system() > startTime + duration and makeParticles:
		set_make_particles(false)

func load_preset():
	lifetime = preset.lifetime
	set_num_particles(preset.count)
	duration = preset.duration
	var textureIdx: int = 0
	for child in get_children():
		if child is GPUParticles2D:
			var particleSpawner: GPUParticles2D = child as GPUParticles2D
			var particleTexture = null
			if textureIdx < len(preset.particleTextures):
				particleTexture = preset.particleTextures[textureIdx]
			particleSpawner.texture = particleTexture
			particleSpawner.process_material = preset.processMaterial
			textureIdx += 1

func set_make_particles(showParticles: bool):
	_makeParticles = showParticles
	var children = get_children()
	for idx in range(len(children)):
		var child = children[idx]
		if child is GPUParticles2D:
			var particleSpawner: GPUParticles2D = child as GPUParticles2D
			if particleSpawner.emitting != showParticles and not (not particleSpawner.emitting and preset.count < 1):
				if preset.staggered and not idx == 0:
					# stagger by delaying a portion of the particles' lifetime to start the next spawning process
					await get_tree().create_timer(preset.lifetime / len(children)).timeout
				particleSpawner.emitting = showParticles
			particleSpawner.lifetime = lifetime
	if showParticles:
		startTime = Time.get_unix_time_from_system()

func set_num_particles(value: int):
	if value < 1:
		return
	var children = get_children()
	_particles = value
	for child in children:
		if child is GPUParticles2D:
			var particleSpawner: GPUParticles2D = child as GPUParticles2D
			particleSpawner.amount = _particles
