extends RigidBody3D
class_name AeroNexisAircraftPhysics

## Game-oriented rigid-body flight model. This is not certified or full-fidelity real aircraft simulation.
@export_file("*.json") var aircraft_config_path: String = "res://aircraft/cessna_172/aircraft.json"
@export var controls_path: NodePath = NodePath("FlightControls")
@export var sea_level_air_density: float = 1.225
@export var wind_velocity_world: Vector3 = Vector3.ZERO
@export var apply_stability_assist: bool = true
@export var runway_centerline_assist: bool = false

var aircraft_config: Dictionary = {}
var airspeed_mps: float = 0.0
var indicated_airspeed_knots: float = 0.0
var angle_of_attack_deg: float = 0.0
var lift_coefficient: float = 0.0
var vertical_lift_n: float = 0.0
var altitude_m: float = 0.0
var vertical_speed_mps: float = 0.0
var heading_deg: float = 0.0
var stall_warning: bool = false
var fuel_liters: float = 0.0
var engine_running: bool = false
var _controls: AeroNexisFlightControls
var _last_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	_load_aircraft_config()
	_controls = get_node_or_null(controls_path) as AeroNexisFlightControls
	if _controls == null:
		push_warning("AeroNexis: FlightControls node not found; keyboard control is unavailable.")
	if aircraft_config.is_empty():
		push_warning("AeroNexis: Aircraft configuration is missing; using safe fallback parameters.")
	fuel_liters = float(aircraft_config.get("max_fuel_capacity_l", 212.0))
	_last_velocity = linear_velocity
	can_sleep = false

func _physics_process(delta: float) -> void:
	var density: float = _air_density_at_altitude(global_position.y)
	var local_air_velocity: Vector3 = global_transform.basis.inverse() * (linear_velocity - wind_velocity_world)
	var aero: Dictionary = AeroNexisAerodynamics.calculate_forces(local_air_velocity, aircraft_config, density)
	var aero_basis: Basis = global_transform.basis
	var lift_local: Vector3 = aero.get("lift", Vector3.ZERO)
	var drag_local: Vector3 = aero.get("drag", Vector3.ZERO)
	var lift_world: Vector3 = aero_basis * lift_local
	var drag_world: Vector3 = aero_basis * drag_local
	vertical_lift_n = lift_world.dot(Vector3.UP)
	apply_central_force(lift_world + drag_world)
	_apply_engine_thrust()
	_apply_control_moments(local_air_velocity, delta)
	_apply_ground_steering_and_centerline(delta)
	_apply_ground_braking(delta)
	_update_telemetry(local_air_velocity, aero, delta)

