extends Node3D

const PYTHON_HOST := "127.0.0.1"
const PYTHON_PORT := 4243

var score : int = 0
var _telemetry_peer := PacketPeerUDP.new()

@export var ObstacleScene: Array[PackedScene] = []
@export var MinSpawnTime : float = 2.0
@export var MaxSpawnTime : float = 2.0
@export var SpawnDistance : float = -20.0

var lanePositions = [-3.0, 0.0, 3.0]

func _ready() -> void:
	_telemetry_peer.connect_to_host(PYTHON_HOST, PYTHON_PORT)

func _physics_process(_delta: float) -> void:
	broadcast_state()

func broadcast_state() -> void:
	var player = get_node_or_null("Player")
	if player == null:
		return

	var is_game_over : bool = false
	var death_screen = get_node_or_null("DeathScreen")
	if death_screen and death_screen.visible:
		is_game_over = true

	var closest = get_closest_obstacles(1)
	var obs_type : int = -1
	var obs_dist : float = -1.0
	var obs_speed : float = 10.0

	if closest.size() > 0:
		var obs = closest[0]
		obs_type = obs.CurrentObstacleType
		obs_dist = abs(obs.global_position.z - player.global_position.z)
		if "Speed" in obs:
			obs_speed = obs.Speed

	var payload = {
		"player_speed": player.Speed if "Speed" in player else 5.0,
		"obstacle_speed": obs_speed,
		"current_lane": player.targetLane if "targetLane" in player else 0,
		"obstacle_type": obs_type,
		"obstacle_distance": obs_dist,
		"grounded": player.is_on_floor(),
		"is_sliding": player.isSliding if "isSliding" in player else false,
		"game_over": is_game_over,
		"gamepad_jump": Input.is_joy_button_pressed(0, JOY_BUTTON_B),
		"gamepad_slide": Input.is_joy_button_pressed(0, JOY_BUTTON_A),
		"timestamp": Time.get_ticks_msec() / 1000.0
	}

	_telemetry_peer.put_packet(JSON.stringify(payload).to_utf8_buffer())

func _on_score_timer_timeout() -> void:
	score += 1

func _on_spawn_timer_timeout() -> void:
	if ObstacleScene.is_empty():
		return

	var obstacleScene = ObstacleScene[randi() % len(ObstacleScene)]
	var tempObstacle = obstacleScene.instantiate()
	var isLow = tempObstacle.CurrentObstacleType == tempObstacle.ObstacleType.LOW
	tempObstacle.queue_free()

	if isLow:
		var obs = obstacleScene.instantiate()
		obs.position = Vector3(lanePositions[1], 0, SpawnDistance)
		$ObstacleContainer.add_child(obs)
	else:
		var openLane = randi() % 3
		for i in range(3):
			if i != openLane:
				var obs = obstacleScene.instantiate()
				obs.position = Vector3(lanePositions[i], 0, SpawnDistance)
				$ObstacleContainer.add_child(obs)

	$SpawnTimer.wait_time = randf_range(MinSpawnTime, MaxSpawnTime)

func get_closest_obstacles(count: int = 1) -> Array:
	var player = get_node_or_null("Player")
	var container = get_node_or_null("ObstacleContainer")
	if player == null or container == null:
		return []

	var obstacles_ahead = []
	for obs in container.get_children():
		if is_instance_valid(obs) and obs.global_position.z < player.global_position.z:
			obstacles_ahead.append(obs)

	obstacles_ahead.sort_custom(func(a, b):
		return abs(a.global_position.z - player.global_position.z) < abs(b.global_position.z - player.global_position.z)
	)
	return obstacles_ahead.slice(0, count)
