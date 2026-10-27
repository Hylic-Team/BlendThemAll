extends CharacterBody3D
class_name PlayerController

@export_group("Movement")
@export var move_speed: float = 8.0
@export_range(0.0, 1.0) var backward_speed_multiplier: float = 0.6
@export var strafe_enabled: bool = true
@export_range(0.0, 1.0) var strafe_speed_multiplier: float = 0.8
@export var acceleration: float = 40.0
@export var deceleration: float = 50.0
@export var jump_impulse: float = 8.0

@export_group("Dash")
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6
@export var can_dash_in_air: bool = true

@export_group("Mouse")
@export var mouse_sensitivity: float = 0.1
@export var invert_turn: bool = false
@export var capture_mouse_on_ready: bool = true

var can_move: bool = true
var can_turn: bool = true
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var knockback_time_left: float = 0.0


func _ready() -> void:
	if capture_mouse_on_ready:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured and can_turn:
		rotate_y(deg_to_rad(event.relative.x * mouse_sensitivity * (1.0 if invert_turn else -1.0)))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_impulse
	
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	if Input.is_action_just_pressed("dash"):
		dash()
	
	if is_dashing():
		dash_time_left -= delta
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	else:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var local_target := Vector3(
			input.x * strafe_speed_multiplier if strafe_enabled else 0.0,
			0.0,
			input.y * (backward_speed_multiplier if input.y > 0.0 else 1.0)) * move_speed
		var target := global_basis.orthonormalized() * local_target if can_move else Vector3.ZERO
		
		var rate := acceleration if target != Vector3.ZERO else deceleration
		var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, rate * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.z
	
	move_and_slide()


func dash() -> void:
	if dash_cooldown_left > 0.0 or not can_move or (not is_on_floor() and not can_dash_in_air):
		return
	dash_direction = Vector3(-global_basis.z.x, 0.0, -global_basis.z.z).normalized()
	dash_time_left = dash_duration
	dash_cooldown_left = dash_cooldown


func is_dashing() -> bool:
	return dash_time_left > 0.0


func apply_knockback(force: Vector3, duration: float) -> void:
	dash_time_left = 0.0
	velocity = force
	knockback_time_left = duration
