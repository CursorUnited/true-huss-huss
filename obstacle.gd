extends StaticBody3D

enum ObstacleType{STANDARD, LOW, HIGH}
@export var CurrentObstacleType: ObstacleType = ObstacleType.STANDARD
@export var Speed : float = 10.0

func _process(delta: float) -> void:
	position.z += Speed * delta

	if position.z > 20:
		queue_free()
