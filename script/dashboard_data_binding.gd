extends Control

## Binds database-backed player data to the existing .tscn labels.
## UI layout remains entirely in scene/dashboard.tscn.

@onready var pilot_name: Label = $PilotPanel/PilotName
@onready var pilot_id: Label = $PilotPanel/PilotId
@onready var pilot_rank: Label = $PilotPanel/PilotRank
@onready var pilot_xp: Label = $PilotPanel/PilotXP
@onready var flights_value: Label = $StatsPanel/StatFlightsValue
@onready var time_value: Label = $StatsPanel/StatTimeValue
@onready var distance_value: Label = $StatsPanel/StatDistanceValue
@onready var landing_value: Label = $StatsPanel/StatLandingValue
@onready var stats_footer: Label = $StatsPanel/StatsFooter

func _ready() -> void:
	var fly_button: Button = get_node_or_null("FlyNowButton") as Button
	var profile_card: Control = get_node_or_null("ProfileCard") as Control
	if profile_card:
		profile_card.mouse_filter = Control.MOUSE_FILTER_STOP
		if not profile_card.gui_input.is_connected(_on_profile_card_input):
			profile_card.gui_input.connect(_on_profile_card_input)
	if fly_button and not fly_button.pressed.is_connected(_on_fly_now_pressed):
		fly_button.pressed.connect(_on_fly_now_pressed)
	if not PlayerData.profile_changed.is_connected(_on_profile_changed):
		PlayerData.profile_changed.connect(_on_profile_changed)
	if not PlayerData.database_status_changed.is_connected(_on_database_status_changed):
		PlayerData.database_status_changed.connect(_on_database_status_changed)
	_apply_profile(PlayerData.get_dashboard_data())
	var status: Dictionary = PlayerData.get_database_status()
	_on_database_status_changed(bool(status.get("ready", false)), str(status.get("message", "")))

func _on_profile_changed(profile: Dictionary) -> void:
	_apply_profile(profile)

func _apply_profile(profile: Dictionary) -> void:
	pilot_name.text = str(profile.get("display_name", "Guest Pilot"))
	var id := str(profile.get("player_id", ""))
	if id.is_empty():
		pilot_id.text = "LOCAL GUEST  /  DATABASE SETUP REQUIRED"
	else:
		pilot_id.text = "PILOT ID  /  " + id.left(13).to_upper()
	pilot_rank.text = _rank_insignia(str(profile.get("rank_name", "Cadet V"))) + "  " + str(profile.get("rank_name", "Cadet V")).to_upper()
	pilot_xp.text = "%s FP" % _format_integer(int(profile.get("fp", profile.get("xp", 0))))
	flights_value.text = _format_integer(int(profile.get("total_flights", 0)))
	time_value.text = _format_duration(int(profile.get("total_flight_seconds", 0)))
	distance_value.text = "%s km" % _format_number(float(profile.get("distance_km", 0.0)))
	landing_value.text = "%d%%" % int(profile.get("landing_success_rate", 0))

func _on_database_status_changed(is_ready: bool, message: String) -> void:
	if is_instance_valid(stats_footer):
		stats_footer.text = "LOCAL DATABASE  /  READY" if is_ready else "DATABASE SETUP REQUIRED"
		stats_footer.tooltip_text = message

func _format_duration(total_seconds: int) -> String:
	var hours: int = floori(float(maxi(0, total_seconds)) / 3600.0)
	var minutes: int = floori(float(maxi(0, total_seconds) % 3600) / 60.0)
	return "%dh %02dm" % [hours, minutes]

func _format_integer(value: int) -> String:
	return String.num_int64(value, 10)

func _format_number(value: float) -> String:
	if value >= 1000.0:
		return "%.0f" % value
	if value >= 100.0:
		return "%.1f" % value
	return "%.2f" % value

func _rank_insignia(rank_name: String) -> String:
	var tier := rank_name.to_lower()
	if tier.begins_with("ace"):
		return "★  ELITE"
	if tier.begins_with("commander"):
		return "✦✦✦  WINGS"
	if tier.begins_with("captain"):
		return "✦✦  WINGS"
	if tier.begins_with("first officer"):
		return "✦  WINGS"
	return "◇  RANK"

func _on_profile_card_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scene/pilot_profile.tscn")

func _on_fly_now_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/aircraft_selection.tscn")
