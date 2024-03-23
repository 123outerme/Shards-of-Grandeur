extends Resource
class_name ParticlePreset

@export_enum('behind', 'front', 'hit', 'shard', 'surge') var emitter: String = 'behind'
@export var count: int = 0
@export var inFrontOfCombatant: bool = false
@export var lifetime: float = 0.5
@export var duration: float = 1.25
@export var processMaterial: ParticleProcessMaterial = null
@export var particleTextures: Array[Texture2D] = []
@export var sfx: AudioStream = null

func _init(
	i_emitter = 'behind',
	i_count = 0,
	i_inFront = false,
	i_lifetime = 0.5,
	i_duration = 1.25,
	i_processMaterial = null,
	i_particles: Array[Texture2D] = [],
	i_sfx = null,
):
	emitter = i_emitter
	count = i_count
	inFrontOfCombatant = i_inFront
	lifetime = i_lifetime
	duration = i_duration
	processMaterial = i_processMaterial
	particleTextures = i_particles
	sfx = i_sfx
