extends Resource
class_name ParticlePreset

@export var type: String = ''
@export var count: int = 0
@export var inFrontOfCombatant: bool = false
@export var lifetime: float = 0.5
@export var duration: float = 1.25
@export var processMaterial: ParticleProcessMaterial = null
@export var particleTexture1: Texture2D = null
@export var particleTexture2: Texture2D = null
@export var particleTexture3: Texture2D = null
@export var particleTexture4: Texture2D = null

func _init(
	i_type = '',
	i_count = 0,
	i_inFront = false,
	i_lifetime = 0.5,
	i_duration = 1.25,
	i_processMaterial = null,
	i_particle1 = null,
	i_particle2 = null,
	i_particle3 = null,
	i_particle4 = null,
):
	type = i_type
	count = i_count
	inFrontOfCombatant = i_inFront
	lifetime = i_lifetime
	duration = i_duration
	processMaterial = i_processMaterial
	particleTexture1 = i_particle1
	particleTexture2 = i_particle2
	particleTexture3 = i_particle3
	particleTexture4 = i_particle4
