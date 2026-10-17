extends Node
class_name AeroNexisFlightControls

## Shared flight input. Mobile tilt uses the accelerometer's gravity vector,
## so controls respond to the phone's current angle rather than integrating gyro
## angular velocity (which drifts and may be unavailable on some devices).

@export var keyboard_enabled: bool = true
@export var gyro_enabled: bool = true # Kept as a serialized compatibility toggle; controls accelerometer tilt.
@export_range(5.0, 60.0, 1.0) var max_tilt_degrees: float = 25.0
@export_range(0.1, 5.0, 0.1) var gyro_sensitivity: float = 1.0 # Sensitivity multiplier for tilt controls.
@export_range(0.0, 0.25, 0.01) var dead_zone: float = 0.035
@export_range(1.0, 20.0, 0.5) var smoothing_speed: float = 8.0
@export var landscape_axis_swap: bool = false
@export var invert_pitch: bool = false
@export var invert_roll: bool = false
@export var throttle_change_per_second: float = 0.35

var pitch: float = 0.0
var roll: float = 0.0
var yaw: float = 0.0
var throttle: float = 0.0
var brakes: float = 0.0
var flaps: float = 0.0
var gear_down: bool = true
var autopilot_enabled: bool = false
var gyro_available: bool = false # Compatibility name; indicates mobile sensor support.
var gyro_calibrated: bool = false # Compatibility name; means accelerometer tilt calibrated.
var gyro_status: String = "Accelerometer unavailable — touch/keyboard controls active"

var _neutral_angles := Vector2.ZERO
var _filtered_acceleration := Vector3.ZERO
var _sensor_initialized: bool = false
var _tilt_input := Vector2.ZERO # x = roll, y = pitch
var _touch_input := Vector2.ZERO
var _smoothed_input := Vector2.ZERO

func _ready() -> void:
	gyro_available = OS.has_feature("android") or OS.has_feature("ios")
	if gyro_available and gyro_enabled:
		gyro_status = "ACCELEROMETER READY — hold phone neutral and calibrate"
	else:
		gyro_status = "Touch/keyboard controls active"

func _process(delta: float) -> void:
	_update_accelerometer(delta)
	var target := _touch_input
	if gyro_enabled and gyro_available and gyro_calibrated:
		target = _tilt_input
	if keyboard_enabled:
		var key_pitch := (1.0 if Input.is_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) else 0.0)
		var key_roll := (1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0)
		if absf(key_pitch) > 0.0 or absf(key_roll) > 0.0:
			target = Vector2(key_roll, key_pitch)
	_smoothed_input = _smoothed_input.lerp(target, 1.0 - exp(-smoothing_speed * delta))
	roll = _apply_dead_zone(_smoothed_input.x)
	pitch = _apply_dead_zone(_smoothed_input.y)
	if invert_pitch: pitch = -pitch
	if invert_roll: roll = -roll
	if keyboard_enabled:
		var key_yaw := (1.0 if Input.is_key_pressed(KEY_E) else 0.0) - (1.0 if Input.is_key_pressed(KEY_Q) else 0.0)
		if absf(key_yaw) > 0.0:
			yaw = key_yaw
		if Input.is_key_pressed(KEY_R): throttle = minf(1.0, throttle + throttle_change_per_second * delta)
		if Input.is_key_pressed(KEY_F): throttle = maxf(-1.0, throttle - throttle_change_per_second * delta)
		if Input.is_key_pressed(KEY_SPACE): brakes = 1.0
		if Input.is_key_pressed(KEY_G): gear_down = true
		if Input.is_key_pressed(KEY_H): gear_down = false

func _update_accelerometer(delta: float) -> void:
	if not gyro_enabled or not gyro_available:
		return
	var acceleration: Vector3 = Input.get_accelerometer()
	# A zero vector usually means the platform/editor has no sensor data yet.
	if acceleration.length_squared() < 1.0:
		if not _sensor_initialized:
			gyro_status = "WAITING FOR ACCELEROMETER — use touch controls if unavailable"
		return
	if not _sensor_initialized:
		_filtered_acceleration = acceleration
		_sensor_initialized = true
	else:
		# Low-pass filter suppresses vibration and short movement spikes.
		_filtered_acceleration = _filtered_acceleration.lerp(acceleration, 1.0 - exp(-12.0 * delta))
	var a := _filtered_acceleration
	# Convert the gravity vector into two tilt angles. Using atan2 with the
	# other two axes avoids division by zero when the phone is held upright.
	var angles := Vector2(
		atan2(a.x, sqrt(a.y * a.y + a.z * a.z)),
		atan2(a.y, sqrt(a.x * a.x + a.z * a.z))
	)
	var relative := angles - _neutral_angles
	if landscape_axis_swap:
		relative = Vector2(relative.y, -relative.x)
	var limit_rad := maxf(deg_to_rad(max_tilt_degrees), 0.01)
	var normalized := Vector2(
		clampf(relative.x * gyro_sensitivity / limit_rad, -1.0, 1.0),
		clampf(relative.y * gyro_sensitivity / limit_rad, -1.0, 1.0)
	)
	_tilt_input = normalized
	if gyro_calibrated:
		gyro_status = "ACCEL ACTIVE • TILT %d%%" % int(maxf(absf(normalized.x), absf(normalized.y)) * 100.0)
	else:
		gyro_status = "ACCEL READY — hold neutral and tap CALIBRATE"

func calibrate_gyroscope() -> void:
	if not _sensor_initialized:
		gyro_status = "NO ACCELEROMETER DATA — touch controls remain available"
		return
	var a := _filtered_acceleration
	_neutral_angles = Vector2(
		atan2(a.x, sqrt(a.y * a.y + a.z * a.z)),
		atan2(a.y, sqrt(a.x * a.x + a.z * a.z))
	)
	gyro_calibrated = true
	gyro_status = "ACCELEROMETER CALIBRATED — tilt to control"

func set_touch_axes(pitch_axis: float, roll_axis: float) -> void:
	_touch_input = Vector2(clampf(roll_axis, -1.0, 1.0), clampf(pitch_axis, -1.0, 1.0))

func clear_touch_axes() -> void:
	_touch_input = Vector2.ZERO

func set_gyro_enabled(enabled: bool) -> void:
	gyro_enabled = enabled
	if not enabled:
		gyro_status = "Touch/keyboard controls active"
	elif gyro_available:
		gyro_status = "Hold phone neutral and tap CALIBRATE"

func _apply_dead_zone(value: float) -> float:
	if absf(value) <= dead_zone:
		return 0.0
	return signf(value) * (absf(value) - dead_zone) / (1.0 - dead_zone)
