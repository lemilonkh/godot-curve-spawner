# Godot Curve Spawner Addon
Godot 4.5+ addon that spawns scenes in regular intervals along a 3D curve, can be synced to BPM and player speed

![CurveSpawner screenshot with fruit spawned along a windy curve and the inspector options visible](/docs/screenshot.png)

## Usage
1. Clone repository into addons/godot-curve-spawner or add it as a submodule
1. There is a demo scene available in [curve_spawner.tscn](/curve_spawner.tscn)

Alternatively, you can set up a CurveSpawner manually like this:

1. Add a CurveSpawner node to a scene
1. Add a Curve3D node as a child of it (otherwise it can be selected with the Path 3D Node property in the Nodes sections of the CurveSpawner inspector).
1. Press the Bake Objects button. If you want to copy or edit the objects afterwards, you can enable the "Add to Scene" option below it. However, changes to any nodes that are children of the Objects child node of the CurveSpawner are lost when the "Bake Objects" button is pressed again, so copy them to a different location in the scene tree or rather a different scene if possible when you use this option and want to make manual changes.
1. Add any modifiers you desire to the curve spawner to alter the position/ rotation of the spawned objects in an automated way.
1. You can also write your own modifiers by creating a subclass of `SpawnModifier` (make sure to add @tool as the first line in the script).

## Planned features
- Placing objects in a set height above terrain/ other colliders by using raycasts in the editor (WIP)
- Specifying spawning patterns using custom resources (e.g. AAABAAAC or AABB/ different scenes used in alternating patterns)
- Extracting meshes from scenes and using multi-meshes for optimizing performance (maybe split into chunks)
- Allowing interaction (e.g. coin pickups) with these multi-meshes by running interactive distance logic in set intervals when the camera/ player is close by
