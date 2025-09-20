class_name CurveSpawnerUtils extends Node

## performs Fisher-Yates algorithm for unbiased shuffle
static func shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in array.size() - 2:
		var j := rng.randi_range(i, array.size() - 1)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
