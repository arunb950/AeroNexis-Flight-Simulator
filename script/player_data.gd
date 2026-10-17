extends Node

## Local-first player persistence for AeroNexis.
## Requires the Godot-SQLite GDExtension (SQLite class) installed in addons/godot-sqlite.

signal profile_changed(profile: Dictionary)
signal database_status_changed(is_ready: bool, message: String)

const DATABASE_PATH := "user://aeronexis_player.db"
const SCHEMA_VERSION := 1
const DEFAULT_GUEST_NAME := "Guest Pilot"

var _db: Object = null
var _database_ready := false
var _profile_cache: Dictionary = {}

func _ready() -> void:
	_load_active_player_id()
	_open_database()

func _open_database() -> void:
	if not ClassDB.class_exists("SQLite"):
		var message := "SQLite extension missing. Install the Godot-SQLite addon before exporting."
		push_warning("PlayerData: " + message)
		database_status_changed.emit(false, message)
		_profile_cache = _empty_profile()
		return

	_db = ClassDB.instantiate("SQLite")
	_db.path = DATABASE_PATH
	_db.foreign_keys = true
	_db.read_only = false
	if not _db.open_db():
		var message := "Could not open local player database: %s" % str(_db.error_message)
		push_error("PlayerData: " + message)
		database_status_changed.emit(false, message)
		_profile_cache = _empty_profile()
		return

	if not _run_schema_migrations():
		var message := "Could not initialize player database schema."
		push_error("PlayerData: " + message)
		database_status_changed.emit(false, message)
		_profile_cache = _empty_profile()
		return

	_database_ready = true
	_ensure_guest_profile()
	_profile_cache = get_dashboard_data()
	database_status_changed.emit(true, "Local SQLite database ready")
	profile_changed.emit(_profile_cache)

func _run_schema_migrations() -> bool:
	var statements := [
		"CREATE TABLE IF NOT EXISTS schema_migrations (version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);",
		"CREATE TABLE IF NOT EXISTS player_profile (player_id TEXT PRIMARY KEY, display_name TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, is_guest INTEGER NOT NULL DEFAULT 1, xp INTEGER NOT NULL DEFAULT 0, rank_name TEXT NOT NULL DEFAULT 'Cadet V', total_flights INTEGER NOT NULL DEFAULT 0, total_flight_seconds INTEGER NOT NULL DEFAULT 0, distance_km REAL NOT NULL DEFAULT 0, successful_landings INTEGER NOT NULL DEFAULT 0, total_landings INTEGER NOT NULL DEFAULT 0);",
		"CREATE TABLE IF NOT EXISTS flight_records (flight_id INTEGER PRIMARY KEY AUTOINCREMENT, player_id TEXT NOT NULL, aircraft_id TEXT NOT NULL DEFAULT '', departure_airport TEXT NOT NULL DEFAULT '', arrival_airport TEXT NOT NULL DEFAULT '', duration_seconds INTEGER NOT NULL DEFAULT 0, distance_km REAL NOT NULL DEFAULT 0, landing_success INTEGER NOT NULL DEFAULT 0, xp_awarded INTEGER NOT NULL DEFAULT 0, haul_category TEXT NOT NULL DEFAULT 'short', completed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY(player_id) REFERENCES player_profile(player_id) ON DELETE CASCADE);",
		"CREATE INDEX IF NOT EXISTS idx_flight_records_player_completed ON flight_records(player_id, completed_at);",
		"CREATE TABLE IF NOT EXISTS player_settings (player_id TEXT PRIMARY KEY, graphics_quality TEXT NOT NULL DEFAULT 'balanced', music_volume REAL NOT NULL DEFAULT 0.8, sfx_volume REAL NOT NULL DEFAULT 0.8, control_scheme TEXT NOT NULL DEFAULT 'touch', distance_unit TEXT NOT NULL DEFAULT 'km', FOREIGN KEY(player_id) REFERENCES player_profile(player_id) ON DELETE CASCADE);",
		"INSERT OR IGNORE INTO schema_migrations(version) VALUES (1);"
	]
	for statement in statements:
		if not _db.query(statement):
			push_error("PlayerData SQLite error: " + str(_db.error_message))
			return false
	return true

