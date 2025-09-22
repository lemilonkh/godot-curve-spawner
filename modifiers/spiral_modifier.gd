@tool
class_name SpiralModifier extends SpawnModifier

@export var radius := 1.0 ## meters from curve
@export var length_scale := 1.0 ## 'stretch' of spiral

# TODO this should maybe take the curve progress as an input instead of using only one axis of the global position
# for more natural results along very curvy curves

# poin, up and forward vectors are passed in in global space
func apply(object: Node3D, point: Vector3, up: Vector3, forward: Vector3, index: int, curve_progress: float) -> void:
	var spiral_offset := Vector3.ZERO
	# rotate in local space of curve
	var radius_vector := up * radius
	var angle := length_scale * curve_progress * 2 * PI
	var rotated_vector := radius_vector.rotated(forward, angle)
	# TODO need to transform from curve to global space?
	# only if curve is rotated, but it can definitely happen
	object.global_position += rotated_vector
