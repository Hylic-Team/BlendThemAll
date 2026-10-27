extends Area3D
class_name HitComponent

@export var player: PlayerController
@export var enemy_group: StringName = &"enemy"
@export var radius: float = 0.8
@export var active_time: float = 0.4

@export_group("Damage")
@export var damage: float = 1.0
@export var jump_damage_multiplier: float = 2.0

@export_group("Knockback")
@export var knockback_force: float = 15.0
@export var jump_knockback_force: float = 8.0
@export var jump_knockback_up: float = 4.0
@export var knockback_time: float = 0.15

var active_time_left: float = 0.0
var hit_targets: Array[Node3D] = []
var debug_mesh := MeshInstance3D.new()


func _ready() -> void:
	if not player:
		player = get_parent() as PlayerController
	monitorable = false

	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = radius
	add_child(shape)

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.2, 0.2, 0.4)
	debug_mesh.mesh = SphereMesh.new()
	debug_mesh.mesh.radius = radius
	debug_mesh.mesh.height = radius * 2.0
	debug_mesh.material_override = material
	add_child(debug_mesh)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("hit"):
		hit()
	
	debug_mesh.visible = active_time_left > 0.0
	if not debug_mesh.visible:
		return
	
	active_time_left -= delta
	for body in get_overlapping_bodies():
		if body.is_in_group(enemy_group) and body not in hit_targets:
			register_hit(body)


func hit() -> void:
	if active_time_left <= 0.0:
		hit_targets.clear()
		active_time_left = active_time


func register_hit(enemy: Node3D) -> void:
	hit_targets.append(enemy)
	var from_jump := not player.is_on_floor()
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage * (jump_damage_multiplier if from_jump else 1.0))
	
	var dir := ((player.global_position - enemy.global_position) * Vector3(1, 0, 1)).normalized()
	if dir == Vector3.ZERO:
		dir = player.global_basis.z
	var pushback := dir * jump_knockback_force + Vector3.UP * jump_knockback_up if from_jump else dir * knockback_force
	player.apply_knockback(pushback, knockback_time)
