@tool
extends Node2D
class_name Particles

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
	
func _process(delta):
	if waves > 0 and Time.get_unix_time_from_system() > startTime + duration and makeParticles:
		set_make_particles(false)

func set_make_particles(show: bool):
	_makeParticles = show
	for child in get_children():
		if child is GPUParticles2D:
			var particleSpawner: GPUParticles2D = child as GPUParticles2D
			if particleSpawner.emitting != show:
				particleSpawner.emitting = show
			particleSpawner.lifetime = lifetime
	if show:
		startTime = Time.get_unix_time_from_system()

func set_num_particles(value: int):
	var children = get_children()
	_particles = value
	for child in children:
		if child is GPUParticles2D:
			var particleSpawner: GPUParticles2D = child as GPUParticles2D
			particleSpawner.amount = _particles
