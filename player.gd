extends CharacterBody3D

@export var Speed   = 5.0
@export var Jump_velocity = 6.0
@export var LaneChangeSpeed = 5.0
@export var TireSpinSpeed = 15.0

enum Lane {LEFT = -1, CENTER = 0, RIGHT = 1}
enum State {RUNNING, JUMPING, SLIDING, DEAD}

@export var SlideKey : Key = KEY_SHIFT
@export var SlideJoyButton : JoyButton = JOY_BUTTON_A
@export var SlideJoyDevice : int = 0

var targetLane : int = Lane.CENTER
var currentLane : int = Lane.CENTER
@export var LaneWidth = 3.0
var isSliding : bool = false
var slideTween : Tween

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity()* delta

	#jumping
	var controller_jump = Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	if (Input.is_action_just_pressed("ui_accept") or controller_jump) and is_on_floor() and not isSliding: # or CVInput.consume_jump()
		velocity.y = Jump_velocity

	#sliding
	var keyboard_slide = Input.is_key_pressed(SlideKey)
	var controller_slide = Input.is_joy_button_pressed(SlideJoyDevice, SlideJoyButton)
	#var cv_slide = CVInput.duck_active
	if (keyboard_slide or controller_slide) and is_on_floor() and not isSliding: # or cv_slide
		isSliding = true
		$CollisionShape3D.scale.y = 0.5

		if slideTween:
			slideTween.kill()

		slideTween = create_tween()
		slideTween.set_trans(Tween.TRANS_QUAD)
		slideTween.set_ease(Tween.EASE_OUT)
		slideTween.tween_property($Model, "scale:y", 0.2, 0.2)
		slideTween.parallel().tween_property($CollisionShape3D, "scale:y", 0.2, 0.4)
		slideTween.tween_interval(0.5)
		slideTween.tween_property($Model, "scale:y", 1.0, 0.2)
		slideTween.parallel().tween_property($CollisionShape3D, "scale:y", 1.0, 0.4)
		slideTween.tween_callback(func():
			isSliding = false
		)
	
	var targetX = targetLane * LaneWidth
	position.x = lerp(position.x, targetX, LaneChangeSpeed * delta)

	if Input.is_action_just_pressed("ui_left") and targetLane > Lane.LEFT:
		targetLane -= 1
	if Input.is_action_just_pressed("ui_right") and targetLane < Lane.RIGHT:
		targetLane += 1

	match CVInput.current_lane:
		"left":
			targetLane = Lane.LEFT
		"right":
			targetLane = Lane.RIGHT
		"center":
			targetLane = Lane.CENTER

	move_and_slide()

	#collision handler
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("obstacle"):
			die()

func get_game_state() -> Array:
	"""
	Returns 8-dimensional state vector: [lane, grounded, vel, dist1, dist2, dist3, sliding, score]
	"""
	var game_manager = get_parent()
	var obstacles = game_manager.get_closest_obstacles(3)

	var lane_norm = float(currentLane) / 1.0
	var grounded = 1.0 if is_on_floor() else 0.0
	var vel_norm = clamp(velocity.y / Jump_velocity, -2.0, 2.0)
	var slide_norm = 1.0 if isSliding else 0.0

	var obs_distances = []
	for i in range(3):
		if i < obstacles.size():
			var dist = obstacles[i].position.z - position.z
			dist = clamp(dist, -50.0, 50.0) / 50.0
			obs_distances.append(dist)
		else:
			obs_distances.append(-1.0)

	var score_norm = clamp(float(game_manager.score) / 1000.0, 0.0, 1.0)

	return [lane_norm, grounded, vel_norm, obs_distances[0], obs_distances[1], obs_distances[2], slide_norm, score_norm]

func die():
	get_parent().get_node("DeathScreen").show()
	set_physics_process(false)
