@tool
class_name CurveSpawner extends Node3D

@export_tool_button("Bake Objects", "Bake") var bake_button := bake_objects
@export var add_to_scene := false ## when enabled, nodes are added to the scene and saved with it (by setting the owner)
@export var use_auto_bake := false: ## when curve is changed, update spawned objects to be moved onto the new path
	set(value):
		use_auto_bake = value
		if use_auto_bake:
			path_3d.curve_changed.connect(bake_objects)
		elif path_3d.curve_changed.is_connected(bake_objects):
			path_3d.curve_changed.disconnect(bake_objects)

@export_category("Object Modifiers")
@export var modifiers: Array[SpawnModifier] = []

@export_category("Object Selection")
@export var use_random_pattern := true ## if index_pattern should be ignored and all objects picked randomly (according to random_seed)
@export var use_object_shuffle := false ## if objects should be shuffled before applying pattern (using random_seed)
@export_range(0, 1000000) var random_seed := 1
@export var index_pattern := "AABB"

@export_category("Nodes")
@export_node_path("Path3D") var path_3d_node := ^"Path3D":
	set(value):
		if is_instance_valid(path_3d) and path_3d.curve_changed.is_connected(bake_objects):
			path_3d.curve_changed.disconnect(bake_objects)
		
		path_3d_node = value
		path_3d = get_node(path_3d_node)
		if use_auto_bake:
			path_3d.curve_changed.connect(bake_objects)
@export_node_path("Node3D") var objects_container_node := ^"Objects":
	set(value):
		var new_container := get_node(objects_container_node)
		
		# make sure no non-editable objects are left in the temporary scene accidentally
		if not add_to_scene and is_instance_valid(objects_container) and objects_container != new_container:
			for child in objects_container.get_children():
				child.queue_free()
		
		objects_container_node = value
		objects_container = new_container

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
@export var lock_rotation := false ## if the rotation of the spawned scenes should stay constant or align with the curve
@export var only_y_rotation := false ## if the rotation of the spawned scenes should aling with the curve but only as rotation around the object's Y axis, ignores lock_rotation.

@onready var path_3d: Path3D = get_node(path_3d_node)
@onready var objects_container: Node3D = get_node(objects_container_node)
@onready var curve: Curve3D = path_3d.curve

var rng := RandomNumberGenerator.new()

func _validate_property(property: Dictionary):
	if not use_bpm and (property.name == "bpm" or property.name == "average_player_speed"):
		property.usage |= PROPERTY_USAGE_NO_EDITOR
	if use_bpm and property.name == "default_spacing":
		property.usage |= PROPERTY_USAGE_READ_ONLY
	
	#if property.name == "index_pattern":
		#if use_random_pattern:
			#property.usage |= PROPERTY_USAGE_READ_ONLY
		#else:
			#property.usage &= ~PROPERTY_USAGE_READ_ONLY
	#elif property.name == "random_seed":
		#if not use_random_pattern:
			#property.usage |= PROPERTY_USAGE_READ_ONLY
		#else:
			#property.usage &= ~PROPERTY_USAGE_READ_ONLY

func _exit_tree() -> void:
	path_3d.curve_changed.disconnect(bake_objects)

func bake_objects() -> void:
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
	
	# remove non-alphabetic characters from pattern string
	var active_pattern := index_pattern
	if not use_random_pattern:
		# TODO cache compiled regex?
		var regex := RegEx.new()
		regex.compile("^[A-Za-z]")
		active_pattern = regex.sub(active_pattern, "", true).to_upper()
	
	var total_length := curve.get_baked_length()
	var index := 0
	
	for offset: float in range(0, total_length, object_interval):
		# TODO measure impact of cubic sampling (true argument)
		var object_transform := curve.sample_baked_with_rotation(offset, true)
		var point := path_3d.to_global(object_transform.origin)
		object_transform.origin = point
		
		var path_basis := path_3d.global_transform.basis
		var up_vector := path_basis * object_transform.basis.y
		var forward_vector := path_basis * object_transform.basis.z
		
		var curve_progress := 0.0
		if total_length >= 0:
			curve_progress = offset / total_length
		
		# TODO implement this as RandomPattern and add 1-3 pattern and AABB pattern etc.
		# [Strategy pattern with enum]
		# either user selectable with dropdown or custom resource exported as abstract base class
		var object_index := 0
		if use_random_pattern:
			object_index = rng.randi_range(0, objects.size() - 1)
		else:
			var active_objects := objects
			if use_object_shuffle:
				active_objects = objects.duplicate()
				CurveSpawnerUtils.shuffle(active_objects, rng)
			
			# pick by pattern
			var pattern_index := index % active_pattern.length()
			var index_letter := active_pattern[pattern_index]
			object_index = abs(ord(index_letter) - ord("A"))
		
		var object_scene: PackedScene = objects[object_index]
		var object: Node3D = object_scene.instantiate()
		objects_container.add_child(object, true) # force readable names
		object.scale = Vector3.ONE * object_scale
		
		if only_y_rotation:
			object.global_position = point
			object.global_rotation.y += object_transform.basis.get_euler().y
		elif lock_rotation:
			object.global_position = point
		else:
			object.global_transform = object_transform
		
		if add_to_scene:
			if Engine.is_editor_hint():
				object.owner = EditorInterface.get_edited_scene_root()
			else:
				object.owner = self.owner
		
		for modifier: SpawnModifier in modifiers:
			if modifier:
				modifier.apply(object, point, up_vector, forward_vector, index, curve_progress)
		
		index += 1
