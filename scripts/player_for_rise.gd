extends CharacterBody3D

const SPEED = 8
const JUMP_VELOCITY = 6
const MOUSE_SENSITIVITY = 0.002



var current_block_index := 0
var placed_blocks = []

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D

@export var preview_material: Material  # Drag your transparent material here

var pitch := 0.0  # Vertical angle
var preview_block: Node3D = null  # Semi-transparent preview block
var TOTAL_TIME = 60

func _ready():
	GameData.costs = GameData.costs_for_rise
	GameData.BLOCK_ICONS = GameData.block_icons
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Create and show the initial preview block
	_create_preview_block()
	GameData.start_timer(TOTAL_TIME)
	await get_tree().create_timer(60).timeout
	var block_list = []
	for block in placed_blocks:
		var instance_scene_path = block.scene_file_path

# Find which preload it matches
		var index = -1
		for i in range(GameData.block_scenes.size()):
			if GameData.block_scenes[i].resource_path == instance_scene_path:
				index = i
				break
		block_list.append([index, block.global_transform])
	GameState.send_match_data(block_list)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Yaw (rotate player left/right)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		# Pitch (rotate camera up/down)
		pitch = clamp(pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed:
		var new_index = -1
		if event.keycode == KEY_1: new_index = 0
		elif event.keycode == KEY_2: new_index = 1
		elif event.keycode == KEY_3: new_index = 2
		elif event.keycode == KEY_4: new_index = 3
		elif event.keycode == KEY_5: new_index = 4
		elif event.keycode == KEY_6: new_index = 5
		elif event.keycode == KEY_7: new_index = 6
		elif event.keycode == KEY_8: new_index = 7
		elif event.keycode == KEY_9: new_index = 8
		elif event.keycode == KEY_0: new_index = 9
		# Assuming you only have 6 unique block scenes
		
		if new_index != -1 and new_index < GameData.block_scenes.size():
			_set_current_block(new_index)
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
		
func _set_current_block(index: int):
	# Ensure index wraps around (0, 1, 2, 3, 4, 5, 0, ...)
	var new_index = (index % GameData.block_scenes.size() + GameData.block_scenes.size()) % GameData.block_scenes.size()
	if new_index != current_block_index:
		current_block_index = new_index
		_create_preview_block()
		GameData.block_selected.emit(current_block_index)

func _physics_process(delta):
	handle_movement(delta)
	handle_block_input()
	update_preview_block()

func handle_movement(_delta: float) -> void:
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
		_set_current_block(current_block_index + 1)
	elif Input.is_action_just_pressed("ui_left"):
		_set_current_block(current_block_index - 1)

	# Right-click to place block
	if Input.is_action_just_pressed("place"):
		if raycast.is_colliding():
			if GameData.place_block(current_block_index, preview_block.global_transform.origin): # GameData.place_block() spends the money and returns true if successful
				var block_scene = GameData.block_scenes[current_block_index]
				var block_instance = block_scene.instantiate()
				get_tree().current_scene.add_child(block_instance)
				block_instance.global_transform = preview_block.global_transform
				add_to_placed_blocks_list(block_instance)
		GameData.block_selected.emit(current_block_index)
			
				
	if Input.is_action_just_pressed("break"):
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider and collider != preview_block:
				if collider in placed_blocks:
					var instance_scene_path = collider.scene_file_path
					var index = -1
					for i in range(GameData.block_scenes.size()):
						if GameData.block_scenes[i].resource_path == instance_scene_path:
							index = i
							break
					GameData.break_block(index)
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
	var original_block = GameData.block_scenes[current_block_index].instantiate()

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
	if node is CollisionShape3D:
		node.disabled = true
	if node is RigidBody3D:
		node.gravity_scale = 0.0
	for child in node.get_children():
		_set_preview_material(child)

func add_to_placed_blocks_list(block_instance):
	if block_instance is RigidBody3D:
		placed_blocks.append(block_instance)
	else:
		for child in block_instance.get_children():
			add_to_placed_blocks_list(child)
