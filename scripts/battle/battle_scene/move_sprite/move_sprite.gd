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

@export var globalMarker: Marker2D
@export var userTeam: Marker2D
@export var enemyTeam: Marker2D

var user: CombatantNode
var target: CombatantNode
var playing: bool = false
var moveFrame: int = 0
var frameTimer: float = 0
var startPos: Vector2 = Vector2()
var targetPos: Vector2 = Vector2()

@onready var particleEmitter: Particles = get_node('ParticleEmitter')

# Called when the node enters the scene tree for the first time.
func _ready():
	startPos = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if playing:
		global_position = anim.frames[moveFrame].get_sprite_position(frameTimer, targetPos, startPos)
		frameTimer += delta
		if frameTimer > anim.frames[moveFrame].get_real_duration(targetPos - startPos):
			next_frame()

func load_animation():
	moveFrame = 0
	if anim != null:
		sprite_frames = anim.spriteFrames
	flip_h = not user.leftSide # mirror if user is right side (sprites drawn as if user is left-side)

func play_sprite_animation():
	if len(anim.frames) > 0:
		playing = true
		load_frame()

func load_frame():
	startPos = global_position
	var sprFrame: MoveAnimSpriteFrame = anim.frames[moveFrame]
	play(sprFrame.animation)
	match sprFrame.relativeTo:
		MoveAnimSpriteFrame.MoveSpriteTarget.GLOBAL:
			targetPos = globalMarker.global_position
		MoveAnimSpriteFrame.MoveSpriteTarget.USER_TEAM:
			targetPos = userTeam.global_position
		MoveAnimSpriteFrame.MoveSpriteTarget.TARGET_TEAM:
			targetPos = enemyTeam.global_position
		MoveAnimSpriteFrame.MoveSpriteTarget.TARGET:
			targetPos = target.global_position
		MoveAnimSpriteFrame.MoveSpriteTarget.USER:
			targetPos = user.global_position
	var cNode: CombatantNode = user if sprFrame.relativeTo == MoveAnimSpriteFrame.MoveSpriteTarget.USER else target
	if sprFrame.relativeTo == MoveAnimSpriteFrame.MoveSpriteTarget.TARGET or \
			sprFrame.relativeTo == MoveAnimSpriteFrame.MoveSpriteTarget.USER:
		if (sprFrame.offset >> (MoveAnimSpriteFrame.MoveSpriteOffset.IN_FRONT - 1)) & 1 == 1:
			targetPos.x += round(0.5 * cNode.combatant.maxSize.x) if cNode.leftSide else round(-0.5 * cNode.combatant.maxSize.x)
			targetPos.x += round(0.5 * anim.maxSize.x) if cNode.leftSide else round(-0.5 * anim.maxSize.x)
		if (sprFrame.offset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BEHIND - 1)) & 1 == 1:
			targetPos.x -= round(0.5 * cNode.combatant.maxSize.x) if cNode.leftSide else round(-0.5 * cNode.combatant.maxSize.x)
			targetPos.x -= round(0.5 * anim.maxSize.x) if cNode.leftSide else round(-0.5 * anim.maxSize.x)
		if (sprFrame.offset >> (MoveAnimSpriteFrame.MoveSpriteOffset.ABOVE - 1)) & 1 == 1:
			targetPos.y -= round(0.5 * cNode.combatant.maxSize.y)
			targetPos.y -= round(0.5 * anim.maxSize.y)
		if (sprFrame.offset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BELOW - 1)) & 1 == 1:
			targetPos.y += round(0.5 * cNode.combatant.maxSize.y)
			targetPos.y += round(0.5 * anim.maxSize.y)
	targetPos += sprFrame.position
	if sprFrame.particles != null:
		particleEmitter.preset = sprFrame.particles
		particleEmitter.set_make_particles(true)
		SceneLoader.audioHandler.play_sfx(sprFrame.particles.sfx)

func next_frame():
	frame_complete.emit(moveFrame)
	moveFrame += 1
	frameTimer = 0
	if moveFrame >= len(anim.frames):
		playing = false
		move_sprite_complete.emit()
		queue_free()
		return
	load_frame()

func reset_animation():
	frameTimer = 0
	moveFrame = 0
	playing = false