func _ensure_guest_profile() -> void:
	var current_id := _read_active_player_id()
	if not current_id.is_empty():
		var rows := _query_rows("SELECT player_id FROM player_profile WHERE player_id = ? LIMIT 1;", [current_id])
		if not rows.is_empty():
			return

	var new_id := "guest-" + _new_uuid()
	if not _db.query_with_bindings(
		"INSERT INTO player_profile(player_id, display_name, is_guest) VALUES (?, ?, 1);",
		[new_id, DEFAULT_GUEST_NAME]
	):
		push_error("PlayerData could not create guest profile: " + str(_db.error_message))
		return
	_db.query_with_bindings(
		"INSERT OR IGNORE INTO player_settings(player_id) VALUES (?);", [new_id]
	)
	_write_active_player_id(new_id)

func get_dashboard_data() -> Dictionary:
	if not _database_ready:
		return _empty_profile()
	var player_id := _read_active_player_id()
	var rows := _query_rows(
		"SELECT player_id, display_name, is_guest, xp, rank_name, total_flights, total_flight_seconds, distance_km, successful_landings, total_landings FROM player_profile WHERE player_id = ? LIMIT 1;",
		[player_id]
	)
	if rows.is_empty():
		return _empty_profile()
	var row: Dictionary = rows[0]
	var total_landings := int(row.get("total_landings", 0))
	var successful_landings := int(row.get("successful_landings", 0))
	var landing_rate := 0
	if total_landings > 0:
		landing_rate = roundi(float(successful_landings) / float(total_landings) * 100.0)
	return {
		"player_id": str(row.get("player_id", "")),
		"display_name": str(row.get("display_name", DEFAULT_GUEST_NAME)),
		"is_guest": int(row.get("is_guest", 1)) == 1,
		"fp": int(row.get("xp", 0)),
		"xp": int(row.get("xp", 0)),
		"rank_name": str(row.get("rank_name", "Cadet")),
		"total_flights": int(row.get("total_flights", 0)),
		"total_flight_seconds": int(row.get("total_flight_seconds", 0)),
		"distance_km": float(row.get("distance_km", 0.0)),
		"landing_success_rate": landing_rate
	}

func update_display_name(new_name: String) -> bool:
	if not _database_ready:
		return false
	var safe_name := new_name.strip_edges()
	if safe_name.is_empty():
		return false
	var ok: bool = _db.query_with_bindings(
		"UPDATE player_profile SET display_name = ? WHERE player_id = ?;",
		[safe_name.left(32), _read_active_player_id()]
	)
	if ok:
		_refresh_profile()
	return ok

## Flight Points (FP) and rank rules. Values are AeroNexis-balanced, not official RFS thresholds.
const RANK_THRESHOLDS := [
	{"name":"Cadet V", "fp":0}, {"name":"Cadet IV", "fp":100}, {"name":"Cadet III", "fp":200}, {"name":"Cadet II", "fp":300}, {"name":"Cadet I", "fp":400},
	{"name":"First Officer V", "fp":500}, {"name":"First Officer IV", "fp":800}, {"name":"First Officer III", "fp":1100}, {"name":"First Officer II", "fp":1400}, {"name":"First Officer I", "fp":1700},
	{"name":"Captain V", "fp":2000}, {"name":"Captain IV", "fp":2600}, {"name":"Captain III", "fp":3200}, {"name":"Captain II", "fp":3800}, {"name":"Captain I", "fp":4400},
	{"name":"Commander V", "fp":5000}, {"name":"Commander IV", "fp":6000}, {"name":"Commander III", "fp":7000}, {"name":"Commander II", "fp":8000}, {"name":"Commander I", "fp":9000},
	{"name":"Ace", "fp":10000}
]

func add_flight_points(amount: int) -> bool:
	if not _database_ready or amount <= 0:
		return false
	var player_id := _read_active_player_id()
	var rows := _query_rows("SELECT xp FROM player_profile WHERE player_id = ? LIMIT 1;", [player_id])
	if rows.is_empty():
		return false
	var new_fp := int(rows[0].get("xp", 0)) + amount
	var ok: bool = _db.query_with_bindings(
		"UPDATE player_profile SET xp = ?, rank_name = ? WHERE player_id = ?;",
		[new_fp, get_rank_label(new_fp), player_id]
	)
	if ok:
		_refresh_profile()
	return ok

