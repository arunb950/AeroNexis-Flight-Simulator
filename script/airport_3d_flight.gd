extends Node3D
## Procedurally built airport apron/runway and a flyable low-poly Cessna 172.
## Airport coordinates and spawn choice are loaded from user://selected_route.json.

const AIRCRAFT_PHYSICS := preload("res://script/flight/aircraft_physics.gd")
const FLIGHT_CONTROLS := preload("res://script/flight/flight_controls.gd")

var aircraft: RigidBody3D
var flight_controls: AeroNexisFlightControls
var chase_camera: Camera3D
var cockpit_camera: Camera3D
var camera_mode_button: Button
var cockpit_view := false
var airport_title: Label
var telemetry_label: Label
var message_label: Label
var throttle_slider: VSlider
var rudder_slider: HSlider
var route_data: Dictionary = {}
var airport_data: Dictionary = {}
var spawn_location := "runway"
var airport_code := "VNKT"
var airport_name := "AeroNexis International"
var arrival_code := "VNLK"
var _camera_offset := Vector3(0, 7.0, 17.0)
var camera_pivot: Node3D
var _camera_drag_active := false
var _camera_drag_last := Vector2.ZERO
var _camera_yaw_deg := 0.0
var _camera_pitch_deg := -17.0
var _hud_layer: CanvasLayer
var _throttle_readout: Label
var _rudder_readout: Label
var _speed_readout: Label
var _altitude_readout: Label
var _lift_readout: Label
var _takeoff_readout: Label
var _engine_readout: Label
var _propeller_pivot: Node3D

func _ready() -> void:
	_load_route()
	_build_environment()
	_build_airport()
	_spawn_cessna()
	_build_camera()
	_build_hud()

