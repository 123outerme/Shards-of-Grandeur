extends AnimatedSprite2D
class_name MoveSprite

signal frame_complete(frame: int)
signal move_sprite_complete

@export var anim: MoveAnimSprite:
	get:
		return _anim
	set(a):
		_anim = a
		load_animation()
var _anim: MoveAnimSprite = null
@export var staticSprite: Texture2D = null

@export var globalMarker: Marker2D
@export var userTeam: Marker2D
@export var enemyTeam: Marker2D

var user: CombatantNode
var target: CombatantNode
var playing: bool = false
var startOpacity: float = 1
var moveFrame: int = 0
var frameTimer: float = 0
var startPos: Vector2 = Vector2()
var targetPos: Vector2 = Vector2()

@onready var particleEmitter: Particles = get_node('ParticleEmitter')
@onready var staticSpriteNode: Sprite2D = get_node('StaticSprite')

# Called when the node enters the scene tree for the first time.
func _ready():
	startPos = global_position
	play_sprite_animation()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing:
		visible = true
		global_position = anim.frames[moveFrame].get_sprite_position(frameTimer, targetPos, startPos)
		modulate.a = anim.frames[moveFrame].get_sprite_opacity(startOpacity, frameTimer, targetPos, startPos)
		if anim.frames[moveFrame].trackRotationTarget:
			calc_rotation(anim.frames[moveFrame])
		frameTimer += delta
		var finishTime = anim.frames[moveFrame].get_real_duration(targetPos - startPos)
		if frameTimer > finishTime:
			next_frame()

func load_animation():
	moveFrame = 0
	frameTimer = 0
	startOpacity = modulate.a
	centered = anim.centerSprite
	if anim != null:
		sprite_frames = anim.spriteFrames
	flip_h = not user.leftSide # mirror if user is right side (sprites drawn as if user is left-side)

func play_sprite_animation():
	if anim == null:
		queue_free()
		return
	load_animation()
	staticSpriteNode.texture = staticSprite
	if len(anim.frames) > 0:
		playing = true
		visible = false
		load_frame()

func load_frame():
	startPos = global_position
	startOpacity = modulate.a
	var sprFrame: MoveAnimSpriteFrame = anim.frames[moveFrame]
	if sprFrame.animation == '#stop':
		stop()
	elif sprFrame.animation != '':
		play(sprFrame.animation)
	var offsetPos: Vector2 = sprFrame.position
	if not user.leftSide:
		offsetPos.x *= -1
	targetPos = get_sprite_target_position(sprFrame.relativeTo, sprFrame.offset) + offsetPos
	calc_rotation(sprFrame)
	
	if sprFrame.particles != null:
		var presetCopy: ParticlePreset = sprFrame.particles.duplicate(true)
		if not user.leftSide: # particles are designed & saved as they would play on an enemy (right side)
			presetCopy.processMaterial.direction.x *= -1 # invert inital X emission direction
		particleEmitter.preset = presetCopy
		particleEmitter.set_make_particles(true)
		particleEmitter.z_index = -1 if sprFrame.particles.emitter == 'behind' else 1
		SceneLoader.audioHandler.play_sfx(sprFrame.particles.sfx)

func get_sprite_target_position(spriteTarget: MoveAnimSpriteFrame.MoveSpriteTarget, posOffset: int) -> Vector2:
	var pos = Vector2()
	match spriteTarget:
			MoveAnimSpriteFrame.MoveSpriteTarget.GLOBAL:
				pos = globalMarker.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.USER_TEAM:
				pos = userTeam.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.TARGET_TEAM:
				pos = enemyTeam.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.TARGET:
				pos = target.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.USER:
				pos = user.spriteContainer.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
				pos = startPos
	var cNode: CombatantNode = target if spriteTarget == MoveAnimSpriteFrame.MoveSpriteTarget.TARGET else user
	particleEmitter.scale.x = cNode.get_in_front_particle_scale()
	particleEmitter.scale.y = particleEmitter.scale.x
	if spriteTarget != MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.IN_FRONT - 1)) & 1 == 1:
			pos.x += round(0.5 * cNode.combatant.maxSize.x) if cNode.leftSide else round(-0.5 * cNode.combatant.maxSize.x)
			pos.x += round(0.5 * anim.maxSize.x) if cNode.leftSide else round(-0.5 * anim.maxSize.x)
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BEHIND - 1)) & 1 == 1:
			pos.x -= round(0.5 * cNode.combatant.maxSize.x) if cNode.leftSide else round(-0.5 * cNode.combatant.maxSize.x)
			pos.x -= round(0.5 * anim.maxSize.x) if cNode.leftSide else round(-0.5 * anim.maxSize.x)
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.ABOVE - 1)) & 1 == 1:
			pos.y -= round(0.5 * cNode.combatant.maxSize.y)
			pos.y -= round(0.5 * anim.maxSize.y)
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BELOW - 1)) & 1 == 1:
			pos.y += round(0.5 * cNode.combatant.maxSize.y)
			pos.y += round(0.5 * anim.maxSize.y)
	return pos

func calc_rotation(sprFrame: MoveAnimSpriteFrame):
	if sprFrame.rotate:
		var rotateOffsetPos: Vector2 = sprFrame.rotateToFacePosition
		if not user.leftSide:
			rotateOffsetPos.x *= -1
		var rotateTargetPos: Vector2 = get_sprite_target_position(sprFrame.rotateToFace, sprFrame.rotateToFaceOffset) + rotateOffsetPos
		if (rotateTargetPos - global_position).length() >= 1:
			look_at(rotateTargetPos)
			if not user.leftSide: # already "rotating" 180 degrees to satisfy sprite rotation, so rotate it back a little
				rotation_degrees -= 180
		else:
			rotation = 0

func next_frame():
	frame_complete.emit(moveFrame)
	moveFrame += 1
	if moveFrame >= len(anim.frames):
		playing = false
		move_sprite_complete.emit()
		queue_free()
		return
	frameTimer = 0
	load_frame()

func reset_animation():
	frameTimer = 0
	moveFrame = 0
	playing = false
