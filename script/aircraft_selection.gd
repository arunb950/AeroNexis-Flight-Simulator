extends Control

## Interaction logic only; all interface layout is authored in aircraft_selection.tscn.

@onready var cessna_button: Button = $AircraftChoices/CessnaCard/CessnaButton
@onready var king_air_button: Button = $AircraftChoices/KingAirCard/KingAirButton
@onready var airliner_button: Button = $AircraftChoices/AirlinerCard/AirlinerButton
@onready var selected_name: Label = $SelectionSummary/SelectedAircraft
@onready var detail_title: Label = $DetailPanel/SelectedAircraftTitle
@onready var specs_left: Label = $DetailPanel/SpecsLeft
@onready var specs_right: Label = $DetailPanel/SpecsRight
@onready var status_label: Label = $StatusLabel
@onready var continue_button: Button = $ContinueButton

var selected_aircraft: String = "Cessna 172"
var selected_description: String = "A forgiving single-engine trainer — ideal for your first flight."

func _ready() -> void:
	cessna_button.pressed.connect(_select_cessna)
	king_air_button.pressed.connect(_select_king_air)
	airliner_button.pressed.connect(_select_airliner)
	if not continue_button.pressed.is_connected(_continue_to_airport_setup):
		continue_button.pressed.connect(_continue_to_airport_setup)
	$BackButton.pressed.connect(_on_back_pressed)
	# Keep the primary touch target above decorative panels and accept mobile input.
	continue_button.mouse_filter = Control.MOUSE_FILTER_STOP
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.disabled = false
	continue_button.z_index = 20
	continue_button.move_to_front()
	_refresh_selection()

func _select_cessna() -> void:
	selected_aircraft = "Cessna 172"
	selected_description = "A forgiving single-engine trainer — ideal for your first flight."
	_refresh_selection()

func _select_king_air() -> void:
	selected_aircraft = "Beechcraft King Air"
	selected_description = "A versatile twin-turboprop for regional and mountain routes."
	_refresh_selection()

func _select_airliner() -> void:
	selected_aircraft = "Airbus A320"
	selected_description = "A modern commercial jet built for high-altitude, high-speed routes."
	_refresh_selection()

func _refresh_selection() -> void:
	selected_name.text = selected_aircraft.to_upper()
	detail_title.text = selected_aircraft.to_upper()
	if selected_aircraft == "Cessna 172":
		specs_left.text = "CLASS          Trainer\nENGINES        Single piston\nWINGSPAN       11.0 m\nCREW           1–2"
		specs_right.text = "SEATS          4\nCRUISE         122 kt\nRANGE          640 nm\nROLE           General aviation"
	elif selected_aircraft == "Beechcraft King Air":
		specs_left.text = "CLASS          Twin turboprop\nENGINES        2 turboprops\nWINGSPAN       16.6 m\nCREW           1–2"
		specs_right.text = "SEATS          9–11\nCRUISE         270 kt\nRANGE          1,500 nm\nROLE           Regional transport"
	else:
		specs_left.text = "CLASS          Commercial jet\nENGINES        2 turbofans\nWINGSPAN       34.1 m\nCREW           2 pilots"
		specs_right.text = "SEATS          Up to 180\nCRUISE         447 kt\nRANGE          3,300 nm\nROLE           Passenger transport"
	status_label.text = selected_description
	cessna_button.text = "✓  CESSNA 172" if selected_aircraft == "Cessna 172" else "SELECT AIRCRAFT"
	king_air_button.text = "✓  KING AIR" if selected_aircraft == "Beechcraft King Air" else "SELECT AIRCRAFT"
	airliner_button.text = "✓  AIRBUS A320" if selected_aircraft == "Airbus A320" else "SELECT AIRCRAFT"

func _continue_to_airport_setup() -> void:
	# Guard against double taps on mobile and give immediate visible feedback.
	if not is_inside_tree():
		return
	continue_button.disabled = true
	continue_button.text = "OPENING AIRPORTS…"
	status_label.text = "Saving aircraft selection…"

	var selection := {"aircraft": selected_aircraft}
	var file := FileAccess.open("user://selected_aircraft.json", FileAccess.WRITE)
	if file == null:
		push_error("Could not save aircraft selection: %s" % error_string(FileAccess.get_open_error()))
		status_label.text = "Could not save aircraft selection. Please try again."
		continue_button.text = "CONFIRM AIRCRAFT  →"
		continue_button.disabled = false
		return
	file.store_string(JSON.stringify(selection))
	file.close()

	var next_scene := "res://scene/airport_selection.tscn"
	if not ResourceLoader.exists(next_scene):
		push_error("Airport selection scene not found: %s" % next_scene)
		status_label.text = "Airport selection scene is missing."
		continue_button.text = "CONFIRM AIRCRAFT  →"
		continue_button.disabled = false
		return

	var error := get_tree().change_scene_to_file(next_scene)
	if error != OK:
		push_error("Failed to open airport selection scene. Error code: %s" % error)
		status_label.text = "Could not open airport selection. Please try again."
		continue_button.text = "CONFIRM AIRCRAFT  →"
		continue_button.disabled = false

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/dashboard.tscn")
