extends Node2D

const DiverScript = preload("res://scripts/diver.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const WorldScript = preload("res://scripts/world.gd")
const LifeformScript = preload("res://scripts/lifeform.gd")
const LIFE_ATLAS := preload("res://assets/art/alien_life.svg")
const LAMP_GLOW := preload("res://assets/art/lamp_glow.svg")
const DRIFTMETAL_ART := preload("res://assets/art/driftmetal.svg")
const LUMEN_KELP_ART := preload("res://assets/art/lumen_kelp.svg")
const MENU_OCEAN_ART := preload("res://assets/art/menu_ocean.svg")
const RADIO_ART := preload("res://assets/art/radio_icon.svg")
const TECHNOLOGY_ICONS := preload("res://assets/art/technology_icons.svg")

const STARTING_OXYGEN := 150.0
const STARTING_DEPTH_LIMIT := 500.0
const UPGRADED_DEPTH_LIMIT := 1050.0
const SUIT_DEPTH_LIMIT := 1650.0
const SUB_DEPTH_LIMIT := 2400.0
const SAVE_PATH := "user://quiet_trench_save.json"
const SETTINGS_PATH := "user://quiet_trench_settings.json"
const SCAN_SECONDS := 0.85
const ANALYZER_RANGE := 180.0
const ANALYZER_HALF_ANGLE := 15.0
const INVENTORY_SLOT_COUNT := 24
const QUICK_SLOT_COUNT := 5
const TECHNOLOGY_ICON_REGIONS := {
	"pressure_weave": Rect2i(0, 0, 128, 128),
	"deep_tank": Rect2i(128, 0, 128, 128),
	"fins": Rect2i(256, 0, 128, 128),
	"lamp": Rect2i(384, 0, 128, 128),
	"submersible": Rect2i(512, 0, 128, 128),
	"tranquilizer": Rect2i(640, 0, 128, 128),
	"medkit": Rect2i(768, 0, 128, 128)
}
const WORLD_LIMIT_X := 1400.0
const AUTOSAVE_INTERVALS := [0, 30, 60, 300, 600, 900, 1800]
const RESOLUTIONS := [
	Vector2i(1024, 576),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]
const KEY_BINDINGS := {
	"move_up": "Swim up",
	"move_down": "Swim down",
	"move_left": "Swim left",
	"move_right": "Swim right",
	"interact": "Interact",
	"technology": "Technology bench",
	"pause": "Pause menu"
}

const RECIPES := {
	"pressure_weave": {
		"title": "Pressure-weave suit",
		"scan": "Known at start",
		"cost": {"driftmetal": 3, "lumen_kelp": 1},
		"description": "Reinforce your suit to dive into the middle depths."
	},
	"fins": {
		"title": "Current-rider fins",
		"scan": "Ribbon glider",
		"cost": {"ribbon_silk": 2, "ember_kelp": 2},
		"description": "Swim faster. Hold Shift to kick into a burst."
	},
	"deep_tank": {
		"title": "Moon-jelly scrubber tank",
		"scan": "Moon-jelly",
		"cost": {"moon_mucus": 2, "spire_coral": 1},
		"description": "More oxygen per dive and a safer deep pressure rating."
	},
	"lamp": {
		"title": "Lantern-bloom lamp",
		"scan": "Lantern bloom",
		"cost": {"abyssal_bloom": 2, "veil_moss": 1},
		"description": "A focused light reveals shapes in dark water."
	},
	"submersible": {
		"title": "Pocket pressure pod",
		"scan": "Glassback",
		"cost": {"shell_plate": 2, "spire_coral": 2},
		"description": "A compact powered pod for exploring the lower trench."
	},
	"tranquilizer": {
		"title": "Dreamspore dart launcher",
		"scan": "Riftstalker",
		"cost": {"electric_filament": 1, "ember_kelp": 1},
		"description": "Right-click a nearby threat in the analyzer beam to stun it."
	},
	"medkit": {
		"title": "Symbiotic repair gel",
		"scan": "Veil moss",
		"cost": {"veil_moss": 2, "moon_mucus": 1},
		"description": "Restore health after a dangerous encounter."
	}
}

const SPECIES := [
	{
		"id": "moon_jelly",
		"name": "Moon-jelly",
		"kind": "fauna",
		"resource": "moon_mucus",
		"recipe": "deep_tank",
		"region": Rect2i(0, 0, 128, 128),
		"depth": Vector2(270, 0),
		"count": 3,
		"yield": 1,
		"aggressive": false,
		"ability": "oxygen_pulse"
	},
	{
		"id": "ribbon_glider",
		"name": "Ribbon glider",
		"kind": "fauna",
		"resource": "ribbon_silk",
		"recipe": "fins",
		"region": Rect2i(128, 0, 128, 128),
		"depth": Vector2(390, 500),
		"count": 3,
		"yield": 1,
		"aggressive": false,
		"ability": "current_burst"
	},
	{
		"id": "glassback",
		"name": "Glassback",
		"kind": "fauna",
		"resource": "shell_plate",
		"recipe": "submersible",
		"region": Rect2i(256, 0, 128, 128),
		"depth": Vector2(570, 850),
		"count": 3,
		"yield": 1,
		"aggressive": false,
		"ability": "shell_guard"
	},
	{
		"id": "riftstalker",
		"name": "Riftstalker",
		"kind": "fauna",
		"resource": "electric_filament",
		"recipe": "tranquilizer",
		"region": Rect2i(384, 0, 128, 128),
		"depth": Vector2(760, 1350),
		"count": 2,
		"yield": 1,
		"aggressive": true,
		"ability": "electric_lunge"
	},
	{
		"id": "ember_kelp",
		"name": "Ember kelp",
		"kind": "flora",
		"resource": "ember_kelp",
		"recipe": "fins",
		"region": Rect2i(512, 0, 128, 128),
		"depth": Vector2(305, 180),
		"count": 4,
		"yield": 1,
		"aggressive": false,
		"flora_behavior": "sway",
		"ability": "warm_current"
	},
	{
		"id": "veil_moss",
		"name": "Veil moss",
		"kind": "flora",
		"resource": "veil_moss",
		"recipe": "medkit",
		"region": Rect2i(640, 0, 128, 128),
		"depth": Vector2(520, 720),
		"count": 4,
		"yield": 1,
		"aggressive": false,
		"flora_behavior": "creep",
		"ability": "healing_spores"
	},
	{
		"id": "spire_coral",
		"name": "Spire coral",
		"kind": "flora",
		"resource": "spire_coral",
		"recipe": "submersible",
		"region": Rect2i(768, 0, 128, 128),
		"depth": Vector2(675, 1120),
		"count": 4,
		"yield": 1,
		"aggressive": true,
		"flora_behavior": "stalk",
		"ability": "vine_snare"
	},
	{
		"id": "lantern_bloom",
		"name": "Lantern bloom",
		"kind": "flora",
		"resource": "abyssal_bloom",
		"recipe": "lamp",
		"region": Rect2i(896, 0, 128, 128),
		"depth": Vector2(560, 930),
		"count": 4,
		"yield": 1,
		"aggressive": false,
		"flora_behavior": "pulse",
		"ability": "lure_flash"
	}
]

var save_path := SAVE_PATH
var settings_path := SETTINGS_PATH
var ocean_world: OceanWorld
var diver: OceanDiver
var pickups: Array[SalvagePickup] = []
var lifeforms: Array[AlienLifeform] = []
var inventory := {
	"driftmetal": 0,
	"lumen_kelp": 0,
	"moon_mucus": 0,
	"ribbon_silk": 0,
	"shell_plate": 0,
	"electric_filament": 0,
	"ember_kelp": 0,
	"veil_moss": 0,
	"spire_coral": 0,
	"abyssal_bloom": 0
}
var discovered_materials := {}
var unlocked_recipes := {"pressure_weave": true}
var installed_techs := {}
var oxygen := STARTING_OXYGEN
var oxygen_capacity := STARTING_OXYGEN
var depth_limit := STARTING_DEPTH_LIMIT
var health := 100.0
var scan_target: AlienLifeform
var scan_progress := 0.0
var analyzer_beam: MeshInstance2D
var analyzer_mesh: ArrayMesh
var scan_cooldown := 0.0
var dart_cooldown := 0.0
var suit_upgraded := false
var signal_found := false
var story_message := "The escape pod ruptures against the shore. The ocean is quiet. Too quiet."

var status_label: Label
var prompt_label: Label
var oxygen_bar: ProgressBar
var depth_label: Label
var oxygen_empty_time := 0.0
var vehicle_bar: ProgressBar
var vehicle_caption: Label
var hover_panel: PanelContainer
var hover_label: Label
var world_tint: CanvasModulate
var oxygen_fill_style: StyleBoxFlat
var health_bar: ProgressBar
var weather_label: Label
var scan_label: Label
var scan_bar: ProgressBar
var hint_panels: Array[Control] = []
var prompt_panel: PanelContainer
var scan_panel: PanelContainer
var crafting_overlay: ColorRect
var inventory_overlay: ColorRect
var inventory_grid: GridContainer
var inventory_status: Label
var inventory_tooltip: PanelContainer
var inventory_tooltip_label: Label
var inventory_slots: Array[Button] = []
var inventory_icon_nodes: Array[TextureRect] = []
var inventory_count_labels: Array[Label] = []
var inventory_slot_resources: Array[String] = []
var quick_slot_buttons: Array[Button] = []
var quick_slot_icons: Array[TextureRect] = []
var quick_slot_resources: Array[String] = ["", "", "", "", ""]
var selected_quick_slot := 0
var inventory_open := false
var inventory_hovered_resource := ""
var health_bar_offset := Vector2(0, 40)
var recipe_list: VBoxContainer
var recipe_details: Label
var selected_recipe := ""
var hud_canvas: CanvasLayer
var lamp_light: PointLight2D
var radio_button: Button
var radio_panel: PanelContainer
var pause_overlay: ColorRect
var pause_panel: PanelContainer
var menu_pattern: TextureRect
var pause_scroll: ScrollContainer
var pause_content: VBoxContainer
var pause_message: Label
var settings_message: Label
var confirm_exit_dialog: ConfirmationDialog
var settings_data := {
	"resolution": Vector2i(1280, 720),
	"master_volume": 1.0,
	"autosave_interval": 60,
	"fullscreen": false,
	"show_gameplay_hints": false
}
var autosave_elapsed := 0.0
var awaiting_keybinding := ""
var pause_menu_open := false
var settings_panel_visible := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_gameplay_inputs()
	_load_settings()
	var world: OceanWorld = WorldScript.new()
	world.z_index = -10
	add_child(world)
	ocean_world = world
	_create_atmosphere()

	diver = DiverScript.new()
	diver.name = "Diver"
	diver.position = Vector2(35, -70)
	diver.z_index = 4
	add_child(diver)

	_create_pickups()
	_create_lifeforms()
	_load_game()
	_create_hud()
	_create_inventory_window()
	_create_analyzer_beam()
	_create_crafting_window()
	_create_pause_menu()
	_create_radio_panel()
	_apply_installed_techs()
	_refresh_hud()
	_refresh_crafting_window()

func _setup_gameplay_inputs() -> void:
	var defaults := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E],
		"technology": [KEY_F],
		"pause": [KEY_ESCAPE]
	}
	for action in defaults:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for keycode in defaults[action]:
				var key_event := InputEventKey.new()
				key_event.physical_keycode = keycode
				InputMap.action_add_event(action, key_event)