func _load_route() -> void:
	if FileAccess.file_exists("user://selected_route.json"):
		var file := FileAccess.open("user://selected_route.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				route_data = parsed
	var dep: Variant = route_data.get("departure", {})
	var arr: Variant = route_data.get("arrival", {})
	if dep is Dictionary:
		airport_data = dep
		airport_code = str(dep.get("icao", airport_code))
		airport_name = str(dep.get("name", airport_name))
	if arr is Dictionary:
		arrival_code = str(arr.get("icao", arrival_code))
	# Read the route choice first; the standalone spawn file is a compatibility fallback.
	var saved_spawn: Variant = route_data.get("spawn_location", null)
	if saved_spawn == null and FileAccess.file_exists("user://spawn_location.json"):
		var spawn_file := FileAccess.open("user://spawn_location.json", FileAccess.READ)
		if spawn_file:
			var spawn_parsed: Variant = JSON.parse_string(spawn_file.get_as_text())
			spawn_file.close()
			if spawn_parsed is Dictionary:
				saved_spawn = spawn_parsed.get("spawn_location", "runway")
	spawn_location = str(saved_spawn if saved_spawn != null else "runway").strip_edges().to_lower()
	if spawn_location not in ["gate", "runway"]:
		spawn_location = "runway"

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#1b5b91")
	sky_material.sky_horizon_color = Color("#a6d8ed")
	sky_material.ground_bottom_color = Color("#172a22")
	sky_material.ground_horizon_color = Color("#9ab8c1")
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b7d8ed")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)

func _build_airport() -> void:
	_add_box("GrassField", Vector3(0, -0.6, 0), Vector3(1200, 1, 900), Color("#4d7045"), true)
	# Runway and shoulders.
	_add_box("RunwayShoulders", Vector3(0, -0.05, -60), Vector3(38, 0.2, 310), Color("#545b60"), true)
	_add_box("Runway", Vector3(0, 0.02, -60), Vector3(32, 0.12, 304), Color("#292f35"), true)
	_add_box("TaxiwayConnector", Vector3(24, 0.03, 8), Vector3(8, 0.1, 100), Color("#41484b"), true)
	_add_box("TaxiwayCross", Vector3(15, 0.03, -25), Vector3(28, 0.1, 8), Color("#41484b"), true)
	_add_box("Apron", Vector3(77, 0.02, 48), Vector3(120, 0.12, 82), Color("#777d7e"), true)
	# Runway threshold bars, centerline dashes and edge lines.
	for side in [-1.0, 1.0]:
		_add_box("RunwayEdgeLine", Vector3(side * 14.5, 0.095, -60), Vector3(0.35, 0.025, 292), Color.WHITE, false)
		for i in range(8):
			_add_box("ThresholdBar", Vector3(side * (2.0 + float(i) * 1.35), 0.095, 87), Vector3(0.7, 0.025, 12), Color.WHITE, false)
		for i in range(19):
			_add_box("CenterlineDash", Vector3(0, 0.095, -195 + float(i) * 15.0), Vector3(0.45, 0.025, 8), Color.WHITE, false)
	# Taxiway centerline yellow markings.
	_add_box("TaxiCenterline", Vector3(24, 0.095, 8), Vector3(0.22, 0.025, 95), Color("#f4d34e"), false)
	_add_box("ApronCenterline", Vector3(35, 0.095, 40), Vector3(36, 0.025, 0.22), Color("#f4d34e"), false)
	# Terminal building and glass facade.
	_add_box("TerminalMain", Vector3(77, 6, 104), Vector3(94, 12, 20), Color("#c4d0d7"), true)
	_add_box("TerminalRoof", Vector3(77, 12.3, 104), Vector3(98, 1, 24), Color("#263d50"), true)
	_add_box("TerminalGlass", Vector3(77, 5.3, 93.7), Vector3(88, 7, 0.45), Color("#4e9eb8"), false)
	_add_box("TerminalLowerWall", Vector3(77, 1.0, 93.3), Vector3(90, 2, 0.7), Color("#dce4e8"), false)
	# Gate bays, yellow lead-in lines, jet bridges and simple gate signs.
	for i in range(5):
		var gx := 42.0 + float(i) * 17.0
		_add_box("GateStandLine", Vector3(gx, 0.10, 55), Vector3(0.25, 0.025, 35), Color("#f5d44d"), false)
		_add_box("GateStopLine", Vector3(gx, 0.10, 37), Vector3(12, 0.025, 0.25), Color.WHITE, false)
		_add_box("JetBridgeArm", Vector3(gx, 4.0, 77), Vector3(3.5, 1.1, 18), Color("#aab9c4"), true)
		_add_box("JetBridgeCabin", Vector3(gx, 4.1, 67), Vector3(5.2, 2.5, 5.0), Color("#d8e1e6"), true)
		_add_box("GatePost", Vector3(gx + 5.5, 2.2, 56), Vector3(0.35, 4.4, 0.35), Color("#344a5b"), true)
		_add_label_3d("GateLabel", "GATE %02d" % (i + 1), Vector3(gx + 5.7, 4.7, 56), Color("#e9f8ff"))
	# Apron floodlights and runway edge lights.
	for i in range(7):
		var z := -190.0 + float(i) * 43.0
		for side in [-1.0, 1.0]:
			_add_light_pole(Vector3(side * 17.5, 0, z))
	for i in range(5):
		_add_light_pole(Vector3(80, 0, 24 + float(i) * 13.0))
	_add_label_3d("AirportSign", airport_code + "  •  AERONEXIS FIELD", Vector3(77, 15.0, 104), Color("#e9f7ff"))
	# Hangar, tower and small service buildings complete the airport silhouette.
	_add_box("Hangar", Vector3(-58, 7, 75), Vector3(36, 14, 28), Color("#9baab3"), true)
	_add_box("HangarRoof", Vector3(-58, 14.2, 75), Vector3(38, 1.0, 30), Color("#526b7c"), true)
	_add_box("TowerBase", Vector3(-95, 8, 83), Vector3(9, 16, 9), Color("#c4cfd5"), true)
	_add_box("TowerCab", Vector3(-95, 18, 83), Vector3(14, 4, 14), Color("#428da8"), true)
	_add_box("TowerRoof", Vector3(-95, 20.5, 83), Vector3(15, 1, 15), Color("#2c4354"), true)

func _spawn_cessna() -> void:
	aircraft = RigidBody3D.new()
	aircraft.name = "Cessna172"
	aircraft.mass = 1111.0
	aircraft.linear_damp = 0.08
	aircraft.angular_damp = 0.7
	# The landing gear is represented by colliders attached to the airframe, not
	# independently rotating wheel bodies. Low contact friction prevents the
	# default high-friction contact from pinning the aircraft in place.
	var aircraft_contact_material := PhysicsMaterial.new()
	aircraft_contact_material.friction = 0.2
	aircraft_contact_material.bounce = 0.0
	aircraft.physics_material_override = aircraft_contact_material
	aircraft.can_sleep = false
	aircraft.continuous_cd = true
	aircraft.set_script(AIRCRAFT_PHYSICS)
	aircraft.set("aircraft_config_path", "res://aircraft/cessna_172/aircraft.json")
	aircraft.set("runway_centerline_assist", spawn_location == "runway")
	# Fuselage collider stays above the runway; individual sphere colliders make
	# the three visible tyres contact the ground instead of sinking through it.
	var collision := CollisionShape3D.new()
	var body_shape := BoxShape3D.new()
	body_shape.size = Vector3(2.0, 0.55, 4.8)
	collision.shape = body_shape
	collision.position = Vector3(0, 0.18, 0)
	aircraft.add_child(collision)
	for side in [-1.0, 1.0]:
		var main_tyre_collision := CollisionShape3D.new()
		main_tyre_collision.name = "MainTyreCollision"
		var main_tyre_shape := SphereShape3D.new()
		main_tyre_shape.radius = 0.23
		main_tyre_collision.shape = main_tyre_shape
		main_tyre_collision.position = Vector3(side * 0.82, -0.56, 0.45)
		aircraft.add_child(main_tyre_collision)
	var nose_tyre_collision := CollisionShape3D.new()
	nose_tyre_collision.name = "NoseTyreCollision"
	var nose_tyre_shape := SphereShape3D.new()
	nose_tyre_shape.radius = 0.17
	nose_tyre_collision.shape = nose_tyre_shape
	nose_tyre_collision.position = Vector3(0, -0.48, -2.1)
	aircraft.add_child(nose_tyre_collision)
	flight_controls = FLIGHT_CONTROLS.new() as AeroNexisFlightControls
	flight_controls.name = "FlightControls"
	aircraft.add_child(flight_controls)
	_build_cessna_model(aircraft)
	# Explicitly separate parking stand and runway start transforms. Gate stands are on
	# the apron beside the terminal (positive Z); the runway is far to the north (negative Z).
	var spawn_transform := Transform3D.IDENTITY
	if spawn_location == "runway":
		spawn_transform.origin = Vector3(0.0, 0.85, 60.0)
	else:
		spawn_transform.origin = Vector3(42.0, 0.85, 47.0)
	spawn_transform.basis = Basis(Vector3.UP, 0.0)
	aircraft.transform = spawn_transform
	aircraft.linear_velocity = Vector3.ZERO
	aircraft.angular_velocity = Vector3.ZERO
	add_child(aircraft)
	# A parked aircraft starts with brakes applied; runway start is ready to taxi/take off.
	flight_controls.brakes = 1.0 if spawn_location == "gate" else 0.0

func _build_cessna_model(parent: Node3D) -> void:
	var white := Color("#e7edf0")
	var blue := Color("#087eae")
	var dark := Color("#203542")
	# Fuselage, cowling and cabin glazing.
	_add_mesh_box(parent, "Fuselage", Vector3(0, 0.15, 0), Vector3(0.82, 0.72, 5.2), white)
	_add_mesh_box(parent, "EngineCowling", Vector3(0, 0.08, -2.65), Vector3(0.76, 0.58, 0.9), white)
	_add_mesh_box(parent, "CabinWindows", Vector3(0, 0.52, -0.05), Vector3(0.72, 0.42, 1.65), Color("#367f9a"))
	# High wing.
	_add_mesh_box(parent, "MainWing", Vector3(0, 0.48, -0.15), Vector3(11.0, 0.16, 1.25), white)
	_add_mesh_box(parent, "WingStripe", Vector3(0, 0.575, -0.15), Vector3(10.7, 0.035, 0.22), blue)
	# Tailplane and vertical stabilizer.
	_add_mesh_box(parent, "Tailplane", Vector3(0, 0.35, 2.15), Vector3(3.1, 0.12, 0.75), white)
	_add_mesh_box(parent, "VerticalTail", Vector3(0, 0.78, 2.25), Vector3(0.16, 1.05, 0.78), blue)
	# Landing gear struts and wheels.
	for side in [-1.0, 1.0]:
		_add_mesh_box(parent, "MainGearStrut", Vector3(side * 0.78, -0.28, 0.45), Vector3(0.09, 0.72, 0.09), dark)
		_add_mesh_cylinder(parent, "MainWheel", Vector3(side * 0.82, -0.56, 0.45), 0.24, 0.15, dark, true)
	_add_mesh_box(parent, "NoseGearStrut", Vector3(0, -0.25, -2.1), Vector3(0.08, 0.55, 0.08), dark)
	_add_mesh_cylinder(parent, "NoseWheel", Vector3(0, -0.48, -2.1), 0.18, 0.12, dark, true)
	# Rotating propeller assembly. The blades are children of a pivot so the engine
	# state and throttle visibly affect the propeller rather than leaving it static.
	_propeller_pivot = Node3D.new()
	_propeller_pivot.name = "PropellerPivot"
	_propeller_pivot.position = Vector3(0, 0.08, -3.23)
	parent.add_child(_propeller_pivot)
	_add_mesh_box(_propeller_pivot, "PropellerHub", Vector3(0, 0, 0.08), Vector3(0.18, 0.18, 0.16), dark)
	_add_mesh_box(_propeller_pivot, "PropellerBladeA", Vector3(0, 0, 0), Vector3(0.09, 1.5, 0.08), dark)
	_add_mesh_box(_propeller_pivot, "PropellerBladeB", Vector3(0, 0, 0), Vector3(1.5, 0.09, 0.08), dark)

func _build_camera() -> void:
	# The pivot is a child of the aircraft, so it follows its position and attitude
	# directly rather than chasing it from the world root.
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.25, 0)
	aircraft.add_child(camera_pivot)
	chase_camera = Camera3D.new()
	chase_camera.name = "ChaseCamera"
	chase_camera.position = Vector3(0, 6.0, 16.0)
	chase_camera.rotation_degrees = Vector3(_camera_pitch_deg, 0, 0)
	chase_camera.current = true
	chase_camera.fov = 68.0
	camera_pivot.add_child(chase_camera)

	# Pilot-eye camera: above the panel/fuselage, looking forward along aircraft -Z.
	cockpit_camera = Camera3D.new()
	cockpit_camera.name = "PilotSeatCamera"
	cockpit_camera.position = Vector3(0, 0.98, -0.72)
	cockpit_camera.rotation_degrees = Vector3.ZERO
	cockpit_camera.current = false
	cockpit_camera.fov = 82.0
	aircraft.add_child(cockpit_camera)

