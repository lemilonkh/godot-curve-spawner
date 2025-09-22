@tool
class_name SpiralModifier extends SpawnModifier

@export var radius := 1.0 ## meters from curve
@export var length_scale := 1.0 ## 'stretch' of spiral - with 1.0 it takes 1m to repeat

# TODO this should maybe take the curve progress as an input instead of using only one axis of the global position
# for more natural results along very curvy curves

func apply(object: Node3D, point: Vector3, up: Vector3, index: int, curve_progress: float) -> void:
	var spiral_offset := Vector3.ZERO
	# TODO pass forward vector of curve into the apply function?
	# or can it be done only with the up vector?
	spiral_offset.x = cos(curve_progress * length_scale * 2 * PI) * radius
	spiral_offset.z = sin(curve_progress * length_scale * 2 * PI) * radius
	# TODO transform in local space of curve?
	object.global_position += spiral_offset