func _load_settings() -> void:
	if not FileAccess.file_exists(settings_path):
		_apply_settings()
		return
	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		push_error("Could not read settings: %s" % error_string(FileAccess.get_open_error()))
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Settings file is invalid JSON.")
		return
	var resolution_values: Array = parsed.get("resolution", [1280, 720])
	if resolution_values.size() == 2:
		var saved_resolution := Vector2i(
			int(resolution_values[0]),
			int(resolution_values[1])
		)
		if RESOLUTIONS.has(saved_resolution):
			settings_data["resolution"] = saved_resolution
		else:
			push_warning("Unsupported saved resolution; using the default.")
	settings_data["master_volume"] = clampf(float(parsed.get("master_volume", 1.0)), 0.0, 1.0)
	var saved_bindings: Dictionary = parsed.get("key_bindings", {})
	for action in KEY_BINDINGS:
		if not saved_bindings.has(action) or not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for physical_keycode in saved_bindings[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(physical_keycode) as Key
			InputMap.action_add_event(action, key_event)
	var autosave_interval := int(parsed.get("autosave_interval", 60))
	if autosave_interval in AUTOSAVE_INTERVALS:
		settings_data["autosave_interval"] = autosave_interval
	settings_data["fullscreen"] = bool(parsed.get("fullscreen", false))
	settings_data["show_gameplay_hints"] = bool(parsed.get("show_gameplay_hints", false))
	_apply_settings()

func _apply_settings() -> void:
	var resolution: Vector2i = settings_data["resolution"]
	if bool(settings_data["fullscreen"]):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
		var screen_size := DisplayServer.screen_get_size()
		DisplayServer.window_set_position(
			Vector2i(
				maxi(0, int(floor(float(screen_size.x - resolution.x) / 2.0))),
				maxi(0, int(floor(float(screen_size.y - resolution.y) / 2.0)))
			)
		)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_linear(master_bus, float(settings_data["master_volume"]))
	else:
		push_error("The Master audio bus is missing.")

func _save_settings() -> void:
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save settings: %s" % error_string(FileAccess.get_open_error()))
		return
	var saved_settings := settings_data.duplicate()
	var resolution: Vector2i = settings_data["resolution"]
	saved_settings["resolution"] = [resolution.x, resolution.y]
	var saved_bindings := {}
	for action in KEY_BINDINGS:
		var keycodes: Array[int] = []
		for assigned_event in InputMap.action_get_events(action):
			if assigned_event is InputEventKey:
				keycodes.append((assigned_event as InputEventKey).physical_keycode)
		saved_bindings[action] = keycodes
	saved_settings["key_bindings"] = saved_bindings
	file.store_string(JSON.stringify(saved_settings))
	var error := file.get_error()
	if error != OK:
		push_error("Could not write settings: %s" % error_string(error))

func _update_autosave(delta: float) -> void:
	var interval := int(settings_data["autosave_interval"])
	if interval <= 0:
		autosave_elapsed = 0.0
		return
	autosave_elapsed += delta
	if autosave_elapsed >= float(interval):
		autosave_elapsed = fmod(autosave_elapsed, float(interval))
		_save_game()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var depth := maxf(0.0, diver.global_position.y - 77.0)
	var depth_ratio := clampf(depth / float(SUB_DEPTH_LIMIT), 0.0, 1.0)
	var depth_tint := Color.WHITE.lerp(Color(0.18, 0.29, 0.48), depth_ratio * 0.74)
	world_tint.color = depth_tint.lerp(ocean_world.ambient_tint, 0.10)
	weather_label.text = "%s  ·  %s" % [
		"DAY" if ocean_world.daylight >= 0.5 else "NIGHT",
		ocean_world.weather
	]
	weather_label.modulate = Color(0.72, 0.89, 0.95, 0.55) if ocean_world.weather == "MIST" else Color.WHITE
	if diver.global_position.y <= 145.0:
		oxygen = minf(oxygen_capacity, oxygen + 34.0 * delta)
		if diver.has_submersible:
			diver.vehicle_health = minf(100.0, diver.vehicle_health + 10.0 * delta)
		oxygen_empty_time = 0.0
	else:
		var over_depth := maxf(0.0, depth - depth_limit)
		var oxygen_stress := 1.0 + over_depth * 0.018
		oxygen = maxf(0.0, oxygen - (1.8 + depth * 0.006) * oxygen_stress * delta)
		if over_depth > 0.0:
			if diver.has_submersible and diver.vehicle_health > 0.0:
				diver.vehicle_health = maxf(
					0.0,
					diver.vehicle_health - (1.5 + over_depth * 0.012) * delta
				)
				if diver.vehicle_health <= 0.0:
					health = maxf(0.0, health - 12.0 * delta)
			else:
				var pressure_damage := (1.5 + over_depth * 0.012) * delta
				health = maxf(
					0.0,
					health - pressure_damage * (0.4 if diver.shield_time > 0.0 else 1.0)
				)

	for lifeform in lifeforms:
		if lifeform.harvested:
			continue
		var ability_distance := diver.global_position.distance_to(lifeform.global_position)
		_update_lifeform_ability(lifeform, ability_distance)
		if lifeform.aggressive and lifeform.stun_remaining <= 0.0 and ability_distance < 100.0:
			health = maxf(
				0.0,
				health - 20.0 * delta * (0.4 if diver.shield_time > 0.0 else 1.0)
			)
			story_message = "%s is striking! Scan it or escape." % lifeform.specimen_name

	if oxygen <= 0.0 and diver.global_position.y > 145.0:
		oxygen_empty_time += delta
		if oxygen_empty_time >= 5.0:
			diver.global_position = Vector2(-185, 90)
			oxygen = oxygen_capacity
			health = maxf(health, 45.0)
			oxygen_empty_time = 0.0
			story_message = "Your emergency beacon hauls you back to the surface. The pod's lights flicker."

	scan_cooldown = maxf(0.0, scan_cooldown - delta)
	dart_cooldown = maxf(0.0, dart_cooldown - delta)
	_update_autosave(delta)
	_update_analyzer(delta)
	_refresh_hud()
	_update_inventory_tooltip_position()
	_update_world_hover()

func _update_lifeform_ability(lifeform: AlienLifeform, distance: float) -> void:
	if (
		lifeform.ability in ["electric_lunge", "vine_snare"]
		or lifeform.stun_remaining > 0.0
		or lifeform.ability_cooldown > 0.0
		or distance > 225.0
	):
		return
	match lifeform.ability:
		"oxygen_pulse":
			oxygen = minf(oxygen_capacity, oxygen + 28.0)
			story_message = "A Moon-jelly releases a clean oxygen pulse."
			lifeform.ability_cooldown = 13.0
		"current_burst":
			diver.current_boost_time = 4.0
			story_message = "A Ribbon glider's current carries you forward."
			lifeform.ability_cooldown = 12.0
		"shell_guard":
			diver.shield_time = 5.0
			story_message = "A Glassback wraps you in a protective resonance."
			lifeform.ability_cooldown = 16.0
		"warm_current":
			oxygen = minf(oxygen_capacity, oxygen + 16.0)
			story_message = "Ember kelp warms the water and eases your breathing."
			lifeform.ability_cooldown = 15.0
		"healing_spores":
			health = minf(100.0, health + 12.0)
			story_message = "Veil moss releases restorative spores."
			lifeform.ability_cooldown = 16.0
		"lure_flash":
			for threat in lifeforms:
				if (
					threat.aggressive
					and not threat.harvested
					and threat.global_position.distance_to(lifeform.global_position) < 270.0
				):
					threat.stun()
			story_message = "Lantern bloom's flash disorients nearby hunters."
			lifeform.ability_cooldown = 14.0
		_:
			return
	lifeform.activate_ability()

func _unhandled_input(event: InputEvent) -> void:
	if awaiting_keybinding != "":
		if event is InputEventKey and event.pressed and not event.echo:
			_apply_keybinding(event as InputEventKey)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_TAB:
			if inventory_open:
				_toggle_inventory(false)
			elif not get_tree().paused:
				_toggle_inventory(true)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause") and not event.is_echo():
		if inventory_open:
			_toggle_inventory(false)
		elif settings_panel_visible:
			_show_settings(false)
		elif pause_menu_open:
			_set_pause_menu(false)
		else:
			_set_pause_menu(true)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and (
		not get_tree().paused or inventory_open
	):
		var key_event := event as InputEventKey
		var quick_slot := int(key_event.keycode) - int(KEY_1)
		if quick_slot >= 0 and quick_slot < QUICK_SLOT_COUNT:
			_select_quick_slot(quick_slot)
			get_viewport().set_input_as_handled()
			return
	if get_tree().paused:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("technology") and not event.is_echo():
		_toggle_crafting_window(not crafting_overlay.visible)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and not crafting_overlay.visible:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_fire_dart()

func _create_pickups() -> void:
	_add_pickup("metal_a", "Driftmetal", "driftmetal", 1, Vector2(-450, 270))
	_add_pickup("kelp_a", "Lumen kelp", "lumen_kelp", 1, Vector2(280, 345))
	_add_pickup("metal_b", "Driftmetal", "driftmetal", 1, Vector2(560, 420))
	_add_pickup("kelp_b", "Lumen kelp", "lumen_kelp", 1, Vector2(-720, 460))
	_add_pickup("metal_c", "Driftmetal", "driftmetal", 1, Vector2(930, 485))
	_add_pickup("metal_deep", "Abyssal alloy", "driftmetal", 2, Vector2(-1050, 810))
	_add_pickup("metal_far", "Driftmetal", "driftmetal", 1, Vector2(1180, 380))
	_add_pickup("kelp_far", "Lumen kelp", "lumen_kelp", 1, Vector2(-1200, 320))
	_add_pickup(
		"signal_fragment",
		"Signal fragment",
		"story",
		0,
		Vector2(80, 1320),
		"An old recording crackles to life: \"We did not make the trench. It was here before the water.\""
	)
	_add_pickup("metal_deep_2", "Abyssal alloy", "driftmetal", 2, Vector2(1210, 1250))

func _create_lifeforms() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 48712
	for species_data in SPECIES:
		var atlas := AtlasTexture.new()
		atlas.atlas = LIFE_ATLAS
		atlas.region = species_data.region
		for index in range(int(species_data.count)):
			var lifeform: AlienLifeform = LifeformScript.new()
			lifeform.species_id = species_data.id
			lifeform.specimen_name = species_data.name
			lifeform.species_kind = species_data.kind
			lifeform.resource_id = species_data.resource
			lifeform.recipe_id = species_data.recipe
			lifeform.yield_amount = species_data["yield"]
			lifeform.aggressive = species_data.aggressive
			lifeform.ability = species_data.get("ability", "")
			lifeform.flora_behavior = species_data.get("flora_behavior", "")
			lifeform.hunter_target = diver
			lifeform.sprite_texture = atlas
			lifeform.lifeform_id = "%s_%d" % [species_data.id, index]
			var spread := Vector2(
				random.randf_range(-620.0, 620.0),
				random.randf_range(-105.0, 105.0)
			)
			lifeform.position = species_data.depth + spread
			lifeform.z_index = 2 if species_data.kind == "flora" else 3
			add_child(lifeform)
			lifeforms.append(lifeform)

func _add_pickup(
	id: String,
	display_name: String,
	category: String,
	amount: int,
	world_position: Vector2,
	note := ""
) -> void:
	var pickup: SalvagePickup = PickupScript.new()
	pickup.pickup_id = id
	pickup.title = display_name
	pickup.category = category
	pickup.amount = amount
	pickup.story_text = note
	pickup.position = world_position
	add_child(pickup)
	pickups.append(pickup)

func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 2
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_canvas = canvas
	add_child(canvas)

	depth_label = Label.new()
	depth_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	depth_label.offset_top = 12.0
	depth_label.offset_bottom = 38.0
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.98))
	depth_label.add_theme_font_size_override("font_size", 19)
	canvas.add_child(depth_label)

	var oxygen_caption := Label.new()
	oxygen_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	oxygen_caption.offset_top = 40.0
	oxygen_caption.offset_bottom = 58.0
	oxygen_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oxygen_caption.text = "OXYGEN"
	oxygen_caption.add_theme_color_override("font_color", Color(0.60, 0.84, 0.98))
	oxygen_caption.add_theme_font_size_override("font_size", 11)
	canvas.add_child(oxygen_caption)
	oxygen_bar = ProgressBar.new()
	oxygen_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	oxygen_bar.anchor_left = 0.5
	oxygen_bar.anchor_right = 0.5
	oxygen_bar.offset_left = -130.0
	oxygen_bar.offset_right = 130.0
	oxygen_bar.offset_top = 60.0
	oxygen_bar.offset_bottom = 72.0
	oxygen_bar.max_value = STARTING_OXYGEN
	oxygen_bar.show_percentage = false
	var oxygen_track := StyleBoxFlat.new()
	oxygen_track.bg_color = Color(0.015, 0.105, 0.17, 0.96)
	oxygen_track.set_corner_radius_all(10)
	oxygen_bar.add_theme_stylebox_override("background", oxygen_track)
	oxygen_fill_style = StyleBoxFlat.new()
	oxygen_fill_style.bg_color = Color(0.18, 0.92, 0.78)
	oxygen_fill_style.set_corner_radius_all(9)
	oxygen_bar.add_theme_stylebox_override("fill", oxygen_fill_style)
	canvas.add_child(oxygen_bar)
	vehicle_bar = ProgressBar.new()
	vehicle_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	vehicle_bar.anchor_left = 0.5
	vehicle_bar.anchor_right = 0.5
	vehicle_bar.offset_left = -130.0
	vehicle_bar.offset_right = 130.0
	vehicle_bar.offset_top = 94.0
	vehicle_bar.offset_bottom = 103.0
	vehicle_bar.max_value = 100.0
	vehicle_bar.show_percentage = false
	vehicle_bar.visible = false
	var vehicle_track := StyleBoxFlat.new()
	vehicle_track.bg_color = Color(0.015, 0.105, 0.17, 0.96)
	vehicle_track.set_corner_radius_all(6)
	vehicle_bar.add_theme_stylebox_override("background", vehicle_track)
	var vehicle_fill := StyleBoxFlat.new()
	vehicle_fill.bg_color = Color(0.32, 0.84, 1.0)
	vehicle_fill.set_corner_radius_all(5)
	vehicle_bar.add_theme_stylebox_override("fill", vehicle_fill)
	canvas.add_child(vehicle_bar)
	vehicle_caption = Label.new()
	vehicle_caption.text = "POD HULL"
	vehicle_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vehicle_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	vehicle_caption.anchor_left = 0.5
	vehicle_caption.anchor_right = 0.5
	vehicle_caption.offset_left = -130.0
	vehicle_caption.offset_right = 130.0
	vehicle_caption.offset_top = 77.0
	vehicle_caption.offset_bottom = 91.0
	vehicle_caption.add_theme_font_size_override("font_size", 9)
	vehicle_caption.add_theme_color_override("font_color", Color(0.65, 0.88, 0.96))
	vehicle_caption.visible = false
	canvas.add_child(vehicle_caption)
	weather_label = Label.new()
	weather_label.position = Vector2(22.0, 22.0)
	weather_label.add_theme_color_override("font_color", Color(0.79, 0.94, 0.95))
	weather_label.add_theme_font_size_override("font_size", 13)
	canvas.add_child(weather_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(68, 7)
	health_bar.max_value = 100.0
	health_bar.show_percentage = false
	var health_track := StyleBoxFlat.new()
	health_track.bg_color = Color(0.12, 0.035, 0.1, 0.95)
	health_track.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("background", health_track)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(1.0, 0.36, 0.57)
	health_fill.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(health_bar)
	hover_panel = PanelContainer.new()
	hover_panel.visible = false
	hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_panel.z_index = 20
	_style_glass_panel(hover_panel, Color(0.38, 0.92, 0.87))
	hover_label = Label.new()
	hover_label.add_theme_font_size_override("font_size", 13)
	hover_label.add_theme_color_override("font_color", Color(0.88, 1.0, 0.98))
	hover_panel.add_child(hover_label)
	canvas.add_child(hover_panel)
	_create_quick_slots(canvas)

	var radio_control := Button.new()
	radio_control.text = "RADIO"
	radio_control.icon = RADIO_ART
	radio_control.expand_icon = true
	radio_control.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	radio_control.offset_left = -204.0
	radio_control.offset_right = -112.0
	radio_control.offset_top = 20.0
	radio_control.offset_bottom = 62.0
	radio_control.pressed.connect(_toggle_radio)
	radio_control.name = "RadioButton"
	radio_button = radio_control
	canvas.add_child(radio_control)

	var menu_button := Button.new()
	menu_button.text = "MENU"
	menu_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	menu_button.offset_left = -106.0
	menu_button.offset_right = -20.0
	menu_button.offset_top = 20.0
	menu_button.offset_bottom = 62.0
	menu_button.pressed.connect(_set_pause_menu.bind(true))
	canvas.add_child(menu_button)

	prompt_panel = PanelContainer.new()
	prompt_panel.custom_minimum_size = Vector2(570, 56)
	prompt_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.position = Vector2(-285, -142)
	_style_glass_panel(prompt_panel, Color(0.40, 1.0, 0.83))
	canvas.add_child(prompt_panel)
	hint_panels.append(prompt_panel)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color(0.80, 1.0, 0.90))
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_panel.add_child(prompt_label)

	scan_panel = PanelContainer.new()
	scan_panel.custom_minimum_size = Vector2(300, 52)
	scan_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	scan_panel.position = Vector2(-150, -202)
	_style_glass_panel(scan_panel, Color(0.40, 1.0, 0.83))
	canvas.add_child(scan_panel)
	hint_panels.append(scan_panel)

	var scan_column := VBoxContainer.new()
	scan_column.add_theme_constant_override("separation", 4)
	scan_panel.add_child(scan_column)
	scan_label = Label.new()
	scan_label.text = "ANALYZER  |  HOLD LEFT CLICK TO SCAN"
	scan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scan_label.add_theme_color_override("font_color", Color(0.68, 1.0, 0.91))
	scan_label.add_theme_font_size_override("font_size", 12)
	scan_column.add_child(scan_label)
	scan_bar = ProgressBar.new()
	scan_bar.custom_minimum_size = Vector2(264, 7)
	scan_bar.max_value = SCAN_SECONDS
	scan_bar.show_percentage = false
	var scan_track := StyleBoxFlat.new()
	scan_track.bg_color = Color(0.035, 0.18, 0.23)
	scan_track.set_corner_radius_all(4)
	scan_bar.add_theme_stylebox_override("background", scan_track)
	var scan_fill := StyleBoxFlat.new()
	scan_fill.bg_color = Color(0.33, 1.0, 0.78)
	scan_fill.set_corner_radius_all(4)
	scan_bar.add_theme_stylebox_override("fill", scan_fill)
	scan_column.add_child(scan_bar)
	_update_hint_visibility()

