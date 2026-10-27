extends Camera3D
class_name ArenaCamera

@export var target: Node3D
@export var rail_start: Node3D
@export var rail_end: Node3D
@export_range(-2.0, 2.0) var follow_ratio: float = -1.0
@export var smoothing: float = 6.0
@export var look_height_offset: float = 1.0

@export_group("Zoom")
@export var near_distance: float = 6.0
@export var far_distance: float = 20.0
@export_range(1.0, 179.0) var near_fov: float = 70.0
@export_range(1.0, 179.0) var far_fov: float = 55.0


func _ready() -> void:
	if target and rail_start and rail_end:
		global_position = rail_position()
		look_at(target.global_position + Vector3.UP * look_height_offset)
		fov = zoom_fov()


func _process(delta: float) -> void:
	if not (is_instance_valid(target) and rail_start and rail_end):
		return
	var desired := rail_position()
	var weight := 1.0 if smoothing <= 0.0 else 1.0 - exp(-smoothing * delta)
	global_position = global_position.lerp(desired, weight)
	look_at(target.global_position + Vector3.UP * look_height_offset)
	fov = lerpf(fov, zoom_fov(), weight)


func rail_position() -> Vector3:
	var a := rail_start.global_position
	var b := rail_end.global_position
	var rail := b - a
	var player_offset := (target.global_position - (a + b) * 0.5).dot(rail.normalized())
	return a.lerp(b, clampf(0.5 + player_offset * follow_ratio / rail.length(), 0.0, 1.0))


func zoom_fov() -> float:
	var distance := global_position.distance_to(target.global_position)
	return lerpf(near_fov, far_fov, clampf(inverse_lerp(near_distance, far_distance, distance), 0.0, 1.0))
