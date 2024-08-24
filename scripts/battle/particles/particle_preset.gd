extends Resource
class_name ParticlePreset

## which emitter to use. Only relevant for CombatantNode or MoveSprite particle emitting, not anything else. If MoveSprite, "behind" goes behind the move sprite, "front" goes in front. If CombatantNode, selects the ParticleEmitter to use
@export_enum('behind', 'front', 'hit', 'shard', 'surge') var emitter: String = 'behind'

## how many particles per emitter (there are 4 emitters total) 
@export var count: int = 0

## the individual lifetime of one particle
@export var lifetime: float = 0.5

## how long to play particles for
@export var duration: float = 1.25

## if true, will emit particles from one emitter, wait `lifetime` secs, then emit from the next, etc.
@export var staggered: bool = false

@export var processMaterial: ParticleProcessMaterial = null

## set up to 4 textures here to be used (one per emitter, 4 emitters total)
@export var particleTextures: Array[Texture2D] = []

## sfx to play when particles start being emitted
@export var sfx: AudioStream = null

func _init(
	i_emitter = 'behind',
	i_count = 0,
	i_lifetime = 0.5,
	i_duration = 1.25,
	i_staggered = false,
	i_processMaterial = null,
	i_particles: Array[Texture2D] = [],
	i_sfx = null,
):
	emitter = i_emitter
	count = i_count
	lifetime = i_lifetime
	duration = i_duration
	staggered = i_staggered
	processMaterial = i_processMaterial
	particleTextures = i_particles
	sfx = i_sfx
