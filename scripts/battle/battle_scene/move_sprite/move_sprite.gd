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
var totalTimer: float = 0
var startPos: Vector2 = Vector2()
var targetPos: Vector2 = Vector2()
var lastPivotPos: Vector2 = Vector2.ZERO
var halt: bool = false # set to true on construction if we want to instantiate this move sprite but not immediately start it
var destroying: bool = false

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
	if playing and anim != null:
		visible = true
		# first, increase the timer by the frame delta
		frameTimer += delta
		totalTimer += delta
		var frame: MoveAnimSpriteFrame = anim.frames[moveFrame]
		var finishTime: float = frame.get_real_duration(targetPos - startPos)
		# check if we are over the current frame's duration
		if frameTimer > finishTime:
			# if over: snap this animation to the tail end of the current frame (F1)
			finish_current_frame()
			# then advance to F2 and process F2 for the amount of time over F1's total duration
			# i.e. if F1 duration is 0.5 seconds and frameTimer was 0.55s going into this, process F2 for 0.05s
			next_frame()
			if not playing: # if the animation's now over, don't continue
				return
			frame = anim.frames[moveFrame] # update the move frame since we just advanced it
		spritePivot.position = frame.get_sprite_pivot(frameTimer, frame.spritePivot, lastPivotPos)
		if not user.leftSide:
			spritePivot.position.x *= -1
		global_position = frame.get_sprite_position(frameTimer, targetPos, startPos)
		modulate.a = frame.get_sprite_opacity(startOpacity, frameTimer, targetPos, startPos)
		if frame.trackRotationTarget:
			calc_rotation(frame)

func load_animation():
	moveFrame = 0
	frameTimer = 0
	totalTimer = 0
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
			# flip orbit (tangential) velocity to correspond with flipped sprite
			var orbitVelMin: float = presetCopy.processMaterial.orbit_velocity_min
			presetCopy.processMaterial.orbit_velocity_min = -1 * presetCopy.processMaterial.orbit_velocity_max
			presetCopy.processMaterial.orbit_velocity_max = -1 * orbitVelMin
			# flip tangential acceleration to correspond with flipped sprite
			var tangentialAccelMin: float = presetCopy.processMaterial.tangential_accel_min
			presetCopy.processMaterial.tangential_accel_min = -1 * presetCopy.processMaterial.tangential_accel_max
			presetCopy.processMaterial.tangential_accel_max = -1 * tangentialAccelMin
		particleEmitter.preset = presetCopy
		particleEmitter.set_make_particles(true)
		particleEmitter.z_index = -1 if sprFrame.particles.emitter == 'behind' else 1
		SceneLoader.audioHandler.play_sfx(sprFrame.particles.sfx)
	
	if sprFrame.sfx != null:
		SceneLoader.audioHandler.play_sfx(sprFrame.sfx)
	
	if sprFrame.emitCompleteOnStart:
		move_sprite_complete.emit(self)

# unused: attempt at fixing how in get_sprite_target_position(), `user` scales the particles unless the sprite is specifically centered on the (single) target
'''
func get_last_defined_target() -> MoveAnimSpriteFrame.MoveSpriteTarget:
	for frame: int in range(min(len(anim.frames) - 1, moveFrame), -1, -1):
		if anim.frames[frame].relativeTo != MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
			return anim.frames[frame].rotateToFace
	return MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION
#'''

func get_sprite_target_position(spriteTarget: MoveAnimSpriteFrame.MoveSpriteTarget, posOffset: int) -> Vector2:
	var pos: Vector2 = Vector2()
	var cNode: CombatantNode = user
	match spriteTarget:
			MoveAnimSpriteFrame.MoveSpriteTarget.GLOBAL:
				pos = globalMarker.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.USER_TEAM:
				pos = userTeam.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.TARGET_TEAM:
				pos = enemyTeam.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.TARGET:
				pos = target.global_position
				cNode = target
			MoveAnimSpriteFrame.MoveSpriteTarget.USER:
				pos = user.spriteContainer.global_position
			MoveAnimSpriteFrame.MoveSpriteTarget.CURRENT_POSITION:
				pos = startPos
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
		var maxSize: Vector2 = cNode.combatant.get_max_size()
		var feetPosTranslation: Vector2 = cNode.get_feet_pos_translation()
		if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.HEAD - 1)) & 1 == 1: # if the head offset bit is set: play at the head
			# remove the feet position translation to get top-left
			pos += feetPosTranslation
			pos.y += 8
			# then go from top-left to the head pos
			var headPos: Vector2 = cNode.combatant.get_head_pos()
			if cNode.leftSide != cNode.combatant.get_faces_right():
				headPos.x = cNode.combatant.get_max_size().x - headPos.x
			pos += headPos
		elif posOffset == 0b01111: # if first four offset bits are set: play at visual center of sprite instead of the "interaction center"
			# remove the feet position translation to get the top-left
			pos += feetPosTranslation # translate away from the feet position to top-left
			pos.y += 8 # add 8 just as the CombatantNode does (to display the HP tag starting at foot height)
			pos += cNode.combatant.get_max_size() / 2  # go from top-left to visual center (half max-size)
		else:
			if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.IN_FRONT - 1)) & 1 == 1:
				pos.x += round(0.5 * centerPos.x) if cNode.leftSide else round(-0.5 * centerPos.x)
			if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BEHIND - 1)) & 1 == 1:
				pos.x -= round(0.5 * centerPos.x) if cNode.leftSide else round(-0.5 * centerPos.x)
				# true other side of sprite; change above to pos.x += ... and then uncomment below
				# seems to be wrong, though...
				#pos.x -= maxSize.x if cNode.leftSide else -1 * maxSize.x
			if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.ABOVE - 1)) & 1 == 1:
				pos.y += 8
				pos.y -= maxSize.y
			if (posOffset >> (MoveAnimSpriteFrame.MoveSpriteOffset.BELOW - 1)) & 1 == 1:
				pos.y += 8 # pos.y is set at position of combatant node...
				# combatant node coordinate is 8px above feet position...
				# so just add 8px
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

func finish_current_frame() -> void:
	var frame: MoveAnimSpriteFrame = anim.frames[moveFrame]
	var finishTime: float = frame.get_real_duration(targetPos - startPos)
	spritePivot.position = frame.get_sprite_pivot(finishTime, frame.spritePivot, lastPivotPos)
	if not user.leftSide:
		spritePivot.position.x *= -1
	global_position = frame.get_sprite_position(finishTime, targetPos, startPos)
	modulate.a = frame.get_sprite_opacity(startOpacity, finishTime, targetPos, startPos)
	if frame.trackRotationTarget:
		calc_rotation(frame)

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
	
	# continue with some leftover duration (if any)
	var finishTime: float = anim.frames[moveFrame - 1].get_real_duration(targetPos - startPos)
	frameTimer = max(0, min(frameTimer, frameTimer - finishTime))
	lastPivotPos = spritePivot.position
	if not user.leftSide:
		lastPivotPos.x *= -1 # account for the pivot being flipped for right-side combatants
	load_frame()

func reset_animation(stop: bool = true):
	frameTimer = 0
	moveFrame = 0
	totalTimer = 0
	lastPivotPos = spritePivot.position
	playing = not stop
	if stop:
		animatedSpriteNode.play('default')
		position = Vector2.ZERO

func destroy(emitSignal: bool = true):
	playing = false
	visible = false
	destroying = true
	if emitSignal:
		move_sprite_complete.emit(self)
	queue_free()
