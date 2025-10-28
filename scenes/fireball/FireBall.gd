extends RigidBody3D

@export var lifetime: float = 5.0
@export var gravity: float = -9.8
var launched := false

func _ready():
	set_as_top_level(true)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func launch(initial_velocity: Vector3):
	launched = true
	linear_velocity = initial_velocity

func _physics_process(delta: float):
	if launched:
		# Gravity effect on fireball (manual acceleration)
		linear_velocity.y += gravity * delta