func _toggle_camera() -> void:
	cockpit_view = not cockpit_view
	if cockpit_view:
		cockpit_camera.make_current()
	else:
		chase_camera.make_current()
	if is_instance_valid(camera_mode_button):
		camera_mode_button.text = "CAMERA: PILOT" if cockpit_view else "CAMERA: CHASE"

func _process(delta: float) -> void:
	if not is_instance_valid(aircraft):
		return
	if is_instance_valid(_propeller_pivot):
		var engine_is_running := bool(aircraft.get("engine_running"))
		if engine_is_running:
			var prop_speed := lerpf(0.0, 95.0, maxf(absf(flight_controls.throttle), 0.12))
			_propeller_pivot.rotation.z = fposmod(_propeller_pivot.rotation.z + prop_speed * delta, TAU)
	var speed := 0.0
	if "indicated_airspeed_knots" in aircraft:
		speed = float(aircraft.get("indicated_airspeed_knots"))
	if is_instance_valid(telemetry_label):
		telemetry_label.text = "%s  →  %s   |   %s %d%%   |   %s" % [airport_code, arrival_code, "REV" if flight_controls.throttle < -0.005 else "THR", roundi(absf(flight_controls.throttle) * 100.0), "ENGINE ON" if bool(aircraft.get("engine_running")) else "ENGINE OFF"]
	if is_instance_valid(_speed_readout):
		_speed_readout.text = "%03d kt\nIAS" % int(speed)
	if is_instance_valid(_altitude_readout):
		_altitude_readout.text = "%04d ft\nALT MSL" % int(maxf(aircraft.global_position.y, 0.0) * 3.28084)
	var lift_n := float(aircraft.get("vertical_lift_n")) if "vertical_lift_n" in aircraft else 0.0
	var weight_n := maxf(aircraft.mass * 9.81, 1.0)
	var lift_ratio := lift_n / weight_n
	if is_instance_valid(_lift_readout):
		_lift_readout.text = "LIFT %d%%\nOF WEIGHT" % clampi(roundi(lift_ratio * 100.0), -999, 999)
	if is_instance_valid(_takeoff_readout):
		if speed < 55.0:
			_takeoff_readout.text = "ROTATE TARGET\nNEED %d KT" % ceili(55.0 - speed)
		elif lift_ratio < 1.0:
			_takeoff_readout.text = "ROTATE TARGET\nPITCH UP GENTLY"
		else:
			_takeoff_readout.text = "LIFT ≥ WEIGHT\nCHECK CLIMB"
	if is_instance_valid(_throttle_readout):
		_throttle_readout.text = _throttle_text(flight_controls.throttle)
	if is_instance_valid(_engine_readout):
		_engine_readout.text = "ENGINE  %s" % ("RUNNING" if bool(aircraft.get("engine_running")) else "OFF")
	if is_instance_valid(_rudder_readout):
		_rudder_readout.text = "RUD  %s%d%%" % ["−" if flight_controls.yaw < 0.0 else "+", int(absf(flight_controls.yaw) * 100.0)]