func _create_quick_slots(canvas: CanvasLayer) -> void:
	var quick_bar := PanelContainer.new()
	quick_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	quick_bar.position = Vector2(-166.0, -68.0)
	_style_glass_panel(quick_bar, Color(0.40, 1.0, 0.83))
	canvas.add_child(quick_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	quick_bar.add_child(row)
	for index in range(QUICK_SLOT_COUNT):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(52.0, 52.0)
		slot.tooltip_text = "Quick slot %d" % (index + 1)
		slot.pressed.connect(_select_quick_slot.bind(index))
		row.add_child(slot)
		quick_slot_buttons.append(slot)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(34.0, 34.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		icon.position = Vector2(-17.0, -17.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		quick_slot_icons.append(icon)
		var hotkey := Label.new()
		hotkey.text = str(index + 1)
		hotkey.position = Vector2(3.0, 1.0)
		hotkey.add_theme_font_size_override("font_size", 10)
		hotkey.add_theme_color_override("font_color", Color(0.72, 0.96, 0.90))
		hotkey.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(hotkey)
	_refresh_quick_slots()

func _create_inventory_window() -> void:
	inventory_overlay = ColorRect.new()
	inventory_overlay.color = Color(0.005, 0.025, 0.065, 0.82)
	inventory_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_overlay.visible = false
	inventory_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_canvas.add_child(inventory_overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300.0
	panel.offset_right = 300.0
	panel.offset_top = -255.0
	panel.offset_bottom = 255.0
	_style_glass_panel(panel, Color(0.40, 1.0, 0.83))
	inventory_overlay.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var heading := HBoxContainer.new()
	layout.add_child(heading)
	var title := Label.new()
	title.text = "DIVE INVENTORY"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.89))
	heading.add_child(title)
	var close_button := Button.new()
	close_button.text = "CLOSE  [TAB]"
	close_button.pressed.connect(_toggle_inventory.bind(false))
	heading.add_child(close_button)

	var subtitle := Label.new()
	subtitle.text = "Recovered materials and samples"
	subtitle.add_theme_color_override("font_color", Color(0.70, 0.85, 0.91))
	layout.add_child(subtitle)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 6
	inventory_grid.add_theme_constant_override("h_separation", 8)
	inventory_grid.add_theme_constant_override("v_separation", 8)
	layout.add_child(inventory_grid)

	for index in range(INVENTORY_SLOT_COUNT):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(76.0, 76.0)
		slot.mouse_entered.connect(_on_inventory_slot_hover.bind(index))
		slot.mouse_exited.connect(_clear_inventory_tooltip)
		slot.pressed.connect(_pin_inventory_item.bind(index))
		inventory_grid.add_child(slot)
		inventory_slots.append(slot)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(46.0, 46.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		icon.position = Vector2(-23.0, -25.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		inventory_icon_nodes.append(icon)
		var amount := Label.new()
		amount.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		amount.offset_left = -30.0
		amount.offset_top = -20.0
		amount.offset_right = -4.0
		amount.offset_bottom = -2.0
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		amount.add_theme_font_size_override("font_size", 13)
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(amount)
		inventory_count_labels.append(amount)

	inventory_status = Label.new()
	inventory_status.text = "Hover a sample to inspect it; click one to pin it to the selected quick slot."
	inventory_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_status.custom_minimum_size.y = 32.0
	inventory_status.add_theme_color_override("font_color", Color(0.81, 0.91, 0.95))
	layout.add_child(inventory_status)

	inventory_tooltip = PanelContainer.new()
	inventory_tooltip.visible = false
	inventory_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_tooltip.z_index = 30
	_style_glass_panel(inventory_tooltip, Color(0.73, 0.91, 1.0))
	hud_canvas.add_child(inventory_tooltip)
	inventory_tooltip_label = Label.new()
	inventory_tooltip_label.custom_minimum_size = Vector2(220.0, 0.0)
	inventory_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_tooltip_label.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	inventory_tooltip.add_child(inventory_tooltip_label)
	inventory_slot_resources.resize(INVENTORY_SLOT_COUNT)
	inventory_slot_resources.fill("")
	_refresh_inventory_window()

func _toggle_inventory(open: bool) -> void:
	if open:
		crafting_overlay.visible = false
		radio_panel.visible = false
		pause_menu_open = false
		pause_overlay.visible = false
	inventory_open = open
	inventory_overlay.visible = open
	inventory_tooltip.visible = false
	get_tree().paused = open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if open:
		_refresh_inventory_window()
	else:
		inventory_hovered_resource = ""
		_clear_analyzer_beam()
	_refresh_hud()

func _refresh_inventory_window() -> void:
	if inventory_slots.is_empty():
		return
	inventory_slot_resources.fill("")
	var slot_index := 0
	for resource_id in inventory:
		var quantity := int(inventory[resource_id])
		if quantity <= 0 or slot_index >= INVENTORY_SLOT_COUNT:
			continue
		inventory_slot_resources[slot_index] = resource_id
		inventory_icon_nodes[slot_index].texture = _resource_icon(resource_id)
		inventory_count_labels[slot_index].text = str(quantity)
		inventory_slots[slot_index].tooltip_text = _resource_name(resource_id)
		slot_index += 1
	for index in range(slot_index, INVENTORY_SLOT_COUNT):
		inventory_icon_nodes[index].texture = null
		inventory_count_labels[index].text = ""
		inventory_slots[index].tooltip_text = "Empty"
	_refresh_quick_slots()

func _resource_icon(resource_id: String) -> Texture2D:
	if resource_id == "driftmetal":
		return DRIFTMETAL_ART
	if resource_id == "lumen_kelp":
		return LUMEN_KELP_ART
	for species_data in SPECIES:
		if species_data.resource == resource_id:
			var atlas := AtlasTexture.new()
			atlas.atlas = LIFE_ATLAS
			atlas.region = species_data.region
			return atlas
	return null

func _on_inventory_slot_hover(index: int) -> void:
	var resource_id := inventory_slot_resources[index]
	inventory_hovered_resource = resource_id
	if resource_id.is_empty():
		inventory_tooltip.visible = false
		return
	inventory_tooltip_label.text = _inventory_item_details(resource_id)
	inventory_tooltip.visible = true
	call_deferred("_update_inventory_tooltip_position")

func _clear_inventory_tooltip() -> void:
	inventory_hovered_resource = ""
	if inventory_tooltip != null:
		inventory_tooltip.visible = false

func _update_inventory_tooltip_position() -> void:
	if not inventory_tooltip.visible:
		return
	var viewport_size := get_viewport_rect().size
	var tooltip_size := inventory_tooltip.size
	var tooltip_position := get_viewport().get_mouse_position() + Vector2(18.0, 18.0)
	tooltip_position.x = minf(tooltip_position.x, viewport_size.x - tooltip_size.x - 8.0)
	tooltip_position.y = minf(tooltip_position.y, viewport_size.y - tooltip_size.y - 8.0)
	inventory_tooltip.position = tooltip_position

func _inventory_item_details(resource_id: String) -> String:
	if resource_id == "driftmetal":
		return "DRIFTMETAL\nCOMMON SALVAGE\nRich in conductive metals; useful for pressure-safe equipment."
	if resource_id == "lumen_kelp":
		return "LUMEN KELP\nCOMMON FLORA\nA faintly glowing, flexible fiber used in surface technology."
	for species_data in SPECIES:
		if species_data.resource != resource_id:
			continue
		if not _resource_source_scanned(resource_id):
			return "%s\nUNANALYZED SAMPLE\nScan a living specimen to reveal its traits." % _resource_name(resource_id).to_upper()
		var temperament := "Aggressive hunter" if species_data.aggressive else "Non-aggressive"
		var rarity := _resource_rarity(resource_id)
		var behavior := _flora_behavior_description(species_data) if species_data.kind == "flora" else "Drifts through the water column."
		return "%s\n%s  •  %s\n%s\n%s" % [
			species_data.name.to_upper(),
			rarity,
			temperament.to_upper(),
			behavior,
			"Sample source: %s." % _resource_name(resource_id)
		]
	return "%s\nRECOVERED MATERIAL\nThe sample's composition has not been catalogued." % _resource_name(resource_id).to_upper()

func _resource_source_scanned(resource_id: String) -> bool:
	for lifeform in lifeforms:
		if lifeform.resource_id == resource_id and lifeform.scanned:
			return true
	return false

func _resource_rarity(resource_id: String) -> String:
	match resource_id:
		"moon_mucus", "ribbon_silk", "ember_kelp", "veil_moss":
			return "UNCOMMON"
		"shell_plate", "electric_filament", "spire_coral", "abyssal_bloom":
			return "RARE"
		_:
			return "COMMON"

func _flora_behavior_description(species_data: Dictionary) -> String:
	match String(species_data.get("flora_behavior", "")):
		"sway":
			return "Sways with the current and releases warm spores."
		"creep":
			return "Slowly creeps along the rock, filtering the water."
		"stalk":
			return "A hunting coral that stalks nearby movement."
		"pulse":
			return "Pulses with light to attract small drifting organisms."
		_:
			return "Rooted alien flora."

func _pin_inventory_item(index: int) -> void:
	var resource_id := inventory_slot_resources[index]
	if resource_id.is_empty():
		return
	quick_slot_resources[selected_quick_slot] = resource_id
	inventory_status.text = "%s pinned to quick slot %d." % [
		_resource_name(resource_id),
		selected_quick_slot + 1
	]
	_refresh_quick_slots()

func _select_quick_slot(index: int) -> void:
	selected_quick_slot = index
	_refresh_quick_slots()

func _refresh_quick_slots() -> void:
	if quick_slot_buttons.is_empty():
		return
	for index in range(QUICK_SLOT_COUNT):
		var resource_id := quick_slot_resources[index]
		if not resource_id.is_empty() and int(inventory.get(resource_id, 0)) <= 0:
			quick_slot_resources[index] = ""
			resource_id = ""
		quick_slot_icons[index].texture = (
			_resource_icon(resource_id) if not resource_id.is_empty() else null
		)
		quick_slot_buttons[index].modulate = (
			Color(1.0, 1.0, 1.0)
			if index == selected_quick_slot
			else Color(0.65, 0.75, 0.82)
		)
		quick_slot_buttons[index].tooltip_text = (
			"%d — %s" % [index + 1, _resource_name(resource_id)]
			if not resource_id.is_empty()
			else "Quick slot %d — empty" % (index + 1)
		)
	for resource_id in inventory:
		if int(inventory[resource_id]) <= 0 or quick_slot_resources.has(resource_id):
			continue
		var empty_index := quick_slot_resources.find("")
		if empty_index < 0:
			break
		quick_slot_resources[empty_index] = resource_id
		quick_slot_icons[empty_index].texture = _resource_icon(resource_id)
		quick_slot_buttons[empty_index].tooltip_text = "%d — %s" % [
			empty_index + 1,
			_resource_name(resource_id)
		]
		quick_slot_buttons[empty_index].modulate = (
			Color(1.0, 1.0, 1.0)
			if empty_index == selected_quick_slot
			else Color(0.65, 0.75, 0.82)
		)

func _create_crafting_window() -> void:
	crafting_overlay = ColorRect.new()
	crafting_overlay.color = Color(0.008, 0.027, 0.075, 0.82)
	crafting_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crafting_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	crafting_overlay.visible = false
	hud_canvas.add_child(crafting_overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -440.0
	panel.offset_right = 440.0
	panel.offset_top = -310.0
	panel.offset_bottom = 310.0
	_style_glass_panel(panel, Color(0.33, 1.0, 0.81))
	crafting_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var heading := HBoxContainer.new()
	layout.add_child(heading)
	var title := Label.new()
	title.text = "FIELD TECHNOLOGY BENCH"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.87))
	title.add_theme_font_size_override("font_size", 25)
	heading.add_child(title)
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.pressed.connect(_toggle_crafting_window.bind(false))
	heading.add_child(close_button)

	recipe_details = Label.new()
	recipe_details.custom_minimum_size.y = 44.0
	recipe_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_details.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0))
	layout.add_child(recipe_details)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	recipe_list = VBoxContainer.new()
	recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list.add_theme_constant_override("separation", 8)
	scroll.add_child(recipe_list)

	var footer := Label.new()
	footer.text = "Hold LEFT CLICK to analyze life in the beam. Scan a new species to reveal its technology."
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_color_override("font_color", Color(0.48, 0.84, 0.86))
	layout.add_child(footer)

func _refresh_crafting_window() -> void:
	if recipe_list == null:
		return
	for child in recipe_list.get_children():
		child.queue_free()
	for recipe_id in RECIPES:
		var recipe: Dictionary = RECIPES[recipe_id]
		var recipe_scanned := unlocked_recipes.has(recipe_id)
		var recipe_known := _recipe_is_revealed(recipe_id)
		var card := PanelContainer.new()
		_style_glass_panel(
			card,
			Color(0.55, 0.58, 0.67)
			if not recipe_known
			else Color(0.94, 0.28, 0.34)
			if not _has_recipe_materials(recipe)
			else Color(0.31, 0.88, 0.88)
		)
		recipe_list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var technology_icon := TextureRect.new()
		technology_icon.custom_minimum_size = Vector2(76.0, 76.0)
		technology_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		technology_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		technology_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		if recipe_scanned or recipe_id == "pressure_weave":
			var technology_atlas := AtlasTexture.new()
			technology_atlas.atlas = TECHNOLOGY_ICONS
			technology_atlas.region = TECHNOLOGY_ICON_REGIONS[recipe_id]
			technology_icon.texture = technology_atlas
		row.add_child(technology_icon)
		if not recipe_scanned and recipe_id != "pressure_weave":
			var unknown_mark := Label.new()
			unknown_mark.text = "?"
			unknown_mark.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			unknown_mark.offset_left = -18.0
			unknown_mark.offset_right = 18.0
			unknown_mark.offset_top = -25.0
			unknown_mark.offset_bottom = 25.0
			unknown_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			unknown_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			unknown_mark.add_theme_font_size_override("font_size", 32)
			unknown_mark.add_theme_color_override("font_color", Color(0.72, 0.77, 0.86))
			technology_icon.add_child(unknown_mark)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_button := Button.new()
		name_button.text = (
			recipe.title
			if recipe_scanned
			else "Pressure-weave suit"
			if recipe_id == "pressure_weave"
			else "UNDISCOVERED TECHNOLOGY"
			if not recipe_known
			else "UNIDENTIFIED RESEARCH LEAD"
		)
		name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_button.flat = true
		name_button.add_theme_font_size_override("font_size", 18)
		name_button.add_theme_color_override(
			"font_color",
			Color(0.58, 1.0, 0.86)
			if recipe_scanned or recipe_id == "pressure_weave"
			else Color(0.94, 0.36, 0.42)
			if recipe_known and not _has_recipe_materials(recipe)
			else Color(0.68, 0.71, 0.79)
		)
		name_button.pressed.connect(_select_recipe.bind(recipe_id))
		info.add_child(name_button)

		var scan_description: String = (
			recipe.description
			if recipe_scanned
			else "Research incomplete. Analyze related alien life to identify this technology."
			if recipe_known
			else "Unknown"
		)
		var description := Label.new()
		description.text = scan_description
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_color_override(
			"font_color",
			Color(0.84, 0.92, 0.89)
			if recipe_scanned
			else Color(0.72, 0.46, 0.50)
			if recipe_known and not _has_recipe_materials(recipe)
			else Color(0.66, 0.69, 0.75)
		)
		info.add_child(description)

		if recipe_scanned or recipe_id == "pressure_weave":
			var ingredients := Label.new()
			ingredients.text = _format_recipe_cost(recipe.cost)
			ingredients.add_theme_color_override("font_color", Color(1.0, 0.79, 0.49))
			info.add_child(ingredients)
		elif recipe_known:
			var ingredients := Label.new()
			ingredients.text = _format_discovered_recipe_cost(recipe.cost)
			ingredients.add_theme_color_override("font_color", Color(0.71, 0.74, 0.81))
			info.add_child(ingredients)

		var craft_button := Button.new()
		var enough_materials := _has_recipe_materials(recipe)
		var already_built := _is_technology_built(recipe_id)
		if already_built:
			craft_button.text = "INSTALLED"
			craft_button.disabled = true
		elif not recipe_known:
			craft_button.text = "UNKNOWN"
			craft_button.disabled = true
		elif not recipe_scanned and recipe_id != "pressure_weave":
			craft_button.text = "SCAN TO IDENTIFY"
			craft_button.disabled = true
		elif enough_materials:
			craft_button.text = "CRAFT"
			craft_button.pressed.connect(_craft_recipe.bind(recipe_id))
		else:
			craft_button.text = "MISSING MATERIALS"
			craft_button.disabled = true
		if recipe_known and not enough_materials:
			craft_button.add_theme_color_override("font_color", Color(1.0, 0.39, 0.45))
		row.add_child(craft_button)

	if not RECIPES.has(selected_recipe):
		selected_recipe = "pressure_weave"
	recipe_details.text = _recipe_detail_text(selected_recipe)

func _recipe_is_revealed(recipe_id: String) -> bool:
	if unlocked_recipes.has(recipe_id):
		return true
	var recipe: Dictionary = RECIPES[recipe_id]
	for resource_id in recipe.cost:
		if discovered_materials.has(resource_id):
			return true
	return false

func _format_discovered_recipe_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for resource_id in cost:
		if discovered_materials.has(resource_id):
			parts.append("%s × %d" % [_resource_name(resource_id), int(cost[resource_id])])
	if parts.is_empty():
		return "No components identified yet."
	return "KNOWN COMPONENTS  " + "   ·   ".join(parts)

func _recipe_detail_text(recipe_id: String) -> String:
	if not _recipe_is_revealed(recipe_id):
		return "UNDISCOVERED TECHNOLOGY\nNo research data recovered."
	var recipe: Dictionary = RECIPES[recipe_id]
	if not unlocked_recipes.has(recipe_id):
		return "PARTIAL RESEARCH\n%s" % _format_discovered_recipe_cost(recipe.cost)
	var status := "READY TO BUILD"
	if _is_technology_built(recipe_id):
		status = "INSTALLED"
	elif not _has_recipe_materials(recipe):
		status = "MISSING: %s" % _format_recipe_cost(recipe.cost)
	return "%s  •  %s" % [status, recipe.description]

func _create_radio_panel() -> void:
	radio_panel = PanelContainer.new()
	radio_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	radio_panel.offset_left = -390.0
	radio_panel.offset_right = -20.0
	radio_panel.offset_top = 72.0
	radio_panel.offset_bottom = 184.0
	radio_panel.visible = false
	_style_glass_panel(radio_panel, Color(1.0, 0.70, 0.38))
	hud_canvas.add_child(radio_panel)
	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(330, 75)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.73))
	status_label.add_theme_font_size_override("font_size", 15)
	radio_panel.add_child(status_label)