## Compatibility alias for older callers; the stored value now represents FP.
func add_xp(amount: int) -> bool:
	return add_flight_points(amount)

func get_rank_label(fp: int) -> String:
	var result := "Cadet V"
	for rank in RANK_THRESHOLDS:
		if fp >= int(rank["fp"]):
			result = str(rank["name"])
	return result

func get_flight_points(distance_km: float) -> int:
	if distance_km < 0.0:
		return 0
	if distance_km < 1500.0:
		return 50
	if distance_km <= 4000.0:
		return 100
	return 200

## Call only once after a flight with takeoff and landing has been completed.
## The current result API treats this call as the completion event; it does not itself validate telemetry.
func record_completed_flight(aircraft_id: String, departure: String, arrival: String, duration_seconds: int, distance_km: float, landing_success: bool) -> bool:
	if not _database_ready or departure.strip_edges().is_empty() or arrival.strip_edges().is_empty() or duration_seconds <= 0 or distance_km < 0.0:
		return false
	var player_id := _read_active_player_id()
	var safe_distance := maxf(0.0, distance_km)
	var landing_value := 1 if landing_success else 0
	var award := get_flight_points(safe_distance)
	var haul := "short" if safe_distance < 1500.0 else ("medium" if safe_distance <= 4000.0 else "long")
	if not _db.query_with_bindings(
		"INSERT INTO flight_records(player_id, aircraft_id, departure_airport, arrival_airport, duration_seconds, distance_km, landing_success, xp_awarded, haul_category) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);",
		[player_id, aircraft_id, departure, arrival, maxi(0, duration_seconds), safe_distance, landing_value, award, haul]
	):
		push_error("PlayerData could not record flight: " + str(_db.error_message))
		return false
	var rows := _query_rows("SELECT xp FROM player_profile WHERE player_id = ? LIMIT 1;", [player_id])
	if rows.is_empty():
		return false
	var new_fp := int(rows[0].get("xp", 0)) + award
	var update_ok: bool = _db.query_with_bindings(
		"UPDATE player_profile SET total_flights = total_flights + 1, total_flight_seconds = total_flight_seconds + ?, distance_km = distance_km + ?, total_landings = total_landings + 1, successful_landings = successful_landings + ?, xp = ?, rank_name = ? WHERE player_id = ?;",
		[maxi(0, duration_seconds), safe_distance, landing_value, new_fp, get_rank_label(new_fp), player_id]
	)
	if update_ok:
		_refresh_profile()
	return update_ok

func get_database_status() -> Dictionary:
	return {"ready": _database_ready, "path": DATABASE_PATH, "message": "SQLite ready" if _database_ready else "SQLite extension unavailable"}

func _refresh_profile() -> void:
	_profile_cache = get_dashboard_data()
	profile_changed.emit(_profile_cache)

func _query_rows(sql: String, bindings: Array = []) -> Array:
	if not _database_ready and _db == null:
		return []
	var ok: bool
	if bindings.is_empty():
		ok = _db.query(sql)
	else:
		ok = _db.query_with_bindings(sql, bindings)
	if not ok:
		push_error("PlayerData SQLite query failed: " + str(_db.error_message))
		return []
	return _db.query_result.duplicate(true)

func _read_active_player_id() -> String:
	return _active_player_id

var _active_player_id := ""

func _write_active_player_id(player_id: String) -> void:
	_active_player_id = player_id
	# user:// keeps the active local profile scoped to this device installation.
	var config := ConfigFile.new()
	config.set_value("player", "active_player_id", player_id)
	config.save("user://player_state.cfg")

func _new_uuid() -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(16).hex_encode()

func _empty_profile() -> Dictionary:
	return {
		"player_id": "", "display_name": DEFAULT_GUEST_NAME, "is_guest": true,
		"fp": 0, "xp": 0, "rank_name": "Cadet V", "total_flights": 0,
		"total_flight_seconds": 0, "distance_km": 0.0, "landing_success_rate": 0
	}

func _load_active_player_id() -> void:
	var config := ConfigFile.new()
	if config.load("user://player_state.cfg") == OK:
		_active_player_id = str(config.get_value("player", "active_player_id", ""))
