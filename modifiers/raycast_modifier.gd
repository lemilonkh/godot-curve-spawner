@tool
class_name RaycastModifier extends SpawnModifier

signal updated

@export var max_ray_distance := 20.0 ## maximum distance downwards to check for the floor in meters
@export var floor_offset := 1.0 ## height above the detected floor in meters

var starting_positions: Array[Vector3] = []
var cached_positions: Array[Vector3] = []

var is_dirty := false

var ray_cast_query := PhysicsRayQueryParameters3D.new()

func _init() -> void:
	uses_physics = true

func update_physics(space_state: PhysicsDirectSpaceState3D, _delta: float) -> void:
	if !is_dirty:
		return
	
	for i in starting_positions.size():
		var position: Vector3 = starting_positions[i]
		var result := cast_ray(space_state, position, position + Vector3.DOWN * max_ray_distance)
		if result:
			cached_positions[i] = result.position + Vector3.UP * floor_offset
		else:
			prints("Nothing hit!", position)
			cached_positions[i] = position
	
	is_dirty = false
	updated.emit()

func apply(object: Node3D, point: Vector3, up: Vector3, forward: Vector3, index: int, curve_progress: float) -> void:
	starting_positions.push_back(object.global_position)
	is_dirty = true
	
	# deferred until next physics update
	# TODO if this doesn't work, cache the nodes as well and handle it directly in _physics_process
	# might be faster anyways
	await updated
	object.global_position = cached_positions[index]

# returns dictionary containing position, normal, collider, collider_id, rid, shape, metadata
# returns empty dictionary if nothing hit.
func cast_ray(
	space_state: PhysicsDirectSpaceState3D,
	start: Vector3,
	end: Vector3,
	mask: int = 0x7FFFFFFF,
	ignore_objects := [],
	collide_with_areas := false,
	hit_from_inside := false
) -> Dictionary:
	ray_cast_query.collide_with_areas = collide_with_areas
	ray_cast_query.hit_from_inside = hit_from_inside
	ray_cast_query.from = start
	ray_cast_query.to = end
	ray_cast_query.exclude = ignore_objects
	ray_cast_query.collision_mask = mask
	return space_state.intersect_ray(ray_cast_query)
