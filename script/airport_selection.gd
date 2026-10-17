extends Control
## Interactive world airport picker. Fully offline: map tiles are read only from bundled project data.
const AIRPORTS := [
 {"icao":"VNKT","iata":"KTM","name":"Tribhuvan International Airport","city":"Kathmandu, Nepal","lat":27.6966,"lon":85.3591},
 {"icao":"VNLK","iata":"LUA","name":"Tenzing-Hillary Airport","city":"Lukla, Nepal","lat":27.6878,"lon":86.7314},
 {"icao":"VNBW","iata":"BWA","name":"Gautam Buddha International Airport","city":"Bhairahawa, Nepal","lat":27.5057,"lon":83.4163},
 {"icao":"VNBP","iata":"PKR","name":"Pokhara International Airport","city":"Pokhara, Nepal","lat":28.2009,"lon":83.9821},
 {"icao":"KJFK","iata":"JFK","name":"John F. Kennedy International Airport","city":"New York, USA","lat":40.6413,"lon":-73.7781},
 {"icao":"KLAX","iata":"LAX","name":"Los Angeles International Airport","city":"Los Angeles, USA","lat":33.9416,"lon":-118.4085},
 {"icao":"KORD","iata":"ORD","name":"O’Hare International Airport","city":"Chicago, USA","lat":41.9742,"lon":-87.9073},
 {"icao":"KATL","iata":"ATL","name":"Hartsfield–Jackson Atlanta International Airport","city":"Atlanta, USA","lat":33.6407,"lon":-84.4277},
 {"icao":"KSFO","iata":"SFO","name":"San Francisco International Airport","city":"San Francisco, USA","lat":37.6213,"lon":-122.3790},
 {"icao":"CYYZ","iata":"YYZ","name":"Toronto Pearson International Airport","city":"Toronto, Canada","lat":43.6777,"lon":-79.6248},
 {"icao":"CYVR","iata":"YVR","name":"Vancouver International Airport","city":"Vancouver, Canada","lat":49.1967,"lon":-123.1815},
 {"icao":"EGLL","iata":"LHR","name":"Heathrow Airport","city":"London, United Kingdom","lat":51.4700,"lon":-0.4543},
 {"icao":"EGKK","iata":"LGW","name":"Gatwick Airport","city":"London, United Kingdom","lat":51.1537,"lon":-0.1821},
 {"icao":"LFPG","iata":"CDG","name":"Charles de Gaulle Airport","city":"Paris, France","lat":49.0097,"lon":2.5479},
 {"icao":"EDDF","iata":"FRA","name":"Frankfurt Airport","city":"Frankfurt, Germany","lat":50.0379,"lon":8.5622},
 {"icao":"EHAM","iata":"AMS","name":"Amsterdam Airport Schiphol","city":"Amsterdam, Netherlands","lat":52.3105,"lon":4.7683},
 {"icao":"LEMD","iata":"MAD","name":"Adolfo Suárez Madrid–Barajas Airport","city":"Madrid, Spain","lat":40.4983,"lon":-3.5676},
 {"icao":"LIRF","iata":"FCO","name":"Rome Fiumicino Airport","city":"Rome, Italy","lat":41.8003,"lon":12.2389},
 {"icao":"OMDB","iata":"DXB","name":"Dubai International Airport","city":"Dubai, UAE","lat":25.2532,"lon":55.3657},
 {"icao":"OTHH","iata":"DOH","name":"Hamad International Airport","city":"Doha, Qatar","lat":25.2731,"lon":51.6081},
 {"icao":"OERK","iata":"RUH","name":"King Khalid International Airport","city":"Riyadh, Saudi Arabia","lat":24.9576,"lon":46.6988},
 {"icao":"VIDP","iata":"DEL","name":"Indira Gandhi International Airport","city":"New Delhi, India","lat":28.5562,"lon":77.1000},
 {"icao":"VABB","iata":"BOM","name":"Chhatrapati Shivaji Maharaj International Airport","city":"Mumbai, India","lat":19.0896,"lon":72.8656},
 {"icao":"VOBL","iata":"BLR","name":"Kempegowda International Airport","city":"Bengaluru, India","lat":13.1986,"lon":77.7066},
 {"icao":"WSSS","iata":"SIN","name":"Singapore Changi Airport","city":"Singapore","lat":1.3644,"lon":103.9915},
 {"icao":"VTBS","iata":"BKK","name":"Suvarnabhumi Airport","city":"Bangkok, Thailand","lat":13.6900,"lon":100.7501},
 {"icao":"WMKK","iata":"KUL","name":"Kuala Lumpur International Airport","city":"Kuala Lumpur, Malaysia","lat":2.7456,"lon":101.7072},
 {"icao":"RJTT","iata":"HND","name":"Tokyo Haneda Airport","city":"Tokyo, Japan","lat":35.5494,"lon":139.7798},
 {"icao":"RJAA","iata":"NRT","name":"Narita International Airport","city":"Tokyo, Japan","lat":35.7720,"lon":140.3929},
 {"icao":"RKSI","iata":"ICN","name":"Incheon International Airport","city":"Seoul, South Korea","lat":37.4602,"lon":126.4407},
 {"icao":"ZBAA","iata":"PEK","name":"Beijing Capital International Airport","city":"Beijing, China","lat":40.0799,"lon":116.6031},
 {"icao":"ZSPD","iata":"PVG","name":"Shanghai Pudong International Airport","city":"Shanghai, China","lat":31.1443,"lon":121.8083},
 {"icao":"YSSY","iata":"SYD","name":"Sydney Kingsford Smith Airport","city":"Sydney, Australia","lat":-33.9399,"lon":151.1753},
 {"icao":"YMML","iata":"MEL","name":"Melbourne Airport","city":"Melbourne, Australia","lat":-37.6690,"lon":144.8410},
 {"icao":"NZAA","iata":"AKL","name":"Auckland Airport","city":"Auckland, New Zealand","lat":-37.0082,"lon":174.7850},
 {"icao":"FAOR","iata":"JNB","name":"O. R. Tambo International Airport","city":"Johannesburg, South Africa","lat":-26.1367,"lon":28.2411},
 {"icao":"FACT","iata":"CPT","name":"Cape Town International Airport","city":"Cape Town, South Africa","lat":-33.9715,"lon":18.6021},
 {"icao":"HECA","iata":"CAI","name":"Cairo International Airport","city":"Cairo, Egypt","lat":30.1219,"lon":31.4056},
 {"icao":"SBGR","iata":"GRU","name":"São Paulo/Guarulhos International Airport","city":"São Paulo, Brazil","lat":-23.4356,"lon":-46.4731},
 {"icao":"SCEL","iata":"SCL","name":"Arturo Merino Benítez International Airport","city":"Santiago, Chile","lat":-33.3930,"lon":-70.7858},
 {"icao":"SAEZ","iata":"EZE","name":"Ministro Pistarini International Airport","city":"Buenos Aires, Argentina","lat":-34.8222,"lon":-58.5358},
 {"icao":"MMMX","iata":"MEX","name":"Mexico City International Airport","city":"Mexico City, Mexico","lat":19.4363,"lon":-99.0721},
 {"icao":"MDSD","iata":"SDQ","name":"Las Américas International Airport","city":"Santo Domingo, Dominican Republic","lat":18.4297,"lon":-69.6689},
 {"icao":"PANC","iata":"ANC","name":"Ted Stevens Anchorage International Airport","city":"Anchorage, USA","lat":61.1744,"lon":-149.9964},
 {"icao":"UUEE","iata":"SVO","name":"Sheremetyevo International Airport","city":"Moscow, Russia","lat":55.9726,"lon":37.4146},
 {"icao":"UUDD","iata":"DME","name":"Domodedovo Airport","city":"Moscow, Russia","lat":55.4088,"lon":37.9063},
 {"icao":"LTFM","iata":"IST","name":"Istanbul Airport","city":"Istanbul, Türkiye","lat":41.2753,"lon":28.7519},
 {"icao":"ZSSS","iata":"SHA","name":"Shanghai Hongqiao International Airport","city":"Shanghai, China","lat":31.1979,"lon":121.3363},
 {"icao":"VHHH","iata":"HKG","name":"Hong Kong International Airport","city":"Hong Kong","lat":22.3080,"lon":113.9185},
 {"icao":"RCTP","iata":"TPE","name":"Taiwan Taoyuan International Airport","city":"Taipei, Taiwan","lat":25.0797,"lon":121.2342},
 {"icao":"PHNL","iata":"HNL","name":"Daniel K. Inouye International Airport","city":"Honolulu, USA","lat":21.3187,"lon":-157.9225},
 {"icao":"KDEN","iata":"DEN","name":"Denver International Airport","city":"Denver, USA","lat":39.8561,"lon":-104.6737}
]
const TILE_SIZE := 256
const TILE_DATA_DIR := "res://data/map_tiles"
var zoom: int = 2
var center_lat: float = 20.0
var center_lon: float = 10.0
var tile_textures: Dictionary = {}
var map_canvas: Control
var search_edit: LineEdit
var results: VBoxContainer
var selected_label: Label
var status_label: Label
var origin: Dictionary = {}
var destination: Dictionary = {}
var choose_origin := true
var drag_last := Vector2.ZERO
var is_dragging := false
var mouse_press_pos := Vector2.ZERO
var mouse_moved := false
var touch_points: Dictionary = {}
var touch_start_positions: Dictionary = {}
var touch_moved: Dictionary = {}
var pinch_last_distance: float = 0.0
var tile_epoch := 0
var spawn_location := "runway"
var spawn_gate_button: Button
var spawn_runway_button: Button

