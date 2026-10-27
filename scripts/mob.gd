extends CharacterBody3D
class_name Enemy

signal scored

enum State { WALK, STUNNED, THROWN }

@export var player: Node3D
@export var throw_target: Node3D
@export var move_speed: float = 3.0
@export var stop_distance: float = 1.2
@export var max_health: int = 3
@export var stun_duration: float = 2.0

@export_group("Flash")
@export var flash_speed: float = 14.0
@export var flash_strength: float = 0.7

@export_group("Throw")
@export var arc_height: float = 2.0
@export_range(0.1, 100.0) var throw_gravity: float = 25.0

var state := State.WALK
var health: int
var stun_time_left: float = 0.0
var throw_start: Vector3
var throw_end: Vector3
var throw_up_speed: float = 0.0
var throw_time: float = 0.0
var throw_duration: float = 1.0
var flash_material := StandardMaterial3D.new()


func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not throw_target:
		throw_target = get_tree().get_first_node_in_group("throw_target")

	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	for geometry: GeometryInstance3D in find_children("*", "GeometryInstance3D", true, false):
		geometry.material_overlay = flash_material


func _physics_process(delta: float) -> void:
	match state:
		State.WALK:
			walk(delta)
		State.STUNNED:
			stunned(delta)
		State.THROWN:
			fly(delta)


func walk(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var dir := Vector3.ZERO
	if is_instance_valid(player):
		var to_player := (player.global_position - global_position) * Vector3(1, 0, 1)
		if to_player.length() > 0.01:
			look_at(global_position + to_player)
		if to_player.length() > stop_distance:
			dir = to_player.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	move_and_slide()


func stunned(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

	stun_time_left -= delta
	flash_material.albedo_color.a = flash_strength * (0.5 + 0.5 * sin(stun_time_left * flash_speed))
	if stun_time_left <= 0.0:
		health = 1
		state = State.WALK
		flash_material.albedo_color.a = 0.0


func fly(delta: float) -> void:
	throw_time = minf(throw_time + delta, throw_duration)
	var pos := throw_start.lerp(throw_end, throw_time / throw_duration)
	pos.y = throw_start.y + throw_up_speed * throw_time - 0.5 * throw_gravity * throw_time * throw_time
	global_position = pos
	if throw_time >= throw_duration:
		scored.emit()
		queue_free()


func take_damage(amount: float) -> void:
	match state:
		State.WALK:
			health -= roundi(amount)
			if health <= 0:
				stun()
		State.STUNNED:
			launch()


func stun() -> void:
	health = 0
	state = State.STUNNED
	stun_time_left = stun_duration
	velocity = Vector3(0.0, velocity.y, 0.0)


func launch() -> void:
	if not throw_target:
		queue_free()
		return
	state = State.THROWN
	remove_from_group("enemy")
	collision_layer = 0
	collision_mask = 0
	flash_material.albedo_color.a = flash_strength
	throw_start = global_position
	throw_end = throw_target.global_position
	var apex := maxf(throw_start.y, throw_end.y) + arc_height
	throw_up_speed = sqrt(2.0 * throw_gravity * (apex - throw_start.y))
	throw_duration = maxf(throw_up_speed / throw_gravity + sqrt(2.0 * (apex - throw_end.y) / throw_gravity), 0.01)
