extends CharacterBody3D

const SPEED = 8
const JUMP_VELOCITY = 6
const MOUSE_SENSITIVITY = 0.002

var block_scenes := [
	preload("res://scenes/blocks/block.tscn"),
	 preload("res://scenes/blocks/sphere.tscn"),
	 preload("res://scenes/blocks/stairs.tscn"),
]

var missile_scenes := [
	preload("res://scenes/launcher.tscn")
]

var current_block_index := 0
var placed_blocks = []

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D

@export var preview_material: Material  # Drag your transparent material here

var pitch := 0.0  # Vertical angle
var preview_block: Node3D = null  # Semi-transparent preview block

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Create and show the initial preview block
	_create_preview_block()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Yaw (rotate player left/right)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		# Pitch (rotate camera up/down)
		pitch = clamp(pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Rotate preview block on scroll
	if event is InputEventMouseButton and event.pressed:
		if preview_block and is_instance_valid(preview_block):
			var rotation_amount = deg_to_rad(15)  # rotate 15 degrees per scroll step
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				preview_block.rotate_y(-rotation_amount)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				preview_block.rotate_y(rotation_amount)


	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	handle_movement(delta)
	handle_block_input()
	update_preview_block()

func handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Vertical (absolute up/down)
	if Input.is_action_pressed("move_up"): # Space
		velocity.y = SPEED
	elif Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"): # Shift
		velocity.y = -SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)


	# Horizontal (relative to camera/player orientation)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func handle_block_input():
	# Scroll through blocks
	if Input.is_action_just_pressed("ui_right"):
		current_block_index = (current_block_index + 1) % missile_scenes.size()
		_create_preview_block()
	elif Input.is_action_just_pressed("ui_left"):
		current_block_index = (current_block_index - 1 + missile_scenes.size()) % missile_scenes.size()
		_create_preview_block()

	# Right-click to place block
	if Input.is_action_just_pressed("place"):
		if raycast.is_colliding():
			var block_scene = missile_scenes[current_block_index]
			var block_instance = block_scene.instantiate()
			get_tree().current_scene.add_child(block_instance)
			block_instance.global_transform = preview_block.global_transform
			placed_blocks.append(block_instance)
	if Input.is_action_just_pressed("break"):
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider and collider != preview_block:
				if collider in placed_blocks:
					placed_blocks.erase(collider)
					collider.queue_free()

func update_preview_block():
	if not is_instance_valid(preview_block):
		return
	if not preview_block.is_inside_tree():
		return

	if raycast.is_colliding():
		var pos = raycast.get_collision_point()
		preview_block.global_transform.origin = pos
		preview_block.visible = true

		# Get the shape to test collisions
	else:
		preview_block.visible = false

func _set_preview_color(node: Node, color: Color):
	if node is MeshInstance3D:
		var mat = node.material_override
		if mat:
			mat = mat.duplicate()
			mat.albedo_color = color
			node.material_override = mat
	for child in node.get_children():
		_set_preview_color(child, color)


func _create_preview_block():
	# Remove old preview block if it exists
	if is_instance_valid(preview_block):
		preview_block.queue_free()

	# Instantiate the original block scene
	var original_block = missile_scenes[current_block_index].instantiate()

	# Create a new StaticBody3D as root for the preview
	preview_block = StaticBody3D.new()
	preview_block.name = "PreviewBlock"

	# Move all children of the original block under the StaticBody3D
	for child in original_block.get_children():
		original_block.remove_child(child)
		preview_block.add_child(child)
		child.owner = preview_block  # important if using scenes

	# Apply transparent preview material
	_set_preview_material(preview_block)

	# Add to the scene
	get_tree().current_scene.call_deferred("add_child", preview_block)


func _set_preview_material(node: Node):
	if node is MeshInstance3D:
		node.material_override = preview_material
	if node is CollisionShape3D:
		node.disabled = true
	for child in node.get_children():
		_set_preview_material(child)
