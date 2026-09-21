extends CanvasLayer

var _prev_joy_a_pressed : bool = false

func _ready():
	$Background/Restart_button.pressed.connect(_on_restart_pressed)

func _process(_delta):
	var joy_a_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var joy_a_just_pressed = joy_a_pressed and not _prev_joy_a_pressed
	_prev_joy_a_pressed = joy_a_pressed

	if visible and (Input.is_action_just_pressed("ui_accept") or joy_a_just_pressed):
		_on_restart_pressed()

func _on_restart_pressed():
	get_tree().reload_current_scene()
