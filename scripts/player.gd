extends CharacterBody3D

const SPEED = 8
const JUMP_VELOCITY = 6
const MOUSE_SENSITIVITY = 0.002

var block_scenes := [
	#preload("res://scenes/blocks/block.tscn"),
	 #preload("res://scenes/blocks/sphere.tscn"),
	 preload("res://scenes/blocks/stairs.tscn"),
]

var current_block_index := 0

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
	elif Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down") or Input.is_action_pressed("shift"): # Shift
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
		current_block_index = (current_block_index + 1) % block_scenes.size()
		_create_preview_block()
	elif Input.is_action_just_pressed("ui_left"):
		current_block_index = (current_block_index - 1 + block_scenes.size()) % block_scenes.size()
		_create_preview_block()

	# Right-click to place block
	if Input.is_action_just_pressed("place"):
		if raycast.is_colliding():
			var position = raycast.get_collision_point()

			var block_scene = block_scenes[current_block_index]
			var block_instance = block_scene.instantiate()
			block_instance.global_transform.origin = position
			get_tree().current_scene.add_child(block_instance)

func update_preview_block():
	if not is_instance_valid(preview_block):
		return
	if not preview_block.is_inside_tree():
		return

	if raycast.is_colliding():
		var position = raycast.get_collision_point()
		position.y+=0.01
		preview_block.global_transform.origin = position
		preview_block.visible = true

		# Get the shape to test collisions
		var collision_shape = preview_block.get_node_or_null("RigidBody3D/CollisionShape3D")
		if collision_shape and collision_shape.shape:
			var shape = collision_shape.shape.duplicate()
			#shape.margin = -0.1
			var transform = collision_shape.global_transform

			var params = PhysicsShapeQueryParameters3D.new()
			params.shape = shape
			params.transform = transform
			params.collide_with_areas = false
			params.collide_with_bodies = true
			params.exclude = [preview_block]

			var space_state = get_world_3d().direct_space_state
			var results = space_state.intersect_shape(params, 32)
			print(preview_block.global_position)
			for result in results:
				print(result.collider.name)
			# Check if it's colliding with any *placed* blocks
			if results.size() > 0:
				_set_preview_color(preview_block, Color(1, 0, 0, 0.5)) # red = blocked
			else:
				_set_preview_color(preview_block, Color(0, 1, 0, 0.3)) # green = valid
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

	# Instantiate a new preview block from current selection
	preview_block = block_scenes[current_block_index].instantiate()
	preview_block.name = "PreviewBlock"
	preview_block.set_physics_process(false)
	preview_block.set_process(false)

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