func _ready() -> void:
	_build_ui()
	map_canvas.resized.connect(_queue_visible_tiles)
	_queue_visible_tiles()
	_update_route_label()

func _build_ui() -> void:
	var bg := ColorRect.new(); bg.color = Color("#061a2a"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var header := _panel(self, Rect2(0,0,1280,64), Color("#082b43"))
	var _brand := _label(header,"AERONEXIS  /  AIRPORT & ROUTE SELECTION",Vector2(24,13),Vector2(520,34),22,Color.WHITE)
	var search_panel := _panel(self,Rect2(840,8,245,46),Color("#12476b"))
	search_edit=LineEdit.new(); search_edit.placeholder_text="Search ICAO / IATA / city"; search_edit.position=Vector2(850,12); search_edit.size=Vector2(225,36); search_edit.add_theme_color_override("font_color",Color.WHITE); search_edit.add_theme_color_override("font_placeholder_color",Color("#a8c7d9")); search_edit.text_submitted.connect(_on_search); search_panel.add_child(search_edit)
	var settings := Button.new(); settings.text="MAP SETTINGS"; settings.position=Vector2(1094,8); settings.size=Vector2(165,46); _style_button(settings); settings.pressed.connect(_show_map_info); add_child(settings)
	map_canvas=Control.new(); map_canvas.position=Vector2(0,64); map_canvas.size=Vector2(1280,566); map_canvas.clip_contents=true; map_canvas.mouse_filter=Control.MOUSE_FILTER_STOP; map_canvas.draw.connect(_draw_map); map_canvas.gui_input.connect(_on_map_input); add_child(map_canvas)
	var side := _panel(self,Rect2(16,82,300,520),Color("#071f31d9")); side.mouse_filter=Control.MOUSE_FILTER_STOP
	_label(side,"AIRPORT SEARCH",Vector2(16,12),Vector2(268,28),18,Color("#49d8ff"))
	_label(side,"Choose departure and arrival airports",Vector2(16,42),Vector2(268,36),12,Color("#c4d8e5"))
	var origin_btn:=Button.new(); origin_btn.text="1  SELECT DEPARTURE"; origin_btn.position=Vector2(14,82); origin_btn.size=Vector2(272,40); _style_button(origin_btn); origin_btn.pressed.connect(func(): choose_origin=true; _update_route_label()); side.add_child(origin_btn)
	var dest_btn:=Button.new(); dest_btn.text="2  SELECT ARRIVAL"; dest_btn.position=Vector2(14,128); dest_btn.size=Vector2(272,40); _style_button(dest_btn); dest_btn.pressed.connect(func(): choose_origin=false; _update_route_label()); side.add_child(dest_btn)
	selected_label=_label(side,"DEPARTURE: —\nARRIVAL: —",Vector2(14,176),Vector2(272,55),13,Color.WHITE)
	_label(side,"AIRPORTS",Vector2(14,234),Vector2(260,26),16,Color("#49d8ff"))
	var scroll:=ScrollContainer.new(); scroll.position=Vector2(12,264); scroll.size=Vector2(276,194); side.add_child(scroll)
	results=VBoxContainer.new(); results.size_flags_horizontal=Control.SIZE_EXPAND_FILL; results.add_theme_constant_override("separation",5); scroll.add_child(results)
	_label(side,"SPAWN LOCATION",Vector2(14,466),Vector2(260,24),16,Color("#49d8ff"))
	spawn_gate_button=Button.new(); spawn_gate_button.text="PARKING GATE"; spawn_gate_button.position=Vector2(14,492); spawn_gate_button.size=Vector2(130,38); _style_button(spawn_gate_button); spawn_gate_button.pressed.connect(func(): _set_spawn_location("gate")); side.add_child(spawn_gate_button)
	spawn_runway_button=Button.new(); spawn_runway_button.text="RUNWAY"; spawn_runway_button.position=Vector2(152,492); spawn_runway_button.size=Vector2(134,38); _style_button(spawn_runway_button); spawn_runway_button.pressed.connect(func(): _set_spawn_location("runway")); side.add_child(spawn_runway_button)
	_label(side,"Gate = parked start  •  Runway = ready for takeoff",Vector2(14,536),Vector2(270,38),11,Color("#c4d8e5"))
	_set_spawn_location("runway")
	var zoom_in:=Button.new(); zoom_in.text="＋"; zoom_in.position=Vector2(1220,86); zoom_in.size=Vector2(44,42); _style_button(zoom_in); zoom_in.pressed.connect(func(): _zoom_at(min(zoom+1,7), map_canvas.size * 0.5)); add_child(zoom_in)
	var zoom_out:=Button.new(); zoom_out.text="－"; zoom_out.position=Vector2(1220,134); zoom_out.size=Vector2(44,42); _style_button(zoom_out); zoom_out.pressed.connect(func(): _zoom_at(max(zoom-1,1), map_canvas.size * 0.5)); add_child(zoom_out)
	var bottom:=_panel(self,Rect2(0,630,1280,90),Color("#06141f"))
	var back:=Button.new(); back.text="◀  BACK"; back.position=Vector2(32,18); back.size=Vector2(145,48); _style_button(back); back.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/aircraft_selection.tscn")); bottom.add_child(back)
	status_label=_label(bottom,"OFFLINE MAP  •  bundled tiles only  •  no map network requests",Vector2(200,29),Vector2(480,30),13,Color("#a9c5d6"))
	var reset:=Button.new(); reset.text="RESET VIEW"; reset.position=Vector2(700,18); reset.size=Vector2(150,48); _style_button(reset); reset.pressed.connect(func(): center_lat=20.0; center_lon=10.0; zoom=2; _queue_visible_tiles()); bottom.add_child(reset)
	var start:=Button.new(); start.text="START FLIGHT  ▶"; start.position=Vector2(1030,18); start.size=Vector2(218,48); _style_button(start,true); start.pressed.connect(_start_flight); bottom.add_child(start)
	_refresh_results("")

func _panel(parent: Control, rect: Rect2, color: Color) -> Panel:
	var p:=Panel.new(); p.position=rect.position; p.size=rect.size; p.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.set_corner_radius_all(8); style.border_width_left=1; style.border_width_top=1; style.border_width_right=1; style.border_width_bottom=1; style.border_color=Color("#15516e"); p.add_theme_stylebox_override("panel",style); parent.add_child(p); return p
func _label(parent: Control, text_value: String, pos: Vector2, dims: Vector2, font_size: int, color: Color) -> Label:
	var l:=Label.new(); l.text=text_value; l.position=pos; l.size=dims; l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(l); return l
func _style_button(b: Button, primary: bool=false) -> void:
	b.add_theme_font_size_override("font_size",15); b.add_theme_color_override("font_color",Color.WHITE)
	var s:=StyleBoxFlat.new(); s.bg_color=Color("#087da7") if primary else Color("#123c56"); s.set_corner_radius_all(6); s.border_width_bottom=1; s.border_color=Color("#27bde8"); b.add_theme_stylebox_override("normal",s)
	var h:=s.duplicate(); h.bg_color=Color("#0a9acb") if primary else Color("#1b5475"); b.add_theme_stylebox_override("hover",h); b.add_theme_stylebox_override("pressed",h)

func _on_search(query: String) -> void:
	_refresh_results(query)
	var q:=query.strip_edges().to_upper()
	for a in AIRPORTS:
		if a.icao==q or a.iata==q:
			center_lat=a.lat; center_lon=a.lon; zoom=max(zoom,5); _queue_visible_tiles(); _select_airport(a); return
	if results.get_child_count()==0: status_label.text="No airport matched. Try ICAO (e.g. VNKT) or city name."

func _refresh_results(query: String) -> void:
	for c in results.get_children(): c.queue_free()
	var q:=query.strip_edges().to_lower()
	var count:=0
	for a in AIRPORTS:
		var hay: String=(a.icao+" "+a.iata+" "+a.name+" "+a.city).to_lower()
		if q!="" and not hay.contains(q): continue
		var b:=Button.new(); b.text=a.icao+"  ·  "+a.iata+"\n"+a.city; b.custom_minimum_size=Vector2(250,50); b.alignment=HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_font_size_override("font_size",13); b.add_theme_color_override("font_color",Color.WHITE); _style_button(b); b.pressed.connect(_select_airport.bind(a)); results.add_child(b); count+=1
		if count>=50: break

func _select_airport(a: Dictionary) -> void:
	if choose_origin: origin=a.duplicate(true); choose_origin=false
	else: destination=a.duplicate(true)
	center_lat=a.lat; center_lon=a.lon; zoom=max(zoom,4); _update_route_label(); _queue_visible_tiles()
	status_label.text="Selected "+a.icao+" — "+a.name
func _update_route_label() -> void:
	var o: String=origin.get("icao","—"); var d: String=destination.get("icao","—")
	if is_instance_valid(selected_label): selected_label.text="DEPARTURE: "+o+"\nARRIVAL: "+d
	if is_instance_valid(search_edit): search_edit.placeholder_text="Search "+("departure" if choose_origin else "arrival")+" ICAO / city"

func _start_flight() -> void:
	if origin.is_empty() or destination.is_empty(): status_label.text="Select both a departure and arrival airport first."; return
	if origin.icao==destination.icao: status_label.text="Departure and arrival must be different airports."; return
	var route={"departure":origin,"arrival":destination,"aircraft":_selected_aircraft(),"spawn_location":spawn_location}
	var f:=FileAccess.open("user://selected_route.json",FileAccess.WRITE)
	if f == null:
		status_label.text="Could not save flight setup. Check user data storage."
		return
	f.store_string(JSON.stringify(route,"\t"))
	f.close()
	var spawn_file:=FileAccess.open("user://spawn_location.json",FileAccess.WRITE)
	if spawn_file:
		spawn_file.store_string(JSON.stringify({"spawn_location":spawn_location,"airport":origin.icao},"\t"))
		spawn_file.close()
	status_label.text="Building 3D airport and Cessna 172…"
	var next_scene := "res://scene/airport_3d_flight.tscn"
	if not ResourceLoader.exists(next_scene):
		status_label.text="3D flight scene is missing."
		return
	var error := get_tree().change_scene_to_file(next_scene)
	if error != OK:
		status_label.text="Could not start flight (error %d)." % error
func _set_spawn_location(value: String) -> void:
	spawn_location = value
	if is_instance_valid(spawn_gate_button):
		spawn_gate_button.text = "✓ PARKING GATE" if value == "gate" else "PARKING GATE"
		spawn_runway_button.text = "✓ RUNWAY" if value == "runway" else "RUNWAY"
		_style_button(spawn_gate_button, value == "gate")
		_style_button(spawn_runway_button, value == "runway")

func _selected_aircraft() -> String:
	if FileAccess.file_exists("user://selected_aircraft.json"):
		var file := FileAccess.open("user://selected_aircraft.json", FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				return str(parsed.get("aircraft", "Cessna 172"))
	return "Cessna 172"
func _show_map_info() -> void:
	status_label.text="Offline mode: only map tiles packaged with the app are shown. No map requests are sent."

func _on_map_input(event: InputEvent) -> void:
	# Desktop: wheel zoom, drag to pan, click an airport marker to select it.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(min(zoom + 1, 7), event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(max(zoom - 1, 1), event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_last = event.position
				mouse_press_pos = event.position
				mouse_moved = false
			else:
				is_dragging = false
				if not mouse_moved and mouse_press_pos.distance_to(event.position) < 10.0:
					_select_airport_at(event.position)
	elif event is InputEventMouseMotion and is_dragging:
		var delta: Vector2 = event.position - drag_last
		if mouse_press_pos.distance_to(event.position) >= 8.0:
			mouse_moved = true
		_pan_by(delta)
		drag_last = event.position
	# Mobile: one finger pans; two fingers pinch-zoom around the gesture midpoint.
	elif event is InputEventScreenTouch:
		var touch_idx: int = event.index
		if event.pressed:
			touch_points[touch_idx] = event.position
			touch_start_positions[touch_idx] = event.position
			touch_moved[touch_idx] = false
			if touch_points.size() == 2:
				var touch_points_array: Array = touch_points.values()
				var touch_a: Vector2 = touch_points_array[0]
				var touch_b: Vector2 = touch_points_array[1]
				pinch_last_distance = touch_a.distance_to(touch_b)
				for touch_id in touch_moved.keys():
					touch_moved[touch_id] = true
				is_dragging = false
		else:
			var was_tap: bool = touch_points.size() == 1 and not bool(touch_moved.get(touch_idx, false))
			if was_tap and touch_start_positions.has(touch_idx) and touch_start_positions[touch_idx].distance_to(event.position) < 12.0:
				_select_airport_at(event.position)
			touch_points.erase(touch_idx)
			touch_start_positions.erase(touch_idx)
			touch_moved.erase(touch_idx)
			if touch_points.size() < 2:
				pinch_last_distance = 0.0
				if touch_points.size() == 1:
					var remaining_id = touch_points.keys()[0]
					drag_last = touch_points[remaining_id]
	elif event is InputEventScreenDrag:
		var drag_idx: int = event.index
		var previous: Vector2 = event.position
		if touch_points.has(drag_idx):
			previous = touch_points[drag_idx]
			touch_points[drag_idx] = event.position
			if touch_start_positions.has(drag_idx) and touch_start_positions[drag_idx].distance_to(event.position) >= 8.0:
				touch_moved[drag_idx] = true
		if touch_points.size() >= 2:
			var drag_points_array: Array = touch_points.values()
			var drag_a: Vector2 = drag_points_array[0]
			var drag_b: Vector2 = drag_points_array[1]
			var distance: float = drag_a.distance_to(drag_b)
			var midpoint: Vector2 = (drag_a + drag_b) * 0.5
			if pinch_last_distance > 0.0 and distance > 0.0:
				if distance >= pinch_last_distance * 1.16:
					_zoom_at(min(zoom + 1, 7), midpoint)
					pinch_last_distance = distance
				elif distance <= pinch_last_distance * 0.86:
					_zoom_at(max(zoom - 1, 1), midpoint)
					pinch_last_distance = distance
		else:
			_pan_by(event.position - previous)

func _zoom_at(target_zoom: int, focus: Vector2) -> void:
	if target_zoom == zoom or not is_instance_valid(map_canvas):
		return
	# Keep the geographic point beneath the cursor/fingers fixed during zoom.
	var old_center_world: Vector2 = _latlon_to_world(center_lat, center_lon)
	var old_top_left: Vector2 = old_center_world - map_canvas.size * 0.5
	var focus_world: Vector2 = old_top_left + focus
	var focus_latlon: Vector2 = _world_to_latlon(focus_world)
	zoom = target_zoom
	var new_focus_world: Vector2 = _latlon_to_world(focus_latlon.x, focus_latlon.y)
	var new_center_world: Vector2 = new_focus_world - focus + map_canvas.size * 0.5
	var new_center_latlon: Vector2 = _world_to_latlon(new_center_world)
	center_lat = clampf(new_center_latlon.x, -80.0, 80.0)
	center_lon = wrapf(new_center_latlon.y, -180.0, 180.0)
	_queue_visible_tiles()

func _select_airport_at(screen_position: Vector2) -> void:
	var nearest: Dictionary = {}
	var nearest_distance: float = 24.0 # Comfortable touch target on mobile.
	var center_world: Vector2 = _latlon_to_world(center_lat, center_lon)
	var top_left: Vector2 = center_world - map_canvas.size * 0.5
	var world_width: float = TILE_SIZE * pow(2.0, zoom)
	for airport in AIRPORTS:
		var point: Vector2 = _latlon_to_world(airport.lat, airport.lon) - top_left
		# Wrap marker positions around the international date line.
		while point.x - screen_position.x > world_width * 0.5:
			point.x -= world_width
		while screen_position.x - point.x > world_width * 0.5:
			point.x += world_width
		var distance: float = point.distance_to(screen_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = airport
	if not nearest.is_empty():
		_select_airport(nearest)
	else:
		status_label.text = "Tap an airport marker to select it, or choose one from the airport list."

func _pan_by(delta: Vector2) -> void:
	var world_per_pixel:=360.0/(TILE_SIZE*pow(2.0,zoom))
	center_lon=wrapf(center_lon-delta.x*world_per_pixel,-180.0,180.0)
	center_lat=clampf(center_lat+delta.y*world_per_pixel,-80.0,80.0)
	_queue_visible_tiles()

func _latlon_to_world(lat: float, lon: float) -> Vector2:
	var n:=pow(2.0,zoom)*TILE_SIZE
	var x: float=(lon+180.0)/360.0*n
	var lat_r:=deg_to_rad(clampf(lat,-85.0511,85.0511))
	var y: float=(1.0-log(tan(lat_r)+1.0/cos(lat_r))/PI)/2.0*n
	return Vector2(x,y)
func _world_to_latlon(world: Vector2) -> Vector2:
	var n:=pow(2.0,zoom)*TILE_SIZE
	var lon:=world.x/n*360.0-180.0
	var lat:=rad_to_deg(atan(sinh(PI*(1.0-2.0*world.y/n))))
	return Vector2(lat,lon)
func _queue_visible_tiles() -> void:
	# Deliberately offline: load existing local tiles only; never contact OpenStreetMap.
	if not is_instance_valid(map_canvas): return
	var center := _latlon_to_world(center_lat, center_lon)
	var half := map_canvas.size / 2.0
	var top_left := center - half
	var bottom_right := center + half
	var min_tx := int(floor(top_left.x / TILE_SIZE))
	var max_tx := int(floor(bottom_right.x / TILE_SIZE))
	var min_ty: int = maxi(0, int(floor(top_left.y / TILE_SIZE)))
	var max_ty: int = mini(int(pow(2.0, zoom)) - 1, int(floor(bottom_right.y / TILE_SIZE)))
	for ty in range(min_ty, max_ty + 1):
		for tx in range(min_tx, max_tx + 1):
			var key := Vector3i(zoom, posmod(tx, int(pow(2.0, zoom))), ty)
			if not tile_textures.has(key):
				_load_bundled_tile(key)
	map_canvas.queue_redraw()

func _bundled_tile_path(key: Vector3i) -> String:
	# key is Vector3i(zoom, tile_x, tile_y); no user:// cache and no HTTP fallback.
	return "%s/%d/%d/%d.png" % [TILE_DATA_DIR, key.x, key.y, key.z]

func _load_bundled_tile(key: Vector3i) -> bool:
	var path := _bundled_tile_path(key)
	if not FileAccess.file_exists(path):
		return false
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("Could not load bundled map tile: " + path)
		return false
	tile_textures[key] = ImageTexture.create_from_image(image)
	return true

func _draw_map() -> void:
	if not is_instance_valid(map_canvas): return
	map_canvas.draw_rect(Rect2(Vector2.ZERO,map_canvas.size),Color("#9ccbdc"))
	var center:=_latlon_to_world(center_lat,center_lon); var top_left:=center-map_canvas.size/2.0
	var min_tx=int(floor(top_left.x/TILE_SIZE)); var max_tx=int(floor((top_left.x+map_canvas.size.x)/TILE_SIZE))
	var min_ty=max(0,int(floor(top_left.y/TILE_SIZE))); var max_ty=min(int(pow(2.0,zoom))-1,int(floor((top_left.y+map_canvas.size.y)/TILE_SIZE)))
	for ty in range(min_ty,max_ty+1):
		for tx in range(min_tx,max_tx+1):
			var key=Vector3i(zoom,posmod(tx,int(pow(2.0,zoom))),ty)
			var rect=Rect2(Vector2(tx*TILE_SIZE,ty*TILE_SIZE)-top_left,Vector2(TILE_SIZE,TILE_SIZE))
			if tile_textures.has(key): map_canvas.draw_texture_rect(tile_textures[key],rect,false)
			else: map_canvas.draw_rect(rect,Color("#a3cddd")); map_canvas.draw_rect(rect,Color("#77b5c8"),false,1.0)
	# Draw the planned route beneath the airport markers so both endpoints remain easy to tap.
	if not origin.is_empty() and not destination.is_empty():
		_draw_route_line(top_left)
	for a in AIRPORTS:
		var p=_latlon_to_world(a.lat,a.lon)-top_left
		if Rect2(Vector2.ZERO,map_canvas.size).has_point(p):
			map_canvas.draw_circle(p,5.0,Color("#e94343")); map_canvas.draw_circle(p,2.5,Color.WHITE)
			if zoom>=4: map_canvas.draw_string(ThemeDB.fallback_font,p+Vector2(8,4),a.icao,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#07304a"))
	if not origin.is_empty(): _draw_airport_pin(origin,top_left,Color("#00a878"))
	if not destination.is_empty(): _draw_airport_pin(destination,top_left,Color("#d94c4c"))
	map_canvas.draw_rect(Rect2(Vector2(8,map_canvas.size.y-28),Vector2(300,22)),Color("#071f31d9"))
	map_canvas.draw_string(ThemeDB.fallback_font,Vector2(16,map_canvas.size.y-12),"OFFLINE MAP  •  bundled tiles only  •  © OpenStreetMap contributors",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)

func _draw_route_line(top_left: Vector2) -> void:
	if origin.is_empty() or destination.is_empty():
		return
	var start_world: Vector2 = _latlon_to_world(float(origin.lat), float(origin.lon))
	var end_world: Vector2 = _latlon_to_world(float(destination.lat), float(destination.lon))
	# Use the shortest wrapped map path for routes that cross the date line.
	var world_width: float = pow(2.0, zoom) * TILE_SIZE
	var delta_x: float = end_world.x - start_world.x
	if delta_x > world_width * 0.5:
		end_world.x -= world_width
	elif delta_x < -world_width * 0.5:
		end_world.x += world_width
	var start_point: Vector2 = start_world - top_left
	var end_point: Vector2 = end_world - top_left
	# A dark outline keeps the cyan route visible over both light and dark map tiles.
	map_canvas.draw_line(start_point, end_point, Color("#06263dcc"), 7.0, true)
	map_canvas.draw_line(start_point, end_point, Color("#35e0ff"), 3.0, true)

func _draw_airport_pin(a: Dictionary, top_left: Vector2, color: Color) -> void:
	var p=_latlon_to_world(a.lat,a.lon)-top_left
	map_canvas.draw_circle(p,10,color); map_canvas.draw_circle(p,5,Color.WHITE)
	map_canvas.draw_string(ThemeDB.fallback_font,p+Vector2(12,-8),a.icao,HORIZONTAL_ALIGNMENT_LEFT,-1,16,color)