func _toggle_radio() -> void:
	radio_panel.visible = not radio_panel.visible
	if radio_panel.visible:
		status_label.text = story_message
		if radio_panel.visible:
			status_label.text = story_message

func _create_pause_menu() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.0, 0.012, 0.04, 0.68)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_canvas.add_child(pause_overlay)

	menu_pattern = TextureRect.new()
	menu_pattern.texture = MENU_OCEAN_ART
	menu_pattern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_pattern.stretch_mode = TextureRect.STRETCH_SCALE
	menu_pattern.modulate = Color(0.72, 0.90, 0.95, 0.80)
	menu_pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_overlay.add_child(menu_pattern)
	pause_panel = PanelContainer.new()
	_style_menu_panel(pause_panel)
	pause_overlay.add_child(pause_panel)
	pause_scroll = ScrollContainer.new()
	pause_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pause_panel.add_child(pause_scroll)
	pause_content = VBoxContainer.new()
	pause_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_content.add_theme_constant_override("separation", 12)
	pause_scroll.add_child(pause_content)
	confirm_exit_dialog = ConfirmationDialog.new()
	confirm_exit_dialog.title = "Save and exit?"
	confirm_exit_dialog.dialog_text = "Save your current progress and close Under Pressure?"
	confirm_exit_dialog.ok_button_text = "SAVE AND EXIT"
	confirm_exit_dialog.confirmed.connect(_save_and_exit)
	pause_overlay.add_child(confirm_exit_dialog)
	_show_pause_menu()

