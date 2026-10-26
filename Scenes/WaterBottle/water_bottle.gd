extends RapierRigidBody2D

signal bottle_clicked(clicked_position: Vector2)
signal flip_landed()
signal flip_failed()

var is_dragging: bool = false
var grab_offset: Vector2 = Vector2.ZERO

var physics_frames_passed: int = 0

@onready var fluid_node: Fluid2D = $Fluid2D
@onready var bottle_area: Area2D = $Area2D

@export var follow_speed: float = 10.0
@export var max_drag_speed: float = 40000.0 # Prevents the bottle from slamming into particles
@export var spin_acceleration: float = 15.0

var accumulated_rotation: float = 0.0
const FLIP_THRESHOLD: float = TAU # TAU equals 2 * PI (360 degrees)
var flip_count: int = 0


func _ready() -> void:
	# Make ONLY this body ignore gravity permanently
	
	gravity_scale = 1.0
	
	
# 1. Triggered when clicking the bottle's Area2D
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_dragging:
			is_dragging = true
			gravity_scale = 0.0
			linear_velocity = Vector2.ZERO
			#angular_velocity = 0.0
			grab_offset = global_position - get_global_mouse_position()
			var clicked_position = get_global_mouse_position()
			bottle_clicked.emit(clicked_position)
			

# 2. Catch the release globally anywhere on the screen
func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			is_dragging = false
			gravity_scale = 1.0

# 3. Pull the bottle with a capped velocity limit
func _physics_process(delta: float) -> void:
	if is_dragging:
		var target_position = get_global_mouse_position() + grab_offset
		var error_vector = target_position - global_position
		
		var desired_velocity = error_vector * follow_speed
		
		# Clamp the velocity so fast mouse movements don't cause particle tunneling
		if desired_velocity.length() > max_drag_speed:
			desired_velocity = desired_velocity.normalized() * max_drag_speed
			
		linear_velocity = desired_velocity
		flip_count = 0
		
	if not is_dragging:
		accumulated_rotation += abs(10*angular_velocity * delta)
		
		# Check if a full 360-degree rotation has passed
		if accumulated_rotation >= FLIP_THRESHOLD:
			flip_count += 1
			accumulated_rotation -= FLIP_THRESHOLD # Subtract to count consecutive flips
			print("Flip completed! Total flips: ", flip_count)
	else:
		# Reset tracking while the player is holding/dragging the bottle
		accumulated_rotation = 0.0
		flip_count = 0

		
	# Wait at least 2 frames for the physics server to register everything
	if physics_frames_passed < 2:
		physics_frames_passed += 1
		return
		
	if fluid_node and bottle_area:
		var points = fluid_node.get_points()
		var space_state = get_world_2d().direct_space_state
		var modified: bool = false
		
		for i in range(points.size()):
			var global_pos = fluid_node.to_global(points[i])
			
			var query = PhysicsPointQueryParameters2D.new()
			query.position = global_pos
			query.collide_with_areas = true
			query.collide_with_bodies = false
			query.collision_mask = bottle_area.collision_layer
			
			var results = space_state.intersect_point(query)
			var is_inside: bool = false
			
			for result in results:
				if result["collider"] == bottle_area:
					is_inside = true
					break
			
			# If the particle leaves the bottle bounds, safely snap it back inside
			if not is_inside:
				# Vector2.ZERO is the local center of this node (the bottle).
				# A small random scatter prevents them from stacking on the exact same coordinate.
				var random_scatter = Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
				points[i] = Vector2(0,200) + random_scatter
				modified = true
				
		# Push the updated positions back to the fluid engine
		if modified:
			fluid_node.set_points(points)


func _on_flip_sensor_area_entered(area: Area2D) -> void:
	if flip_count > 0:
		flip_count = 0
		flip_landed.emit()


func _on_side_sensor_area_entered(area: Area2D) -> void:
	angular_velocity = 0
	flip_failed.emit()
