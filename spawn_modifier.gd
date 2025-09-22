@tool
@abstract
class_name SpawnModifier extends Resource

var uses_physics := false ## used in e.g. RaycastModifier to defer work to _physics_process

func apply(object: Node3D, point: Vector3, up: Vector3, index: int, curve_progress: float) -> void:
	pass