func _set_pause_menu(open: bool) -> void:
	pause_menu_open = open
	settings_panel_visible = false
	if open:
		crafting_overlay.visible = false
		radio_panel.visible = false
		_show_pause_menu()
		pause_overlay.visible = true
	else:
		awaiting_keybinding = ""
		pause_overlay.visible = false
	get_tree().paused = open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_hud()

func _show_pause_menu() -> void:
	_layout_menu_panel(false)
	_clear_pause_content()
	_add_menu_title(pause_content, "UNDER PRESSURE")
	var subtitle := Label.new()
	subtitle.text = "DIVE MENU"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.57, 0.88, 0.94))
	pause_content.add_child(subtitle)
	_add_menu_button("CONTINUE", _set_pause_menu.bind(false))
	_add_menu_button("SAVE GAME", _save_from_menu)
	_add_menu_button("LOAD GAME", _load_from_menu)
	_add_menu_button("SETTINGS", _show_settings.bind(true))
	_add_menu_button("SAVE AND EXIT", _request_save_and_exit)
	pause_message = Label.new()
	pause_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_message.add_theme_color_override("font_color", Color(0.83, 0.91, 0.95))
	pause_content.add_child(pause_message)

func _show_settings(open: bool) -> void:
	settings_panel_visible = open
	if not open:
		_show_pause_menu()
		return
	_layout_menu_panel(true)
	_clear_pause_content()
	_add_menu_title(pause_content, "FIELD SETTINGS")
	var heading := HBoxContainer.new()
	pause_content.add_child(heading)
	var title := Label.new()
	title.text = "SETTINGS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.89))
	heading.add_child(title)
	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(_show_settings.bind(false))
	heading.add_child(back)

	_add_settings_label("RESOLUTION")
	var resolution_option := OptionButton.new()
	for resolution in RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [resolution.x, resolution.y])
		resolution_option.set_item_metadata(resolution_option.item_count - 1, resolution)
		if resolution == settings_data["resolution"]:
			resolution_option.select(resolution_option.item_count - 1)
	resolution_option.item_selected.connect(_on_resolution_selected.bind(resolution_option))
	pause_content.add_child(resolution_option)

	_add_settings_label("MASTER VOLUME")
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = settings_data["master_volume"]
	volume_slider.value_changed.connect(_on_volume_changed)
	pause_content.add_child(volume_slider)

	_add_settings_label("AUTOSAVE")
	var autosave_option := OptionButton.new()
	var interval_labels := {
		0: "Off",
		30: "Every 30 seconds",
		60: "Every 1 minute",
		300: "Every 5 minutes",
		600: "Every 10 minutes",
		900: "Every 15 minutes",
		1800: "Every 30 minutes"
	}
	for interval in AUTOSAVE_INTERVALS:
		autosave_option.add_item(interval_labels[interval])
		autosave_option.set_item_metadata(autosave_option.item_count - 1, interval)
		if int(settings_data["autosave_interval"]) == interval:
			autosave_option.select(autosave_option.item_count - 1)
	autosave_option.item_selected.connect(_on_autosave_selected.bind(autosave_option))
	pause_content.add_child(autosave_option)

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Fullscreen display"
	fullscreen_toggle.button_pressed = bool(settings_data["fullscreen"])
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	pause_content.add_child(fullscreen_toggle)

	var hints_toggle := CheckButton.new()
	hints_toggle.text = "Show gameplay hints beneath the diver"
	hints_toggle.button_pressed = bool(settings_data["show_gameplay_hints"])
	hints_toggle.toggled.connect(_on_hints_toggled)
	pause_content.add_child(hints_toggle)

	var divider := HSeparator.new()
	pause_content.add_child(divider)
	_add_settings_label("KEY BINDINGS")
	for action in KEY_BINDINGS:
		var row := HBoxContainer.new()
		pause_content.add_child(row)
		var action_label := Label.new()
		action_label.text = KEY_BINDINGS[action]
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(action_label)
		var bind_button := Button.new()
		bind_button.text = _action_key_text(action) if awaiting_keybinding != action else "PRESS A KEY"
		bind_button.pressed.connect(_start_keybinding.bind(action))
		row.add_child(bind_button)
	var mouse_controls := Label.new()
	mouse_controls.text = "Analyze: hold left mouse  ·  Tranquilizer: right mouse"
	mouse_controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_controls.add_theme_color_override("font_color", Color(0.67, 0.80, 0.86))
	pause_content.add_child(mouse_controls)
	settings_message = Label.new()
	settings_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_message.add_theme_color_override("font_color", Color(1.0, 0.70, 0.58))
	pause_content.add_child(settings_message)

