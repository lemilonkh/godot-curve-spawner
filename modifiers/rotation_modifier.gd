@tool
class_name RotationModifier extends SpawnModifier

func apply(object: Node3D, point: Vector3, up: Vector3, index: int = 0) -> void:
	var global_up := point + up
	object.look_at(global_up)
