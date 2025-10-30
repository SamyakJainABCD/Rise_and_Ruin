extends Node3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.005
@export var fireball_speed: float = 20.0

@onready var cam: Camera3D = $launcher_asset/Camera3D
@onready var spawn_point: Node3D = $launcher_asset/position_for_missile_spawning

var rotation_y: float = 0.0
var camera_pitch: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	var direction := 0.0

	if Input.is_action_pressed("left"):
		direction -= 1.0
	if Input.is_action_pressed("right"):
		direction += 1.0

	# Move along the absolute Z-axis (world space)
	if direction != 0:
		global_translate(Vector3(0, 0, direction * speed * delta))

	# --- SHOOTING ---
	if Input.is_action_just_pressed("shoot"):
		shoot_fireball()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Rotate player horizontally (yaw)
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation.y = rotation_y
		
		# Rotate camera vertically (pitch)
		camera_pitch -= event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-80), deg_to_rad(80))
		cam.rotation.x = camera_pitch

func shoot_fireball():
	if not GameData.place_block(0):
		return
	var fireball_scene: PackedScene = preload("res://scenes/fireball/fireball.tscn")
	var fireball_instance = fireball_scene.instantiate()

	# Set fireball position and rotation to spawn point
	fireball_instance.global_transform = spawn_point.global_transform

	# Add to scene tree
	get_tree().current_scene.add_child(fireball_instance)

	# Compute velocity in direction camera is facing
	var direction = -cam.global_transform.basis.z.normalized()
	var velocity = direction * fireball_speed

	# Call launch() on the fireball
	if fireball_instance.has_method("launch"):
		fireball_instance.launch(velocity)
