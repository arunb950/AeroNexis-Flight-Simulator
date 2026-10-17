extends CanvasLayer

## Minimal landscape HUD for the isolated flight-physics prototype.
@export var controls_path: NodePath = NodePath("../Aircraft/FlightControls")
@onready var controls: AeroNexisFlightControls = get_node_or_null(controls_path) as AeroNexisFlightControls
@onready var sensor_label: Label = $Panel/GyroStatus
@onready var throttle_slider: HSlider = $Panel/Throttle

func _ready() -> void:
	$Panel/Calibrate.pressed.connect(_calibrate)
	$Panel/GyroToggle.toggled.connect(_toggle_gyro)
	throttle_slider.value_changed.connect(_set_throttle)
	$Panel/PitchUp.button_down.connect(_pitch_up)
	$Panel/PitchUp.button_up.connect(_clear_touch)
	$Panel/PitchDown.button_down.connect(_pitch_down)
	$Panel/PitchDown.button_up.connect(_clear_touch)
	$Panel/RollLeft.button_down.connect(_roll_left)
	$Panel/RollLeft.button_up.connect(_clear_touch)
	$Panel/RollRight.button_down.connect(_roll_right)
	$Panel/RollRight.button_up.connect(_clear_touch)
	if controls == null:
		sensor_label.text = "FlightControls node missing"

func _process(_delta: float) -> void:
	if controls != null:
		sensor_label.text = controls.gyro_status

func _calibrate() -> void:
	if controls != null: controls.calibrate_gyroscope()

func _toggle_gyro(enabled: bool) -> void:
	if controls != null: controls.set_gyro_enabled(enabled)

func _set_throttle(value: float) -> void:
	if controls != null: controls.throttle = clampf(float(value) / 100.0, -1.0, 1.0)

func _pitch_up() -> void:
	if controls != null: controls.set_touch_axes(1.0, controls._touch_input.x)
func _pitch_down() -> void:
	if controls != null: controls.set_touch_axes(-1.0, controls._touch_input.x)
func _roll_left() -> void:
	if controls != null: controls.set_touch_axes(controls._touch_input.y, -1.0)
func _roll_right() -> void:
	if controls != null: controls.set_touch_axes(controls._touch_input.y, 1.0)
func _clear_touch() -> void:
	if controls != null: controls.clear_touch_axes()
