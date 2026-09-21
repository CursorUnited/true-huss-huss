extends Node

const PORT := 4242

var current_lane : String = "center"
var duck_active : bool = false

var _udp := PacketPeerUDP.new()
var _jump_flag : bool = false

func _ready() -> void:
	_udp.bind(PORT)

func _process(_delta: float) -> void:
	while _udp.get_available_packet_count() > 0:
		var bytes := _udp.get_packet()
		var parsed = JSON.parse_string(bytes.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		current_lane = parsed.get("lane", current_lane)
		duck_active = parsed.get("duck", false)
		if parsed.get("jump", false):
			_jump_flag = true

func consume_jump() -> bool:
	if _jump_flag:
		_jump_flag = false
		return true
	return false
