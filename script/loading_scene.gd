extends Control

const CURRENT_VERSION := "0.1.0"
const VERSION_URL := "https://raw.githubusercontent.com/AeroNexis-Labs/AeroNexis-Flight-Simulator/main/version.json"
const RELEASE_URL := "https://github.com/AeroNexis-Labs/AeroNexis-Flight-Simulator/releases"
const NEXT_SCENE := "res://scene/dashboard.tscn"
const MINIMUM_DISPLAY_SECONDS := 1.0

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var status_label: Label = $StatusLabel
@onready var retry_button: Button = $RetryButton
@onready var http: HTTPRequest = $HTTPRequest

enum StartupState { VERSION, LOADING, FAILED, UPDATE_REQUIRED, UPDATE_OPTIONAL }
var state: StartupState = StartupState.VERSION
var elapsed := 0.0
var loaded_scene: PackedScene
var pending_release_url := RELEASE_URL
var load_started := false


func _ready() -> void:
    progress_bar.min_value = 0.0
    progress_bar.max_value = 100.0
    progress_bar.value = 0.0
    retry_button.hide()
    retry_button.text = "Retry"
    retry_button.pressed.connect(_on_retry_pressed)
    http.timeout = 5.0
    http.request_completed.connect(_on_request_completed)
    _check_version()


func _process(delta: float) -> void:
    if state != StartupState.LOADING:
        return

    elapsed += delta
    var progress: Array = []
    var load_status := ResourceLoader.load_threaded_get_status(NEXT_SCENE, progress)

    if not progress.is_empty():
        progress_bar.value = clampf(float(progress[0]) * 100.0, 0.0, 100.0)

    match load_status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            status_label.text = "Loading AeroNexis... %d%%" % int(progress_bar.value)
        ResourceLoader.THREAD_LOAD_LOADED:
            if loaded_scene == null:
                loaded_scene = ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
                if loaded_scene == null:
                    _fallback_load_dashboard("Threaded load returned no scene.")
                    return
                progress_bar.value = 100.0
                status_label.text = "Ready for departure"
            if elapsed >= MINIMUM_DISPLAY_SECONDS:
                _open_dashboard()
        ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            _fallback_load_dashboard("Threaded loading failed.")


func _check_version() -> void:
    # The only automatic startup network request is the version/update check.
    # If it fails or the device is offline, continue with the installed build.
    state = StartupState.VERSION
    load_started = false
    loaded_scene = null
    elapsed = 0.0
    progress_bar.value = 0.0
    retry_button.hide()
    status_label.text = "Checking for version updates (optional)..."
    var error := http.request(VERSION_URL)
    if error != OK:
        _start_dashboard_load("Offline. Starting installed version...")


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if state != StartupState.VERSION:
        return

    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        _start_dashboard_load("Update check unavailable. Starting installed version...")
        return

    var data: Variant = JSON.parse_string(body.get_string_from_utf8())
    if not data is Dictionary:
        _start_dashboard_load("Version information unavailable. Starting installed version...")
        return

    var latest := str(data.get("latest_version", ""))
    var minimum := str(data.get("minimum_version", ""))
    var mandatory := bool(data.get("mandatory_update", false))
    pending_release_url = str(data.get("release_url", RELEASE_URL))

    if not _valid_version(latest) or not _valid_version(minimum):
        _start_dashboard_load("Version information invalid. Starting installed version...")
    elif _version_less(CURRENT_VERSION, minimum):
        _show_update_required("This version is no longer supported. Please update to continue.")
    elif _version_less(CURRENT_VERSION, latest) and mandatory:
        _show_update_required("A mandatory update is available. Please update to continue.")
    elif _version_less(CURRENT_VERSION, latest):
        state = StartupState.UPDATE_OPTIONAL
        status_label.text = "Version %s is available. You are using %s." % [latest, CURRENT_VERSION]
        retry_button.text = "Continue"
        retry_button.show()
    else:
        _start_dashboard_load("Version verified. Starting AeroNexis...")


func _start_dashboard_load(message: String) -> void:
    if load_started:
        return

    load_started = true
    state = StartupState.LOADING
    elapsed = 0.0
    loaded_scene = null
    progress_bar.value = 0.0
    status_label.text = message
    retry_button.hide()

    if not ResourceLoader.exists(NEXT_SCENE):
        _show_error("Dashboard scene is missing: " + NEXT_SCENE)
        return

    var error := ResourceLoader.load_threaded_request(NEXT_SCENE, "PackedScene")
    if error != OK:
        _fallback_load_dashboard("Could not start threaded loading (error %d)." % error)


func _fallback_load_dashboard(reason: String) -> void:
    # Recover from a threaded-load failure by trying a normal PackedScene load.
    # This is especially useful for small scenes where threaded loading is unnecessary.
    if not ResourceLoader.exists(NEXT_SCENE):
        _show_error("Dashboard scene is missing: " + NEXT_SCENE)
        return

    status_label.text = "Retrying dashboard load..."
    var resource := ResourceLoader.load(NEXT_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
    loaded_scene = resource as PackedScene

    if loaded_scene == null:
        push_error("Dashboard load failed. " + reason + " Path: " + NEXT_SCENE)
        _show_error("Dashboard could not be loaded. Check the Godot Output panel.")
        return

    progress_bar.value = 100.0
    status_label.text = "Dashboard ready. Opening..."
    state = StartupState.LOADING
    elapsed = maxf(elapsed, MINIMUM_DISPLAY_SECONDS)
    _open_dashboard()


func _open_dashboard() -> void:
    if loaded_scene == null:
        _fallback_load_dashboard("No PackedScene was available to open.")
        return

    var error := get_tree().change_scene_to_packed(loaded_scene)
    if error != OK:
        push_error("change_scene_to_packed failed with error %d for %s" % [error, NEXT_SCENE])
        _show_error("Could not open the dashboard (error %d). Please retry." % error)


func _show_error(message: String) -> void:
    state = StartupState.FAILED
    status_label.text = message
    retry_button.text = "Retry"
    retry_button.show()


func _show_update_required(message: String) -> void:
    state = StartupState.UPDATE_REQUIRED
    status_label.text = message
    retry_button.text = "Open Update Page"
    retry_button.show()


func _on_retry_pressed() -> void:
    if state == StartupState.UPDATE_REQUIRED:
        if pending_release_url.begins_with("https://"):
            OS.shell_open(pending_release_url)
    elif state == StartupState.UPDATE_OPTIONAL:
        _start_dashboard_load("Starting AeroNexis...")
    else:
        _check_version()


func _valid_version(version: String) -> bool:
    var parts := version.split(".")
    if parts.size() != 3:
        return false
    for part in parts:
        if not part.is_valid_int() or int(part) < 0:
            return false
    return true


func _version_less(a: String, b: String) -> bool:
    var av := a.split(".")
    var bv := b.split(".")
    for i in range(3):
        if int(av[i]) < int(bv[i]):
            return true
        if int(av[i]) > int(bv[i]):
            return false
    return false