func _input(event: InputEvent) -> void:
	# Drag in the open central view to orbit the chase camera. HUD controls consume
	# their own events; the central safe area avoids accidental camera movement.
	if cockpit_view:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_camera_drag_active = _is_camera_drag_zone(event.position)
			_camera_drag_last = event.position
		elif _camera_drag_active:
			_camera_drag_active = false
	elif event is InputEventScreenDrag and _camera_drag_active:
		_rotate_chase_camera(event.position - _camera_drag_last)
		_camera_drag_last = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_camera_drag_active = _is_camera_drag_zone(event.position)
			_camera_drag_last = event.position
		else:
			_camera_drag_active = false
	elif event is InputEventMouseMotion and _camera_drag_active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_rotate_chase_camera(event.relative)

func _is_camera_drag_zone(pos: Vector2) -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return pos.x > viewport_size.x * 0.20 and pos.x < viewport_size.x * 0.80 and pos.y > viewport_size.y * 0.16 and pos.y < viewport_size.y * 0.78

func _rotate_chase_camera(delta: Vector2) -> void:
	_camera_yaw_deg = clampf(_camera_yaw_deg - delta.x * 0.22, -150.0, 150.0)
	_camera_pitch_deg = clampf(_camera_pitch_deg - delta.y * 0.18, -55.0, 8.0)
	if is_instance_valid(camera_pivot):
		camera_pivot.rotation_degrees.y = _camera_yaw_deg
	if is_instance_valid(chase_camera):
		chase_camera.rotation_degrees.x = _camera_pitch_deg

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "FlightHUD"
	_hud_layer.layer = 10
	add_child(_hud_layer)
	var green := Color("#52ff73")
	var muted_green := Color("#2da94e")
	var glass := Color(0.015, 0.035, 0.025, 0.64)

	# Upper-left flight strip: compact, aviation-style green symbology.
	var top_panel := _hud_panel(_hud_layer, Vector2(18, 16), Vector2(330, 94), glass, muted_green)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 3)
	top_panel.add_child(top_box)
	airport_title = Label.new()
	airport_title.text = "AERONEXIS  /  %s" % airport_code
	airport_title.add_theme_font_size_override("font_size", 17)
	airport_title.add_theme_color_override("font_color", green)
	top_box.add_child(airport_title)
	telemetry_label = Label.new()
	telemetry_label.text = "%s  →  %s   |   %s %d%%   |   %s" % [airport_code, arrival_code, "REV" if flight_controls.throttle < -0.005 else "THR", roundi(absf(flight_controls.throttle) * 100.0), "ENGINE ON" if bool(aircraft.get("engine_running")) else "ENGINE OFF"]
	telemetry_label.add_theme_font_size_override("font_size", 13)
	telemetry_label.add_theme_color_override("font_color", Color("#d7f6d9"))
	top_box.add_child(telemetry_label)
	var spawn_label := Label.new()
	spawn_label.text = "SPAWN  %s  •  ENGINE OFF — START MANUALLY  •  DRAG CENTER VIEW TO LOOK" % spawn_location.to_upper()
	spawn_label.add_theme_font_size_override("font_size", 11)
	spawn_label.add_theme_color_override("font_color", green)
	top_box.add_child(spawn_label)

	# Bottom telemetry tiles, aligned like a flight-deck readout.
	var bottom := PanelContainer.new()
	bottom.anchor_left = 0.5
	bottom.anchor_right = 0.5
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = -360
	bottom.offset_right = 360
	bottom.offset_top = -88
	bottom.offset_bottom = -12
	bottom.add_theme_stylebox_override("panel", _hud_style(glass, muted_green))
	_hud_layer.add_child(bottom)
	var telemetry_row := HBoxContainer.new()
	telemetry_row.add_theme_constant_override("separation", 16)
	bottom.add_child(telemetry_row)
	_speed_readout = _telemetry_tile(telemetry_row, "000 kt\nIAS", green)
	_altitude_readout = _telemetry_tile(telemetry_row, "0000 ft\nALT MSL", green)
	_lift_readout = _telemetry_tile(telemetry_row, "LIFT 0%\nOF WEIGHT", green)
	_takeoff_readout = _telemetry_tile(telemetry_row, "ROTATE TARGET\nNEED 55 KT", green)
	_telemetry_tile(telemetry_row, "SPAWN\n%s" % spawn_location.to_upper(), green)

	# Left-side vertical throttle control.
	var throttle_panel := _hud_panel(_hud_layer, Vector2(18, 142), Vector2(96, 330), glass, muted_green)
	var throttle_box := VBoxContainer.new()
	throttle_box.add_theme_constant_override("separation", 4)
	throttle_panel.add_child(throttle_box)
	var throttle_header := Label.new()
	throttle_header.text = "THROTTLE"
	throttle_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	throttle_header.add_theme_font_size_override("font_size", 12)
	throttle_header.add_theme_color_override("font_color", green)
	throttle_box.add_child(throttle_header)
	_throttle_readout = Label.new()
	_throttle_readout.text = "THR\n0%"
	_throttle_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_throttle_readout.add_theme_color_override("font_color", green)
	throttle_box.add_child(_throttle_readout)
	throttle_slider = VSlider.new()
	throttle_slider.name = "ThrottleSlider"
	throttle_slider.min_value = -100.0
	throttle_slider.max_value = 100.0
	throttle_slider.step = 1.0
	throttle_slider.value = flight_controls.throttle * 100.0
	throttle_slider.custom_minimum_size = Vector2(72, 250)
	throttle_slider.focus_mode = Control.FOCUS_ALL
	throttle_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	throttle_slider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	throttle_slider.value_changed.connect(_set_throttle)
	throttle_box.add_child(throttle_slider)

	# Right-side camera, brake and exit controls.
	var right_stack := VBoxContainer.new()
	right_stack.anchor_left = 1.0
	right_stack.anchor_right = 1.0
	right_stack.anchor_top = 0.0
	right_stack.anchor_bottom = 0.0
	right_stack.offset_left = -176
	right_stack.offset_right = -16
	right_stack.offset_top = 16
	right_stack.offset_bottom = 250
	right_stack.add_theme_constant_override("separation", 8)
	_hud_layer.add_child(right_stack)
	camera_mode_button = _hud_button("CAM: CHASE")
	camera_mode_button.pressed.connect(_toggle_camera)
	right_stack.add_child(camera_mode_button)
	var engine_button := _hud_button("ENGINE: OFF")
	engine_button.toggle_mode = true
	engine_button.button_pressed = false
	engine_button.toggled.connect(func(on: bool):
		aircraft.set("engine_running", on)
		engine_button.text = "ENGINE: RUNNING" if on else "ENGINE: OFF"
	)
	right_stack.add_child(engine_button)
	_engine_readout = Label.new()
	_engine_readout.text = "ENGINE  OFF"
	_engine_readout.add_theme_color_override("font_color", Color("#52ff73"))
	_engine_readout.add_theme_font_size_override("font_size", 12)
	right_stack.add_child(_engine_readout)
	var brake_button := _hud_button("PARK BRAKE: ON" if flight_controls.brakes > 0.5 else "PARK BRAKE: OFF")
	brake_button.toggle_mode = true
	brake_button.button_pressed = flight_controls.brakes > 0.5
	brake_button.toggled.connect(func(on: bool):
		flight_controls.brakes = 1.0 if on else 0.0
		brake_button.text = "PARK BRAKE: ON" if on else "PARK BRAKE: OFF"
	)
	right_stack.add_child(brake_button)
	var reset_camera := _hud_button("RESET VIEW")
	reset_camera.pressed.connect(_reset_camera)
	right_stack.add_child(reset_camera)
	var exit_button := _hud_button("EXIT FLIGHT")
	exit_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/airport_selection.tscn"))
	right_stack.add_child(exit_button)

	# Bottom-right rudder: horizontal slider springs back to neutral when released.
	var rudder_panel := _hud_panel(_hud_layer, Vector2(0, 0), Vector2(330, 94), glass, muted_green)
	rudder_panel.anchor_left = 1.0
	rudder_panel.anchor_right = 1.0
	rudder_panel.anchor_top = 1.0
	rudder_panel.anchor_bottom = 1.0
	rudder_panel.offset_left = -350
	rudder_panel.offset_right = -18
	rudder_panel.offset_top = -190
	rudder_panel.offset_bottom = -92
	var rudder_box := VBoxContainer.new()
	rudder_box.add_theme_constant_override("separation", 2)
	rudder_panel.add_child(rudder_box)
	var rudder_header := Label.new()
	rudder_header.text = "RUDDER  ◀ LEFT      CENTER      RIGHT ▶"
	rudder_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rudder_header.add_theme_font_size_override("font_size", 11)
	rudder_header.add_theme_color_override("font_color", green)
	rudder_box.add_child(rudder_header)
	rudder_slider = HSlider.new()
	rudder_slider.name = "RudderSlider"
	rudder_slider.min_value = -1.0
	rudder_slider.max_value = 1.0
	rudder_slider.step = 0.01
	rudder_slider.value = 0.0
	rudder_slider.custom_minimum_size = Vector2(280, 38)
	rudder_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rudder_slider.value_changed.connect(_set_rudder)
	rudder_slider.drag_ended.connect(_on_rudder_drag_ended)
	rudder_box.add_child(rudder_slider)
	_rudder_readout = Label.new()
	_rudder_readout.text = "RUD  +0%"
	_rudder_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rudder_readout.add_theme_font_size_override("font_size", 11)
	_rudder_readout.add_theme_color_override("font_color", green)
	rudder_box.add_child(_rudder_readout)

