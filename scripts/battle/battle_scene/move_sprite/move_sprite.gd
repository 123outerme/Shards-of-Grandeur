extends Node2D
class_name MoveSprite

signal frame_complete(frame: int)
signal move_sprite_complete(sprite: MoveSprite)

## optional resource for identifying the sprite's "source" in an array (for Runes mostly)
@export var linkedResource: Resource = null

@export var anim: MoveAnimSprite:
	get:
		return _anim
	set(a):
		_anim = a
var _anim: MoveAnimSprite = null
@export var staticSprite: Texture2D = null

@export var looping: bool = false

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
var lastPivotPos: Vector2 = Vector2.ZERO
var halt: bool = false # set to true on construction if we want to instantiate this move sprite but not immediately start it

@onready var particleEmitter: Particles = get_node('ParticleEmitter')
@onready var spritePivot: Node2D = get_node('SpritePivot')
@onready var animatedSpriteNode: AnimatedSprite2D = get_node('SpritePivot/AnimatedSprite')
@onready var staticSpriteNode: Sprite2D = get_node('SpritePivot/StaticSprite')

# Called when the node enters the scene tree for the first time.
func _ready():
	startPos = global_position
	play_sprite_animation()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing:
		visible = true
		spritePivot.position = anim.frames[moveFrame].get_sprite_pivot(frameTimer, anim.frames[moveFrame].spritePivot, lastPivotPos)
		if not user.leftSide:
			spritePivot.position.x *= -1
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
	animatedSpriteNode.centered = anim.centerSprite
	lastPivotPos = spritePivot.position
	if anim != null:
		animatedSpriteNode.sprite_frames = anim.spriteFrames
	animatedSpriteNode.flip_h = not user.leftSide # mirror if user is right side (sprites drawn as if user is left-side)

func play_sprite_animation():
	if anim == null:
		destroy()
		return
	load_animation()
	staticSpriteNode.texture = staticSprite
	if len(anim.frames) > 0:
		playing = not halt
		visible = false
		load_frame()

func load_frame():
	startPos = global_position
	startOpacity = modulate.a
	var sprFrame: MoveAnimSpriteFrame = anim.frames[moveFrame]
	if sprFrame.animation == '#stop':
		animatedSpriteNode.stop()
	elif sprFrame.animation != '':
		animatedSpriteNode.play(sprFrame.animation)
	var offsetPos: Vector2 = sprFrame.position
	if not user.leftSide:
		offsetPos.x *= -1
	targetPos = get_sprite_target_position(sprFrame.relativeTo, sprFrame.offset) + offsetPos
	''' if the sprite is not centered (origin is at top-left instead of center) and anim is to be flipped: set the position to essentially take into account that it should be the top-right
	if not anim.centerSprite and not user.leftSide and sprFrame.relativeTo != MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
		targetPos.x -= anim.maxSize.x
		# theoretically flipping a sprite to be right-side should work, but this isn't working so I give up for now
		# I think this requires a distinction in the MoveSprite scene; the rotation should be applied to the sprite itself, the translation to the whole node
		# And maybe even separate this translation to be a node in the scene tree that parents the sprite
	#'''
	calc_rotation(sprFrame)
	
	if sprFrame.particles != null:
		var presetCopy: ParticlePreset = sprFrame.particles.duplicate(true)
		if not user.leftSide: # particles are designed & saved as they would play on an enemy (right side)
			presetCopy.processMaterial.direction.x *= -1 # invert inital X emission direction
			presetCopy.processMaterial.emission_shape_offset.x *= -1 # invert emission shape X offset direction
		particleEmitter.preset = presetCopy
		particleEmitter.set_make_particles(true)
		particleEmitter.z_index = -1 if sprFrame.particles.emitter == 'behind' else 1
		SceneLoader.audioHandler.play_sfx(sprFrame.particles.sfx)
	
	if sprFrame.sfx != null:
		SceneLoader.audioHandler.play_sfx(sprFrame.sfx)

# unused: attempt at fixing how in get_sprite_target_position(), `user` scales the particles unless the sprite is specifically centered on the (single) target
'''
func get_last_defined_target() -> MoveAnimSpriteFrame.MoveSpriteTarget:
	for frame: int in range(min(len(anim.frames) - 1, moveFrame), -1, -1):
		if anim.frames[frame].relativeTo != MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
			return anim.frames[frame].rotateToFace
	return MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION
#'''

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
	# scale particles to the user's scale
	particleEmitter.scale.x = user.get_in_front_particle_scale()
	# OR, commented out: scale particles to the scale of the reference point of this animation (usually user)
	#particleEmitter.scale.x = cNode.get_in_front_particle_scale()
	# OR, commented out: use the last defined target for scaling particles 
	#var scaleNode: CombatantNode = target if get_last_defined_target() == MoveAnimSpriteFrame.MoveSpriteTarget.TARGET else user
	#particleEmitter.scale.x = scaleNode.get_in_front_particle_scale()
	particleEmitter.scale.y = particleEmitter.scale.x
	# make the ring radii match the scale
	
	if spriteTarget != MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
		var centerPos: Vector2 = cNode.combatant.get_center_pos()
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.IN_FRONT - 1)) & 1 == 1:
			pos.x += round(0.5 * centerPos.x) if cNode.leftSide else round(-0.5 * centerPos.x)
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BEHIND - 1)) & 1 == 1:
			pos.x -= round(0.5 * centerPos.x) if cNode.leftSide else round(-0.5 * centerPos.x)
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.ABOVE - 1)) & 1 == 1:
			pos.y -= round(0.5 * centerPos.y)
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BELOW - 1)) & 1 == 1:
			pos.y += round(0.5 * centerPos.y)
	return pos

func calc_rotation(sprFrame: MoveAnimSpriteFrame):
	if sprFrame.rotate:
		var rotateOffsetPos: Vector2 = sprFrame.rotateToFacePosition
		if not user.leftSide:
			rotateOffsetPos.x *= -1
		var rotateTargetPos: Vector2 = get_sprite_target_position(sprFrame.rotateToFace, sprFrame.rotateToFaceOffset) + rotateOffsetPos
		# adjust the target Y if the sprite isn't centered (still rotate to the center of the sprite)
		if not anim.centerSprite and sprFrame.relativeTo != MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
			rotateTargetPos.y -= anim.maxSize.y / 2.0
		
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
		if not looping:
			destroy()
			return
		else:
			if len(anim.frames) > 0:
				reset_animation(false)
				load_frame()
				move_sprite_complete.emit(self)
			else:
				destroy()
			return
	frameTimer = 0
	lastPivotPos = spritePivot.position
	if not user.leftSide:
		lastPivotPos.x *= -1 # account for the pivot being flipped for right-side combatants
	load_frame()

func reset_animation(stop: bool = true):
	frameTimer = 0
	moveFrame = 0
	lastPivotPos = spritePivot.position
	playing = not stop
	if stop:
		animatedSpriteNode.play('default')
		position = Vector2.ZERO

func destroy(emitSignal: bool = true):
	playing = false
	visible = false
	if emitSignal:
		move_sprite_complete.emit(self)
	queue_free()
