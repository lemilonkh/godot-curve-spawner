@tool
class_name CurveSpawner extends Node3D

@export_tool_button("Bake Objects", "Bake") var bake_button := _bake
@export_range(0, 1000000) var random_seed := 1
@export var add_to_scene := false ## when enabled, nodes are added to the scene and saved with it (by setting the owner)
@export var use_auto_bake := false: ## when curve is changed, update spawned objects to be moved onto the new path
	set(value):
		use_auto_bake = value
		if use_auto_bake:
			_setup_timer()
		else:
			_clear_timer()

@export_category("Nodes")
@export_node_path("Path3D") var path_3d_node := ^"Path3D"
@export_node_path("Node3D") var objects_container_node := ^"Objects"

@export_category("Objects")
@export var objects: Array[PackedScene] = []

@export_category("Spacing")
@export_range(0, 1000) var default_spacing := 2.0 ## meters, only used if use_bpm is false

@export_subgroup("Sync with Beats per Minute")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var use_bpm: bool = true: ## enables sync with beats per minute feature
	set(value):
		use_bpm = value
		notify_property_list_changed()
@export_range(10, 300) var bpm := 140.0 ## beats per minute
@export_range(0, 50) var average_player_speed := 20.0 ## meters/second

@export_category("Transforms")
@export_range(0, 100) var object_scale := 1.0

@export_category("Modifiers")
@export var modifiers: Array[SpawnModifier] = []

const AUTOBAKE_INTERVAL := 5.0 ## seconds

@onready var path_3d: Path3D = get_node(path_3d_node)
@onready var objects_container: Node3D = get_node(objects_container_node)
@onready var curve: Curve3D = path_3d.curve

var rng := RandomNumberGenerator.new()
var was_curve_changed := true
var timer: Timer = null

func _validate_property(property: Dictionary):
	if not use_bpm and (property.name == "bpm" or property.name == "average_player_speed"):
		property.usage |= PROPERTY_USAGE_NO_EDITOR
	if use_bpm and property.name == "default_spacing":
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _ready() -> void:
	path_3d.curve_changed.connect(_on_curve_changed)
	if use_auto_bake:
		_setup_timer()


func _exit_tree() -> void:
	_clear_timer()


func _setup_timer() -> void:
	if is_instance_valid(timer):
		_clear_timer()
	
	timer = Timer.new()
	timer.wait_time = AUTOBAKE_INTERVAL
	add_child(timer)
	timer.one_shot = false
	timer.timeout.connect(_on_timeout)
	timer.start()


func _clear_timer() -> void:
	if is_instance_valid(timer):
		if timer.timeout.is_connected(_on_curve_changed):
			timer.timeout.disconnect(_on_curve_changed)
		timer.queue_free()
		timer = null


func _on_curve_changed() -> void:
	# update spawned objects to be moved onto the new path (next time _on_timeout is called)
	was_curve_changed = true


func _on_timeout() -> void:
	if use_auto_bake and was_curve_changed:
		_bake()


func _bake() -> void:
	rng.seed = random_seed
	
	var object_interval := 0.0
	if use_bpm:
		var beat_time := 60.0 / bpm
		var beat_distance := average_player_speed * beat_time
		object_interval = beat_distance
	else:
		object_interval = default_spacing
	
	for child: Node3D in objects_container.get_children():
		child.queue_free() # TODO introduce object pooling?
	
	var total_length := curve.get_baked_length()
	var index := 0
	
	for offset: float in range(0, total_length, object_interval):
		var object_transform := curve.sample_baked_with_rotation(offset, true) # TODO measure impact of cubic sampling (true argument)
		var up_vector := object_transform.basis.y
		var point := object_transform.origin
		
		# TODO implement this as RandomPattern and add 1-3 pattern and AABB pattern etc.
		# either user selectable with dropdown or custom resource exported as abstract base class
		var mesh_index := rng.randi_range(0, objects.size() - 1)
		var object_scene: PackedScene = objects[mesh_index]
		var object: Node3D = object_scene.instantiate()
		objects_container.add_child(object)
		object.global_transform = object_transform
		#object.global_position = path_3d.to_global(point)
		object.scale = Vector3.ONE * object_scale
		
		if add_to_scene:
			if Engine.is_editor_hint():
				object.owner = EditorInterface.get_edited_scene_root()
			else:
				object.owner = self.owner
		
		for modifier: SpawnModifier in modifiers:
			modifier.apply(object, point, up_vector, index)
		
		index += 1
	
	was_curve_changed = false
