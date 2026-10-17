extends Control

@onready var pilot_name: Label = $IdentityPanel/PilotName
@onready var pilot_id: Label = $IdentityPanel/PilotId
@onready var rank_emblem: Label = $IdentityPanel/RankBadge/RankEmblem
@onready var rank_name: Label = $IdentityPanel/RankBadge/RankName
@onready var xp_label: Label = $IdentityPanel/XPLabel
@onready var progress: ProgressBar = $IdentityPanel/Progress
@onready var next_rank: Label = $IdentityPanel/NextRank
@onready var flights: Label = $StatsPanel/Flights
@onready var hours: Label = $StatsPanel/Hours
@onready var distance: Label = $StatsPanel/Distance

const RANKS := [
	{"name":"Cadet V", "fp":0, "emblem":"◇", "color":Color(0.72,0.82,0.94)},
	{"name":"Cadet IV", "fp":100, "emblem":"◇◇", "color":Color(0.72,0.82,0.94)},
	{"name":"Cadet III", "fp":200, "emblem":"◇◇◇", "color":Color(0.72,0.82,0.94)},
	{"name":"Cadet II", "fp":300, "emblem":"◇◇◇◇", "color":Color(0.72,0.82,0.94)},
	{"name":"Cadet I", "fp":400, "emblem":"◇✦", "color":Color(0.72,0.82,0.94)},
	{"name":"First Officer V", "fp":500, "emblem":"✦", "color":Color(0.68,0.86,1)},
	{"name":"First Officer IV", "fp":800, "emblem":"✦✦", "color":Color(0.68,0.86,1)},
	{"name":"First Officer III", "fp":1100, "emblem":"✦✦✦", "color":Color(0.68,0.86,1)},
	{"name":"First Officer II", "fp":1400, "emblem":"✦✦✦✦", "color":Color(0.68,0.86,1)},
	{"name":"First Officer I", "fp":1700, "emblem":"✦✦✦✦✦", "color":Color(0.68,0.86,1)},
	{"name":"Captain V", "fp":2000, "emblem":"✦✦", "color":Color(1,0.82,0.38)},
	{"name":"Captain IV", "fp":2600, "emblem":"✦✦", "color":Color(1,0.82,0.38)},
	{"name":"Captain III", "fp":3200, "emblem":"✦✦✦", "color":Color(1,0.82,0.38)},
	{"name":"Captain II", "fp":3800, "emblem":"✦✦✦✦", "color":Color(1,0.82,0.38)},
	{"name":"Captain I", "fp":4400, "emblem":"✦✦✦✦✦", "color":Color(1,0.82,0.38)},
	{"name":"Commander V", "fp":5000, "emblem":"✦✦✦", "color":Color(0.8,0.9,1)},
	{"name":"Commander IV", "fp":6000, "emblem":"✦✦✦", "color":Color(0.8,0.9,1)},
	{"name":"Commander III", "fp":7000, "emblem":"✦✦✦✦", "color":Color(0.8,0.9,1)},
	{"name":"Commander II", "fp":8000, "emblem":"✦✦✦✦✦", "color":Color(0.8,0.9,1)},
	{"name":"Commander I", "fp":9000, "emblem":"✦✦✦✦✦✦", "color":Color(0.8,0.9,1)},
	{"name":"Ace", "fp":10000, "emblem":"★", "color":Color(1,0.72,0.28)}
]

func _ready() -> void:
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/loading_scene.tscn"))
	if not PlayerData.profile_changed.is_connected(_apply_profile):
		PlayerData.profile_changed.connect(_apply_profile)
	_apply_profile(PlayerData.get_dashboard_data())

func _apply_profile(data: Dictionary) -> void:
	var fp := int(data.get("fp", data.get("xp", 0)))
	var current_index := 0
	for i in range(RANKS.size()):
		if fp >= int(RANKS[i]["fp"]): current_index = i
	var current: Dictionary = RANKS[current_index]
	var next: Dictionary = RANKS[mini(current_index + 1, RANKS.size() - 1)]
	pilot_name.text = str(data.get("display_name", "Guest Pilot"))
	var id := str(data.get("player_id", ""))
	pilot_id.text = ("PILOT ID  /  " + id.left(20).to_upper()) if not id.is_empty() else "LOCAL GUEST PROFILE"
	rank_emblem.text = str(current["emblem"])
	rank_emblem.add_theme_color_override("font_color", current["color"])
	rank_name.text = str(current["name"]).to_upper()
	xp_label.text = "%s FP  /  %s FP NEXT LEVEL" % [String.num_int64(fp, 10), String.num_int64(int(next["fp"]), 10)] if current_index < RANKS.size()-1 else "%s FP  /  MAX RANK" % String.num_int64(fp, 10)
	var base_fp := int(current["fp"])
	var target_fp := int(next["fp"])
	progress.max_value = max(1, target_fp - base_fp)
	progress.value = clampi(fp - base_fp, 0, int(progress.max_value))
	next_rank.text = ("%s FP TO %s" % [String.num_int64(maxi(0, target_fp-fp), 10), str(next["name"]).to_upper()]) if current_index < RANKS.size()-1 else "TOP RANK ACHIEVED"
	flights.text = "TOTAL FLIGHTS     " + String.num_int64(int(data.get("total_flights", 0)), 10)
	var seconds := int(data.get("total_flight_seconds", 0))
	hours.text = "FLIGHT TIME       %dh %02dm" % [floori(float(seconds) / 3600.0), floori(float(seconds % 3600) / 60.0)]
	distance.text = "DISTANCE          %s km" % ("%.0f" % float(data.get("distance_km", 0.0)))
