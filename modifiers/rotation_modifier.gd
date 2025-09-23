@tool
class_name RotationModifier extends SpawnModifier

func apply(object: Node3D, point: Vector3, up: Vector3, forward: Vector3, index: int, curve_progress: float) -> void:
	var global_up := point + up
	object.look_at(global_up)