func _load_aircraft_config() -> void:
	if not FileAccess.file_exists(aircraft_config_path):
		return
	var file: FileAccess = FileAccess.open(aircraft_config_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		aircraft_config = parsed as Dictionary
	else:
		push_warning("AeroNexis: Invalid aircraft JSON: " + aircraft_config_path)

func _apply_engine_thrust() -> void:
	# Throttle is signed: -1..0 selects reverse thrust on the ground,
	# 0..1 selects forward power. Reverse is deliberately unavailable in flight.
	if _controls == null or not engine_running or fuel_liters <= 0.0:
		return
	var throttle_value: float = clampf(float(_controls.throttle), -1.0, 1.0)
	if absf(throttle_value) <= 0.001:
		return
	# The parking brake prevents both forward and reverse movement.
	if _controls.brakes >= 0.95:
		return
	var forward: Vector3 = -global_transform.basis.z.normalized()
	var max_thrust: float = maxf(1000.0, float(aircraft_config.get("max_thrust_n", 4200.0)))
	if global_position.y < 2.0:
		# Use physical force rather than editing linear_velocity directly. Direct velocity
		# changes can be cancelled by Jolt's ground-contact solver on a parked aircraft.
		var forward_speed: float = linear_velocity.dot(forward)
		var aircraft_mass: float = maxf(mass, 1.0)
		if throttle_value > 0.0 and forward_speed < 38.0:
			var forward_accel: float = 7.0 * throttle_value
			var speed_limit_factor: float = clampf((38.0 - forward_speed) / 3.0, 0.0, 1.0)
			apply_central_force(forward * aircraft_mass * forward_accel * speed_limit_factor)
		elif throttle_value < 0.0 and forward_speed > -8.0:
			# Reverse thrust pushes backward, with a conservative taxi-speed limit.
			var reverse_accel: float = 3.0 * absf(throttle_value)
			var reverse_limit_factor: float = clampf((forward_speed + 8.0) / 2.0, 0.0, 1.0)
			apply_central_force(-forward * aircraft_mass * reverse_accel * reverse_limit_factor)
	elif throttle_value > 0.0:
		# In flight, negative throttle behaves as idle rather than reversing the aircraft.
		apply_central_force(forward * max_thrust * throttle_value)

func _apply_control_moments(local_air_velocity: Vector3, _delta: float) -> void:
	if _controls == null:
		return
	var speed_factor: float = clampf(local_air_velocity.length() / 55.0, 0.15, 1.5)
	var pitch_input: float = _controls.pitch
	var roll_input: float = _controls.roll
	var yaw_input: float = _controls.yaw
	var pitch_authority: float = float(aircraft_config.get("pitch_moment_nm", 9000.0))
	var roll_authority: float = float(aircraft_config.get("roll_moment_nm", 7000.0))
	var yaw_authority: float = float(aircraft_config.get("yaw_moment_nm", 3500.0))
	var local_torque := Vector3(pitch_input * pitch_authority, yaw_input * yaw_authority, -roll_input * roll_authority) * speed_factor
	if apply_stability_assist and absf(pitch_input) < 0.05 and absf(roll_input) < 0.05:
		var local_angular: Vector3 = global_transform.basis.inverse() * angular_velocity
		local_torque.x -= local_angular.x * float(aircraft_config.get("pitch_damping", 1800.0))
		local_torque.z -= local_angular.z * float(aircraft_config.get("roll_damping", 1600.0))
	local_torque.y -= angular_velocity.dot(global_transform.basis.y) * float(aircraft_config.get("yaw_damping", 900.0))
	apply_torque(global_transform.basis * local_torque)


func _apply_ground_steering_and_centerline(_delta: float) -> void:
	if _controls == null or global_position.y > 2.0:
		return
	var horizontal_speed := Vector2(linear_velocity.x, linear_velocity.z).length()
	var forward_speed := maxf(0.0, -global_transform.basis.z.dot(linear_velocity))
	# Rudder authority on the ground is primarily nose-wheel steering at low speed,
	# becoming more aerodynamic as the aircraft accelerates.
	if horizontal_speed > 0.15 and absf(_controls.yaw) > 0.01:
		var steering_strength := lerpf(0.65, 0.20, clampf(forward_speed / 22.0, 0.0, 1.0))
		var local_steer_torque := Vector3(0.0, _controls.yaw * 900.0 * steering_strength, 0.0)
		apply_torque(global_transform.basis * local_steer_torque)
		var lateral_force := global_transform.basis.x * _controls.yaw * minf(850.0, horizontal_speed * 42.0)
		apply_central_force(lateral_force)
	# Gentle runway directional assistance reduces accidental drift when the rudder
	# returns to neutral. Pilot input still has authority to steer away deliberately.
	if runway_centerline_assist and horizontal_speed > 1.0 and absf(_controls.yaw) < 0.08:
		var heading := atan2(-global_transform.basis.z.x, -global_transform.basis.z.z)
		var heading_correction := clampf(-heading * 1.8, -0.7, 0.7)
		if absf(global_position.x) < 18.0:
			var lateral_correction := clampf(-global_position.x * 0.035, -0.45, 0.45)
			var assist := (global_transform.basis.x * lateral_correction * minf(260.0, horizontal_speed * 18.0))
			apply_central_force(assist)
			apply_torque(global_transform.basis * Vector3(0.0, heading_correction * 220.0, 0.0))
	# Modest rolling resistance. Keep it below low-speed propeller thrust so the
	# aircraft accelerates reliably from a standstill on a flat runway.
	if horizontal_speed > 0.1:
		apply_central_force(-Vector3(linear_velocity.x, 0.0, linear_velocity.z).normalized() * 6.0)

func _apply_ground_braking(_delta: float) -> void:
	if _controls == null or _controls.brakes <= 0.0 or global_position.y > 2.0:
		return
	var horizontal_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if horizontal_velocity.length() > 0.1:
		apply_central_force(-horizontal_velocity.normalized() * float(aircraft_config.get("brake_force_n", 12000.0)) * _controls.brakes)

func _update_telemetry(local_air_velocity: Vector3, aero: Dictionary, delta: float) -> void:
	airspeed_mps = local_air_velocity.length()
	indicated_airspeed_knots = airspeed_mps * 1.943844
	angle_of_attack_deg = float(aero.get("angle_of_attack_deg", 0.0))
	lift_coefficient = float(aero.get("lift_coefficient", 0.0))
	altitude_m = global_position.y
	vertical_speed_mps = (linear_velocity.y - _last_velocity.y) / maxf(delta, 0.0001) if delta > 0.0 else linear_velocity.y
	heading_deg = fposmod(rad_to_deg(atan2(-global_transform.basis.z.x, -global_transform.basis.z.z)), 360.0)
	stall_warning = absf(angle_of_attack_deg) >= float(aircraft_config.get("stall_angle_deg", 16.0))
	_last_velocity = linear_velocity
	if engine_running and _controls != null and absf(_controls.throttle) > 0.01 and fuel_liters > 0.0:
		var burn_lph: float = float(aircraft_config.get("fuel_burn_lph", 35.0)) * absf(_controls.throttle)
		fuel_liters = maxf(0.0, fuel_liters - burn_lph * delta / 3600.0)

func _air_density_at_altitude(altitude: float) -> float:
	# Approximate troposphere model, clamped for a game-scale operating envelope.
	var h: float = clampf(altitude, -500.0, 11000.0)
	return sea_level_air_density * pow(maxf(0.1, 1.0 - 0.0000225577 * h), 4.256)
