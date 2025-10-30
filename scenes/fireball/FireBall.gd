extends RigidBody3D

@export var lifetime: float = 5.0
@export var gravity: float = 0
@export var explosion_radius: float = 10.0
@export var explosion_force: float = 10
@export var impact_force_scale: float = 0.6
@export var explosion_power_multiplier: float = 1.0

var launched = false
# Remove the RayCast3D reference as it's no longer needed
# @onready var ray = $ImpactRay 

func _ready():
	set_as_top_level(true)
	
	# Enable contact monitoring for collision signals
	contact_monitor = true
	# Set the number of maximum contacts to report (1 is enough for a hit)
	max_contacts_reported = 1 
	
	# Connect the signal to the handler function
	body_entered.connect(_on_body_entered) 
	
	
	# Keep the lifetime timer
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func launch(initial_velocity: Vector3):
	launched = true
	linear_velocity = initial_velocity

func _integrate_forces(state):
	if launched:
		# Apply gravity manually
		linear_velocity.y += gravity * state.step
		
		# --- REMOVE RayCast3D checking from here ---
		# No manual collision checking needed anymore
		# -------------------------------------------

# 💥 NEW SIGNAL HANDLER FUNCTION
# The 'body' argument is the collider (the body it hit)
func _on_body_entered(body: Node3D):
	# Since body_entered is triggered by the physics engine, 
	# we are guaranteed to have hit something.
	
	# For simplicity and robustness, we will approximate the impact point
	# as the current position of the fireball, or you can use the last
	# contact point (which requires slightly more complex contact gathering
	# in _integrate_forces, but the current position is usually close enough 
	# for an explosion).
	var impact_point = global_position 

	# 1️⃣ Apply direct hit impulse (momentum transfer)
	if body is RigidBody3D:
		var collider = body as RigidBody3D
		var impact_dir = linear_velocity.normalized()
		var impact_strength = linear_velocity.length() * mass * impact_force_scale
		
		collider.apply_central_impulse(impact_dir * impact_strength)

	# 2️⃣ Apply explosion blast to surroundings
	_explode(impact_point)

	# 3️⃣ Fireball disappears immediately
	queue_free()
	
# No changes to _explode, it's perfect as is.
func _explode(center: Vector3):
	var space_state = get_world_3d().direct_space_state
	# ... (The rest of the _explode function remains the same)
	var sphere = SphereShape3D.new()
	sphere.radius = explosion_radius

	var shape_query = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = sphere
	shape_query.transform.origin = center
	shape_query.collide_with_bodies = true
	shape_query.exclude = [self.get_rid()]

	var results = space_state.intersect_shape(shape_query, 64)
	
	for result in results:
		var body = result.collider
		
		if body is RigidBody3D:
			var body_pos = body.global_position
			var dir = body_pos - center
			var dist = dir.length()
			
			if dist > 0.0:
				dir = dir.normalized()
			else:
				dir = Vector3.UP

			var falloff = 1.0 - clamp(dist / explosion_radius, 0.0, 1.0)
			var impulse_magnitude = explosion_force * falloff * explosion_power_multiplier
			var impulse = dir * impulse_magnitude

			body.apply_central_impulse(impulse)