func _hud_panel(parent: Node, pos: Vector2, min_size: Vector2, bg: Color, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", _hud_style(bg, border_color))
	parent.add_child(panel)
	return panel

func _hud_style(bg: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _hud_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(150, 44)
	button.add_theme_color_override("font_color", Color("#baffc2"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _hud_style(Color(0.015, 0.035, 0.025, 0.78), Color("#2da94e")))
	button.add_theme_stylebox_override("hover", _hud_style(Color(0.02, 0.12, 0.05, 0.92), Color("#52ff73")))
	return button

func _telemetry_tile(parent: HBoxContainer, text_value: String, tint: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label

func _set_throttle(value: float) -> void:
	# Slider range is -100..100: negative values request reverse, positive values forward.
	# Convert explicitly to float and update the readout immediately.
	if flight_controls == null:
		return
	flight_controls.throttle = clampf(float(value) * 0.01, -1.0, 1.0)
	if is_instance_valid(_throttle_readout):
		_throttle_readout.text = _throttle_text(flight_controls.throttle)

func _throttle_text(value: float) -> String:
	var percent := roundi(absf(value) * 100.0)
	if value < -0.005:
		return "REV\n%d%%" % percent
	return "THR\n%d%%" % percent

func _set_rudder(value: float) -> void:
	flight_controls.yaw = clampf(value, -1.0, 1.0)

func _on_rudder_drag_ended(_changed: bool) -> void:
	var tween := create_tween()
	tween.tween_property(rudder_slider, "value", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _reset_camera() -> void:
	_camera_yaw_deg = 0.0
	_camera_pitch_deg = -17.0
	if is_instance_valid(camera_pivot):
		camera_pivot.rotation_degrees.y = 0.0
	if is_instance_valid(chase_camera):
		chase_camera.rotation_degrees.x = _camera_pitch_deg

func _add_hold_button(parent: HBoxContainer, caption: String, down: Callable, up: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(62, 42)
	button.button_down.connect(down)
	button.button_up.connect(up)
	parent.add_child(button)

func _add_box(node_name: String, local_position: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var body := StaticBody3D.new() if collision else Node3D.new()
	body.name = node_name
	body.position = local_position
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	add_child(body)

func _add_mesh_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = local_position
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.08
	material.roughness = 0.55
	instance.material_override = material
	parent.add_child(instance)

func _add_mesh_cylinder(parent: Node3D, node_name: String, local_position: Vector3, radius: float, height: float, color: Color, rotate_wheel: bool) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = local_position
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	instance.mesh = mesh
	if rotate_wheel:
		instance.rotation_degrees.z = 90
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	parent.add_child(instance)

func _add_light_pole(local_position: Vector3) -> void:
	_add_box("ApronLightPole", local_position + Vector3(0, 4, 0), Vector3(0.22, 8, 0.22), Color("#77838b"), true)
	_add_box("ApronLightHead", local_position + Vector3(0, 8, 0), Vector3(1.1, 0.3, 0.65), Color("#dcebf2"), false)

func _add_label_3d(node_name: String, text_value: String, local_position: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text_value
	label.position = local_position
	label.font_size = 32
	label.pixel_size = 0.012
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