func _layout_menu_panel(settings_open: bool) -> void:
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_pattern.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var half_width := 465.0 if settings_open else 275.0
	var half_height := 275.0 if settings_open else 300.0
	pause_panel.offset_left = -half_width
	pause_panel.offset_right = half_width
	pause_panel.offset_top = -half_height
	pause_panel.offset_bottom = half_height
	menu_pattern.offset_left = pause_panel.offset_left
	menu_pattern.offset_right = pause_panel.offset_right
	menu_pattern.offset_top = pause_panel.offset_top
	menu_pattern.offset_bottom = pause_panel.offset_bottom

func _style_menu_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.005, 0.025, 0.065, 0.36)
	style.border_color = Color(0.38, 0.95, 1.0, 0.98)
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	style.shadow_color = Color(0.12, 0.80, 0.91, 0.38)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)

func _add_menu_title(parent: Control, title_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(0.75, 1.0, 0.98))
	parent.add_child(title)

func _clear_pause_content() -> void:
	for child in pause_content.get_children():
		child.queue_free()

func _add_menu_button(caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 42.0
	button.pressed.connect(callback)
	pause_content.add_child(button)

func _add_settings_label(caption: String) -> void:
	var label := Label.new()
	label.text = caption
	label.add_theme_color_override("font_color", Color(0.58, 0.90, 0.94))
	label.add_theme_font_size_override("font_size", 13)
	pause_content.add_child(label)

func _on_resolution_selected(index: int, option: OptionButton) -> void:
	settings_data["resolution"] = option.get_item_metadata(index)
	_apply_settings()
	_save_settings()

func _on_volume_changed(value: float) -> void:
	settings_data["master_volume"] = value
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_linear(master_bus, value)
	else:
		push_error("The Master audio bus is missing.")
	_save_settings()

func _on_autosave_selected(index: int, option: OptionButton) -> void:
	settings_data["autosave_interval"] = int(option.get_item_metadata(index))
	autosave_elapsed = 0.0
	_save_settings()

func _on_fullscreen_toggled(enabled: bool) -> void:
	settings_data["fullscreen"] = enabled
	_apply_settings()
	_save_settings()

func _on_hints_toggled(enabled: bool) -> void:
	settings_data["show_gameplay_hints"] = enabled
	_save_settings()
	_update_hint_visibility()

func _start_keybinding(action: String) -> void:
	awaiting_keybinding = action
	_show_settings(true)

func _apply_keybinding(key_event: InputEventKey) -> void:
	var action := awaiting_keybinding
	if action.is_empty():
		return
	for other_action in KEY_BINDINGS:
		if other_action == action:
			continue
		for assigned_event in InputMap.action_get_events(other_action):
			if assigned_event is InputEventKey and (assigned_event as InputEventKey).physical_keycode == key_event.physical_keycode:
				settings_message.text = "That key is already assigned to %s." % KEY_BINDINGS[other_action]
				return
	InputMap.action_erase_events(action)
	var new_event := InputEventKey.new()
	new_event.physical_keycode = key_event.physical_keycode
	InputMap.action_add_event(action, new_event)
	awaiting_keybinding = ""
	_save_settings()
	_show_settings(true)

func _action_key_text(action: String) -> String:
	var keys: Array[String] = []
	for assigned_event in InputMap.action_get_events(action):
		if assigned_event is InputEventKey:
			keys.append((assigned_event as InputEventKey).as_text_physical_keycode())
	return " / ".join(keys)

func _save_from_menu() -> void:
	pause_message.text = "Game saved." if _save_game() else "Save failed. Check the game log for details."

func _load_from_menu() -> void:
	if not FileAccess.file_exists(save_path):
		pause_message.text = "No saved game was found."
		return
	if not _load_game():
		pause_message.text = "The saved game could not be loaded. Check the game log for details."
		return
	_apply_installed_techs()
	autosave_elapsed = 0.0
	_refresh_crafting_window()
	_refresh_hud()
	pause_message.text = "Saved progress loaded."

func _request_save_and_exit() -> void:
	confirm_exit_dialog.popup_centered()

func _save_and_exit() -> void:
	if _save_game():
		get_tree().quit()
	else:
		pause_message.text = "Save failed; the game remains open."

func _toggle_crafting_window(force_state: bool) -> void:
	crafting_overlay.visible = force_state
	if force_state:
		_refresh_crafting_window()
	else:
		selected_recipe = ""
	_refresh_hud()

func _select_recipe(recipe_id: String) -> void:
	selected_recipe = recipe_id
	recipe_details.text = _recipe_detail_text(recipe_id)

func _craft_recipe(recipe_id: String) -> void:
	if not RECIPES.has(recipe_id) or not unlocked_recipes.has(recipe_id):
		return
	var recipe: Dictionary = RECIPES[recipe_id]
	if _is_technology_built(recipe_id) or not _has_recipe_materials(recipe):
		story_message = "That technology needs more analyzed organic samples."
		_refresh_crafting_window()
		return

	for resource_id in recipe.cost:
		inventory[resource_id] -= int(recipe.cost[resource_id])
	installed_techs[recipe_id] = true
	if recipe_id == "medkit":
		health = 100.0
		installed_techs.erase(recipe_id)
		story_message = "Symbiotic repair gel restores your vitals."
	else:
		story_message = "%s fabricated and installed." % recipe.title
	_apply_installed_techs()
	_save_game()
	_refresh_crafting_window()
	_refresh_hud()

func _is_technology_built(recipe_id: String) -> bool:
	if recipe_id == "pressure_weave":
		return suit_upgraded
	return installed_techs.has(recipe_id)

func _has_recipe_materials(recipe: Dictionary) -> bool:
	for resource_id in recipe.cost:
		if int(inventory.get(resource_id, 0)) < int(recipe.cost[resource_id]):
			return false
	return true

func _format_recipe_cost(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for resource_id in cost:
		parts.append("%s × %d" % [_resource_name(resource_id), int(cost[resource_id])])
	return "USES  " + "   ·   ".join(parts)

func _resource_name(resource_id: String) -> String:
	var names := {
		"driftmetal": "Driftmetal",
		"lumen_kelp": "Lumen kelp",
		"moon_mucus": "Moon-jelly mucus",
		"ribbon_silk": "Ribbon silk",
		"shell_plate": "Glassback plate",
		"electric_filament": "Live filament",
		"ember_kelp": "Ember kelp",
		"veil_moss": "Veil moss",
		"spire_coral": "Spire coral",
		"abyssal_bloom": "Lantern-bloom core"
	}
	return names.get(resource_id, resource_id)

func _apply_installed_techs() -> void:
	suit_upgraded = installed_techs.has("pressure_weave")
	depth_limit = STARTING_DEPTH_LIMIT
	oxygen_capacity = STARTING_OXYGEN
	diver.depth_limit = depth_limit
	diver.movement_speed = OceanDiver.MOVE_SPEED
	diver.has_fins = false
	diver.has_submersible = false
	if suit_upgraded:
		depth_limit = UPGRADED_DEPTH_LIMIT
	if installed_techs.has("deep_tank"):
		depth_limit = SUIT_DEPTH_LIMIT
		oxygen_capacity = 230.0
	if installed_techs.has("submersible"):
		depth_limit = SUB_DEPTH_LIMIT
	if installed_techs.has("fins"):
		diver.movement_speed = OceanDiver.MOVE_SPEED * 1.42
		diver.has_fins = true
	diver.fins_sprite.visible = installed_techs.has("fins")
	diver.helmet_sprite.visible = installed_techs.has("deep_tank")
	if installed_techs.has("submersible"):
		diver.movement_speed *= 1.2
		diver.has_submersible = true
	diver.submersible_sprite.visible = diver.has_submersible
	diver.depth_limit = depth_limit
	oxygen = minf(oxygen_capacity, oxygen)
	if installed_techs.has("lamp") and lamp_light == null:
		lamp_light = PointLight2D.new()
		lamp_light.texture = LAMP_GLOW
		lamp_light.texture_scale = 1.0
		lamp_light.energy = 1.2
		lamp_light.color = Color(0.65, 0.91, 1.0)
		lamp_light.z_index = 6
		diver.add_child(lamp_light)
	if lamp_light != null:
		lamp_light.visible = installed_techs.has("lamp")

func _style_glass_panel(panel: PanelContainer, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.006, 0.035, 0.075, 0.70)
	style.border_color = Color(0.18, 0.70, 0.89, 0.68).lerp(accent, 0.24)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.shadow_color = Color(0.0, 0.035, 0.09, 0.55)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)

func _create_atmosphere() -> void:
	world_tint = CanvasModulate.new()
	world_tint.color = Color.WHITE
	add_child(world_tint)

func _refresh_hud() -> void:
	if status_label == null:
		return

	var depth := maxf(0.0, diver.global_position.y - 77.0)
	depth_label.text = "DEPTH  %03d m     RATING  %03d m" % [roundi(depth), roundi(depth_limit)]
	oxygen_bar.value = oxygen
	oxygen_bar.max_value = oxygen_capacity
	oxygen_fill_style.bg_color = (
		Color(1.0, 0.34, 0.36)
		if oxygen <= oxygen_capacity * 0.25
		else Color(1.0, 0.72, 0.36)
		if oxygen <= STARTING_OXYGEN * 0.5
		else Color(0.18, 0.92, 0.78)
	)
	health_bar.value = health
	var player_screen_position := get_viewport().get_canvas_transform() * diver.global_position
	health_bar.position = player_screen_position + Vector2(-34.0, health_bar_offset.y)
	vehicle_bar.visible = diver.has_submersible
	vehicle_caption.visible = diver.has_submersible
	vehicle_bar.value = diver.vehicle_health
	_refresh_quick_slots()
	status_label.text = story_message

	var nearby := _nearest_interactable()
	if nearby is AlienLifeform:
		var nearby_lifeform := nearby as AlienLifeform
		prompt_label.text = "[E]  Sample %s" % nearby_lifeform.specimen_name
	elif nearby is SalvagePickup:
		var nearby_pickup := nearby as SalvagePickup
		prompt_label.text = "[E]  Collect %s" % nearby_pickup.title
	elif diver.global_position.y <= 145.0 and absf(diver.global_position.x + 185.0) <= 130.0:
		prompt_label.text = "[F]  Open field technology bench"
	elif depth > depth_limit:
		prompt_label.text = "PRESSURE STRESS  Oxygen use and hull damage are increasing."
	elif depth >= depth_limit - 2.0:
		prompt_label.text = "PRESSURE RATING REACHED  Deeper water drains oxygen faster."
	elif oxygen_empty_time > 0.0:
		prompt_label.text = "OXYGEN DEPLETED  Emergency return in progress..."
	elif health <= 25.0:
		prompt_label.text = "VITALS CRITICAL  Flee or craft Symbiotic repair gel."
	else:
		prompt_label.text = ""
	prompt_label.get_parent().visible = not prompt_label.text.is_empty()
	if crafting_overlay.visible or inventory_open:
		prompt_label.get_parent().visible = false
	_update_hint_visibility()

func _update_hint_visibility() -> void:
	var show_hints := bool(settings_data.get("show_gameplay_hints", false))
	for hint_panel in hint_panels:
		hint_panel.visible = show_hints and not crafting_overlay.visible and not inventory_open

func _update_world_hover() -> void:
	if get_tree().paused or inventory_open or crafting_overlay.visible:
		hover_panel.visible = false
		return
	var mouse_world := get_global_mouse_position()
	var hover_name := ""
	var nearest_distance := INF
	for lifeform in lifeforms:
		if lifeform.harvested:
			continue
		var distance := mouse_world.distance_to(lifeform.global_position)
		if distance < 66.0 and distance < nearest_distance:
			nearest_distance = distance
			hover_name = lifeform.specimen_name if lifeform.scanned else "Unknown"
	for pickup in pickups:
		if pickup.collected:
			continue
		var distance := mouse_world.distance_to(pickup.global_position)
		if distance < 44.0 and distance < nearest_distance:
			nearest_distance = distance
			var is_known_pickup := (
				discovered_materials.has(pickup.category)
				or (pickup.category == "story" and signal_found)
			)
			hover_name = pickup.title if is_known_pickup else "Unknown"
	if hover_name.is_empty():
		hover_panel.visible = false
		return
	hover_label.text = hover_name
	hover_panel.visible = true
	var mouse_screen := get_viewport().get_mouse_position() + Vector2(18.0, 18.0)
	var viewport_size := get_viewport_rect().size
	var tooltip_size := hover_panel.size
	hover_panel.position = Vector2(
		minf(mouse_screen.x, viewport_size.x - tooltip_size.x - 8.0),
		minf(mouse_screen.y, viewport_size.y - tooltip_size.y - 8.0)
	)

func _create_analyzer_beam() -> void:
	analyzer_beam = MeshInstance2D.new()
	analyzer_beam.name = "SoftAnalyzerBeam"
	analyzer_beam.z_index = 6
	analyzer_mesh = ArrayMesh.new()
	analyzer_beam.mesh = analyzer_mesh
	var beam_material := CanvasItemMaterial.new()
	beam_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	analyzer_beam.material = beam_material
	add_child(analyzer_beam)

func _update_analyzer(delta: float) -> void:
	if crafting_overlay.visible or inventory_open:
		_clear_analyzer_beam()
		scan_target = null
		scan_progress = 0.0
		scan_bar.value = 0.0
		scan_label.text = "TECH BENCH OPEN"
		return

	var start := diver.global_position + Vector2(0, -8)
	var mouse_world := get_global_mouse_position()
	var direction := (mouse_world - start).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	_draw_analyzer_cone(start, direction)

	var is_scanning := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var target := _target_in_cone(start, direction)
	analyzer_beam.modulate = (
		Color(0.91, 1.0, 0.62, 1.0)
		if is_scanning and target != null
		else Color(0.83, 1.0, 0.55, 0.84)
	)
	if not is_scanning or target == null or scan_cooldown > 0.0:
		scan_target = null
		scan_progress = 0.0
		scan_bar.value = 0.0
		scan_label.text = (
			"ANALYZER  |  %s" % target.specimen_name
			if target != null
			else "ANALYZER  |  HOLD LEFT CLICK TO SCAN"
		)
		return

	if scan_target != target:
		scan_target = target
		scan_progress = 0.0
	_advance_scan(target, delta)

func _draw_analyzer_cone(start: Vector2, direction: Vector2) -> void:
	var origin := to_local(start)
	var angle_steps := 24
	var distance_steps := 8
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var half_angle := deg_to_rad(ANALYZER_HALF_ANGLE)
	for distance_index in range(distance_steps + 1):
		var distance_ratio := float(distance_index) / distance_steps
		var distance_fade := pow(maxf(0.0, sin(distance_ratio * PI)), 0.72)
		for angle_index in range(angle_steps + 1):
			var side_ratio := float(angle_index) / angle_steps * 2.0 - 1.0
			var edge_fade := pow(maxf(0.0, 1.0 - absf(side_ratio)), 0.85)
			var ray := direction.rotated(side_ratio * half_angle)
			var point := origin + ray * ANALYZER_RANGE * distance_ratio
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(Color(0.72, 1.0, 0.31, 0.24 * edge_fade * distance_fade))
	for distance_index in range(distance_steps):
		for angle_index in range(angle_steps):
			var current := distance_index * (angle_steps + 1) + angle_index
			var next_row := current + angle_steps + 1
			indices.append_array(PackedInt32Array([
				current, current + 1, next_row,
				current + 1, next_row + 1, next_row
			]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	analyzer_mesh.clear_surfaces()
	analyzer_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func _clear_analyzer_beam() -> void:
	if analyzer_mesh != null:
		analyzer_mesh.clear_surfaces()

func _advance_scan(target: AlienLifeform, delta: float) -> void:
	if target.harvested or target.scanned:
		scan_target = null
		scan_progress = 0.0
		scan_bar.value = 0.0
		return
	if scan_target != target:
		scan_target = target
		scan_progress = 0.0
	scan_progress = minf(SCAN_SECONDS, scan_progress + delta)
	scan_bar.value = scan_progress
	scan_label.text = "ANALYZING  %s  %d%%" % [
		target.specimen_name.to_upper(),
		roundi(scan_progress / SCAN_SECONDS * 100.0)
	]
	if scan_progress >= SCAN_SECONDS:
		_complete_scan(target)

func _complete_scan(target: AlienLifeform) -> void:
	target.scanned = true
	unlocked_recipes[target.recipe_id] = true
	scan_cooldown = 0.35
	story_message = "%s analyzed. New technology data recovered: %s." % [
		target.specimen_name,
		RECIPES[target.recipe_id].title
	]
	selected_recipe = target.recipe_id
	_save_game()
	_refresh_crafting_window()
	_refresh_hud()

func _target_on_beam(start: Vector2, end: Vector2, require_unscanned := true) -> AlienLifeform:
	var direction := (end - start).normalized()
	if direction.is_zero_approx():
		return null
	return _target_in_cone(start, direction, require_unscanned)

func _target_in_cone(start: Vector2, direction: Vector2, require_unscanned := true) -> AlienLifeform:
	var target: AlienLifeform
	var nearest_score := INF
	for lifeform in lifeforms:
		if lifeform.harvested or (require_unscanned and lifeform.scanned):
			continue
		var offset := lifeform.global_position - start
		var distance := offset.length()
		var angle := absf(direction.angle_to(offset.normalized()))
		if (
			distance <= ANALYZER_RANGE
			and angle <= deg_to_rad(ANALYZER_HALF_ANGLE) + 0.035
		):
			var score := distance * cos(angle)
			if score < nearest_score:
				nearest_score = score
				target = lifeform
	return target

func _fire_dart() -> void:
	if not installed_techs.has("tranquilizer") or dart_cooldown > 0.0:
		return
	var start := diver.global_position
	var mouse_world := get_global_mouse_position()
	var end := start + (mouse_world - start).normalized() * minf(
		(mouse_world - start).length(),
		ANALYZER_RANGE
	)
	var target := _target_on_beam(start, end, false)
	_fire_dart_at(target)

func _fire_dart_at(target: AlienLifeform) -> void:
	if not installed_techs.has("tranquilizer") or dart_cooldown > 0.0:
		return
	if target == null:
		story_message = "No specimen in dart range."
	elif not target.aggressive:
		story_message = "Darts only disable hostile life."
	else:
		target.stun()
		story_message = "Dreamspore dart hit. Riftstalker stunned."
	dart_cooldown = 0.8
	_refresh_hud()

func _nearest_interactable() -> Node2D:
	var nearest: Node2D
	var nearest_distance := 94.0
	for pickup in pickups:
		if pickup.collected:
			continue
		var distance := diver.global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = pickup
	for lifeform in lifeforms:
		if lifeform.harvested:
			continue
		var distance := diver.global_position.distance_to(lifeform.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = lifeform
	return nearest

func _interact() -> void:
	var target := _nearest_interactable()
	if target == null:
		if diver.global_position.distance_to(Vector2(-185, 88)) < 130.0:
			oxygen = oxygen_capacity
			health = 100.0
			diver.vehicle_health = 100.0
			story_message = "Escape pod systems restore oxygen and stabilize your vitals."
			_refresh_hud()
			return
		return
	if target is AlienLifeform:
		_sample_lifeform(target as AlienLifeform)
	elif target is SalvagePickup:
		var pickup := target as SalvagePickup
		if pickup.category == "story":
			signal_found = true
			story_message = pickup.story_text
		else:
			inventory[pickup.category] += pickup.amount
			discovered_materials[pickup.category] = true
			story_message = "%s recovered." % pickup.title
		pickup.collect()
	_save_game()
	_refresh_crafting_window()
	_refresh_hud()

func _sample_lifeform(lifeform: AlienLifeform) -> void:
	if lifeform.harvested:
		return
	inventory[lifeform.resource_id] += lifeform.yield_amount
	discovered_materials[lifeform.resource_id] = true
	lifeform.collect()
	story_message = "%s sampled: %s × %d. Scan its species to identify related technology." % [
		lifeform.specimen_name,
		_resource_name(lifeform.resource_id),
		lifeform.yield_amount
	]
	_save_game()
	_refresh_crafting_window()
	_refresh_hud()

func _craft_upgrade() -> void:
	_toggle_crafting_window(true)

func _save_game() -> bool:
	var collected_ids: Array[String] = []
	for pickup in pickups:
		if pickup.collected:
			collected_ids.append(pickup.pickup_id)
	var collected_lifeforms: Array[String] = []
	var scanned_lifeforms: Array[String] = []
	for lifeform in lifeforms:
		if lifeform.harvested:
			collected_lifeforms.append(lifeform.lifeform_id)
		if lifeform.scanned:
			scanned_lifeforms.append(lifeform.lifeform_id)
	var data := {
		"version": 3,
		"inventory": inventory,
		"discovered_materials": discovered_materials,
		"unlocked_recipes": unlocked_recipes,
		"installed_techs": installed_techs,
		"signal_found": signal_found,
		"collected": collected_ids,
		"collected_lifeforms": collected_lifeforms,
		"scanned_lifeforms": scanned_lifeforms,
		"position": [diver.global_position.x, diver.global_position.y],
		"oxygen": oxygen,
		"health": health,
		"vehicle_health": diver.vehicle_health
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save game: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data))
	var error := file.get_error()
	if error != OK:
		push_error("Could not write save game: %s" % error_string(error))
		return false
	return true

func _load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("Could not read save game: %s" % error_string(FileAccess.get_open_error()))
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) not in [1, 2, 3]:
		push_error("Save file is invalid or uses an unsupported version.")
		return false

	for resource_id in inventory:
		inventory[resource_id] = 0
	discovered_materials.clear()
	unlocked_recipes = {"pressure_weave": true}
	installed_techs.clear()
	signal_found = false
	oxygen = STARTING_OXYGEN
	health = 100.0
	diver.global_position = Vector2(35, 90)
	for pickup in pickups:
		pickup.collected = false
		pickup.icon.show()
	for lifeform in lifeforms:
		lifeform.harvested = false
		lifeform.scanned = false
		lifeform.icon.show()
	var save_version := int(parsed.get("version", 0))
	if save_version == 1:
		inventory["driftmetal"] = maxi(0, int(parsed.get("metal", 0)))
		inventory["lumen_kelp"] = maxi(0, int(parsed.get("kelp", 0)))
		if bool(parsed.get("upgraded", false)):
			installed_techs["pressure_weave"] = true
	else:
		var saved_inventory: Dictionary = parsed.get("inventory", {})
		for resource_id in inventory:
			inventory[resource_id] = maxi(0, int(saved_inventory.get(resource_id, 0)))
		unlocked_recipes = parsed.get("unlocked_recipes", {"pressure_weave": true})
		installed_techs = parsed.get("installed_techs", {})
		if save_version >= 3:
			discovered_materials = parsed.get("discovered_materials", {})
	signal_found = bool(parsed.get("signal_found", false))
	suit_upgraded = installed_techs.has("pressure_weave")
	if save_version >= 3:
		var saved_position: Array = parsed.get("position", [diver.global_position.x, diver.global_position.y])
		if saved_position.size() == 2:
			diver.global_position = Vector2(float(saved_position[0]), float(saved_position[1]))
		var loaded_capacity := 230.0 if installed_techs.has("deep_tank") else STARTING_OXYGEN
		oxygen = clampf(float(parsed.get("oxygen", STARTING_OXYGEN)), 0.0, loaded_capacity)
		health = clampf(float(parsed.get("health", 100.0)), 0.0, 100.0)
		diver.vehicle_health = clampf(float(parsed.get("vehicle_health", 100.0)), 0.0, 100.0)
	if signal_found:
		story_message = "The old recording says the trench was here before the water."
	elif suit_upgraded:
		story_message = "Pressure weave fitted. The trench signal is coming from far below."
	var collected: Array = parsed.get("collected", [])
	for pickup in pickups:
		if pickup.pickup_id in collected:
			pickup.collect()
	var collected_lifeforms: Array = parsed.get("collected_lifeforms", [])
	var scanned_lifeforms: Array = parsed.get("scanned_lifeforms", [])
	for lifeform in lifeforms:
		if lifeform.lifeform_id in collected_lifeforms:
			lifeform.collect()
		if lifeform.lifeform_id in scanned_lifeforms:
			lifeform.scanned = true
	for resource_id in inventory:
		if int(inventory[resource_id]) > 0:
			discovered_materials[resource_id] = true
	return true
