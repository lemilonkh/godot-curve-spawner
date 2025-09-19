@tool
class_name WiggleModifier extends SpawnModifier

@export var axis: Vector3.Axis = Vector3.Axis.AXIS_Y ## this axis is modified
@export var along_axis: Vector3.Axis = Vector3.Axis.AXIS_Z ## this axis is moved/ varied along
@export var amplitude := 1.0 ## meters +- from original position in axis
@export var period := 1.0 ## 'stretch' of cosine function - with 1.0 it takes 1m to repeat

# TODO this should maybe take the curve progress as an input instead of using only one axis of the global position
# for more natural results along very curvy curves

func apply(object: Node3D, point: Vector3, up: Vector3, index: int = 0) -> void:
	var wiggle := Vector3.ZERO
	wiggle[axis] = amplitude * cos(object.global_position[along_axis] * period * 2 * PI)
	object.global_position += wiggle
