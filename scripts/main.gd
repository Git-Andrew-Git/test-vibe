extends Node2D

const DiverScript = preload("res://scripts/diver.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const WorldScript = preload("res://scripts/world.gd")
const LifeformScript = preload("res://scripts/lifeform.gd")
const LIFE_ATLAS := preload("res://assets/art/alien_life.svg")
const LAMP_GLOW := preload("res://assets/art/lamp_glow.svg")

const STARTING_OXYGEN := 150.0
const STARTING_DEPTH_LIMIT := 500.0
const UPGRADED_DEPTH_LIMIT := 1050.0
const SUIT_DEPTH_LIMIT := 1650.0
const SUB_DEPTH_LIMIT := 2400.0
const SAVE_PATH := "user://quiet_trench_save.json"
const SCAN_SECONDS := 0.85
const ANALYZER_RANGE := 780.0
const WORLD_LIMIT_X := 1400.0

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
		"aggressive": false
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
		"aggressive": false
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
		"aggressive": false
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
		"aggressive": true
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
		"aggressive": false
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
		"aggressive": false
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
		"aggressive": false
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
		"aggressive": false
	}
]

var save_path := SAVE_PATH
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
var unlocked_recipes := {"pressure_weave": true}
var installed_techs := {}
var oxygen := STARTING_OXYGEN
var oxygen_capacity := STARTING_OXYGEN
var depth_limit := STARTING_DEPTH_LIMIT
var health := 100.0
var scan_target: AlienLifeform
var scan_progress := 0.0
var analyzer_beam: Line2D
var scan_cooldown := 0.0
var dart_cooldown := 0.0
var suit_upgraded := false
var signal_found := false
var story_message := "The escape pod ruptures against the shore. The ocean is quiet. Too quiet."

var status_label: Label
var prompt_label: Label
var oxygen_bar: ProgressBar
var inventory_label: Label
var objective_label: Label
var depth_label: Label
var oxygen_empty_time := 0.0
var world_tint: CanvasModulate
var oxygen_fill_style: StyleBoxFlat
var health_bar: ProgressBar
var scan_label: Label
var scan_bar: ProgressBar
var crafting_overlay: ColorRect
var recipe_list: VBoxContainer
var recipe_details: Label
var selected_recipe := ""
var hud_canvas: CanvasLayer
var lamp_light: PointLight2D

func _ready() -> void:
	var world := Node2D.new()
	world.set_script(WorldScript)
	world.z_index = -10
	add_child(world)
	_create_atmosphere()

	diver = DiverScript.new()
	diver.name = "Diver"
	diver.position = Vector2(35, 90)
	diver.z_index = 4
	add_child(diver)

	_create_pickups()
	_create_lifeforms()
	_load_game()
	_create_hud()
	_create_analyzer_beam()
	_create_crafting_window()
	_apply_installed_techs()
	_refresh_hud()
	_refresh_crafting_window()

func _process(delta: float) -> void:
	var depth := maxf(0.0, diver.global_position.y - 77.0)
	var depth_ratio := clampf(depth / float(SUB_DEPTH_LIMIT), 0.0, 1.0)
	world_tint.color = Color.WHITE.lerp(Color(0.18, 0.29, 0.48), depth_ratio * 0.74)
	if diver.global_position.y <= 145.0:
		oxygen = minf(oxygen_capacity, oxygen + 34.0 * delta)
		oxygen_empty_time = 0.0
	else:
		oxygen = maxf(0.0, oxygen - (1.8 + depth * 0.006) * delta)

	for lifeform in lifeforms:
		if lifeform.harvested or not lifeform.aggressive or lifeform.stun_remaining > 0.0:
			continue
		if diver.global_position.distance_to(lifeform.global_position) < 100.0:
			health = maxf(0.0, health - 20.0 * delta)
			story_message = "A Riftstalker is striking! Scan it or escape."

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
	_update_analyzer(delta)
	_refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.physical_keycode == KEY_E:
			_interact()
		elif key_event.physical_keycode == KEY_F:
			_toggle_crafting_window(not crafting_overlay.visible)
		elif key_event.physical_keycode == KEY_ESCAPE and crafting_overlay.visible:
			_toggle_crafting_window(false)
		return
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
	hud_canvas = canvas
	add_child(canvas)

	var left_panel := PanelContainer.new()
	left_panel.position = Vector2(22, 20)
	left_panel.custom_minimum_size = Vector2(330, 0)
	_style_glass_panel(left_panel, Color(0.20, 0.93, 0.84))
	canvas.add_child(left_panel)

	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 8)
	left_panel.add_child(left_column)

	var title := Label.new()
	title.text = "THE QUIET TRENCH"
	title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.89))
	title.add_theme_font_size_override("font_size", 23)
	left_column.add_child(title)

	depth_label = Label.new()
	depth_label.name = "DepthLabel"
	depth_label.add_theme_color_override("font_color", Color(0.77, 0.91, 1.0))
	left_column.add_child(depth_label)

	var oxygen_caption := Label.new()
	oxygen_caption.text = "OXYGEN"
	oxygen_caption.add_theme_color_override("font_color", Color(0.60, 0.84, 0.98))
	oxygen_caption.add_theme_font_size_override("font_size", 13)
	left_column.add_child(oxygen_caption)

	oxygen_bar = ProgressBar.new()
	oxygen_bar.custom_minimum_size = Vector2(290, 20)
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
	left_column.add_child(oxygen_bar)

	var health_caption := Label.new()
	health_caption.text = "VITALS"
	health_caption.add_theme_color_override("font_color", Color(0.93, 0.65, 0.76))
	health_caption.add_theme_font_size_override("font_size", 12)
	left_column.add_child(health_caption)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(290, 14)
	health_bar.max_value = 100.0
	health_bar.show_percentage = false
	var health_track := StyleBoxFlat.new()
	health_track.bg_color = Color(0.12, 0.035, 0.1, 0.95)
	health_track.set_corner_radius_all(8)
	health_bar.add_theme_stylebox_override("background", health_track)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(1.0, 0.36, 0.57)
	health_fill.set_corner_radius_all(7)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	left_column.add_child(health_bar)

	inventory_label = Label.new()
	inventory_label.add_theme_color_override("font_color", Color(0.91, 0.98, 0.94))
	inventory_label.add_theme_font_size_override("font_size", 14)
	left_column.add_child(inventory_label)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_color_override("font_color", Color(1.0, 0.79, 0.48))
	objective_label.add_theme_font_size_override("font_size", 14)
	left_column.add_child(objective_label)

	var story_panel := PanelContainer.new()
	story_panel.custom_minimum_size = Vector2(500, 80)
	story_panel.position = Vector2(390, 20)
	_style_glass_panel(story_panel, Color(1.0, 0.70, 0.38))
	canvas.add_child(story_panel)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.73))
	status_label.add_theme_font_size_override("font_size", 16)
	story_panel.add_child(status_label)

	var prompt_panel := PanelContainer.new()
	prompt_panel.custom_minimum_size = Vector2(570, 56)
	prompt_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.position = Vector2(-285, -80)
	_style_glass_panel(prompt_panel, Color(0.40, 1.0, 0.83))
	canvas.add_child(prompt_panel)

	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color", Color(0.80, 1.0, 0.90))
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_panel.add_child(prompt_label)

	var controls_panel := PanelContainer.new()
	controls_panel.position = Vector2(22, 645)
	_style_glass_panel(controls_panel, Color(0.28, 0.86, 0.94))
	canvas.add_child(controls_panel)
	var controls := Label.new()
	controls.text = "SWIM  WASD / ARROWS     USE  E     TECH  F     ANALYZE  HOLD LMB"
	controls.add_theme_color_override("font_color", Color(0.80, 0.91, 1.0))
	controls.add_theme_font_size_override("font_size", 13)
	controls_panel.add_child(controls)

	var scan_panel := PanelContainer.new()
	scan_panel.custom_minimum_size = Vector2(300, 52)
	scan_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	scan_panel.position = Vector2(-150, -145)
	_style_glass_panel(scan_panel, Color(0.40, 1.0, 0.83))
	canvas.add_child(scan_panel)

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
	close_button.text = "CLOSE  [ESC]"
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
		var card := PanelContainer.new()
		_style_glass_panel(card, Color(0.31, 0.88, 0.88))
		recipe_list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_button := Button.new()
		name_button.text = recipe.title
		name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_button.flat = true
		name_button.add_theme_font_size_override("font_size", 18)
		name_button.add_theme_color_override(
			"font_color",
			Color(0.58, 1.0, 0.86) if unlocked_recipes.has(recipe_id) else Color(0.67, 0.75, 0.83)
		)
		name_button.pressed.connect(_select_recipe.bind(recipe_id))
		info.add_child(name_button)

		var scan_description: String = (
			recipe.description
			if unlocked_recipes.has(recipe_id)
			else "UNKNOWN  —  Scan a %s with the analyzer." % recipe.scan
		)
		var description := Label.new()
		description.text = scan_description
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_color_override(
			"font_color",
			Color(0.84, 0.92, 0.89) if unlocked_recipes.has(recipe_id) else Color(0.66, 0.75, 0.82)
		)
		info.add_child(description)

		var ingredients := Label.new()
		ingredients.text = _format_recipe_cost(recipe.cost)
		ingredients.add_theme_color_override("font_color", Color(1.0, 0.79, 0.49))
		info.add_child(ingredients)

		var craft_button := Button.new()
		var enough_materials := _has_recipe_materials(recipe)
		var already_built := _is_technology_built(recipe_id)
		if already_built:
			craft_button.text = "INSTALLED"
			craft_button.disabled = true
		elif not unlocked_recipes.has(recipe_id):
			craft_button.text = "UNKNOWN"
			craft_button.disabled = true
		elif enough_materials:
			craft_button.text = "CRAFT"
			craft_button.pressed.connect(_craft_recipe.bind(recipe_id))
		else:
			craft_button.text = "NEED SAMPLES"
			craft_button.disabled = true
		row.add_child(craft_button)

	if not RECIPES.has(selected_recipe):
		selected_recipe = "pressure_weave"
	recipe_details.text = _recipe_detail_text(selected_recipe)

func _recipe_detail_text(recipe_id: String) -> String:
	var recipe: Dictionary = RECIPES[recipe_id]
	var status := "READY TO BUILD"
	if not unlocked_recipes.has(recipe_id):
		status = "UNKNOWN — Analyzer scan required: %s" % recipe.scan
	elif _is_technology_built(recipe_id):
		status = "INSTALLED"
	elif not _has_recipe_materials(recipe):
		status = "MISSING: %s" % _format_recipe_cost(recipe.cost)
	return "%s  •  %s" % [status, recipe.description]

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

func _inventory_summary() -> String:
	return (
		"SALVAGE\n"
		+ "Driftmetal %d   Lumen kelp %d   Ember kelp %d\n"
		+ "Moon mucus %d   Ribbon silk %d   Veil moss %d\n"
		+ "Shell plate %d   Spire coral %d   Bloom %d   Filament %d"
	) % [
		inventory["driftmetal"],
		inventory["lumen_kelp"],
		inventory["ember_kelp"],
		inventory["moon_mucus"],
		inventory["ribbon_silk"],
		inventory["veil_moss"],
		inventory["shell_plate"],
		inventory["spire_coral"],
		inventory["abyssal_bloom"],
		inventory["electric_filament"]
	]

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
func _style_glass_panel(panel: PanelContainer, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.075, 0.14, 0.84)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
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
	depth_label.text = "DEPTH  %03d m     LIMIT  %03d m" % [roundi(depth), roundi(depth_limit)]
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
	inventory_label.text = _inventory_summary()
	objective_label.text = (
		"Signal recovered. The trench predates the ocean. More answers lie below."
		if signal_found
		else "Find samples, scan alien life, and press F to inspect technologies."
	)
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
	elif depth >= depth_limit - 2.0:
		prompt_label.text = "Pressure wall. Craft the pressure weave at the surface pod."
	elif oxygen_empty_time > 0.0:
		prompt_label.text = "OXYGEN DEPLETED  Emergency return in progress..."
	elif health <= 25.0:
		prompt_label.text = "VITALS CRITICAL  Flee or craft Symbiotic repair gel."
	else:
		prompt_label.text = ""
	prompt_label.get_parent().visible = not prompt_label.text.is_empty()
	if crafting_overlay.visible:
		prompt_label.get_parent().visible = false

func _create_analyzer_beam() -> void:
	analyzer_beam = Line2D.new()
	analyzer_beam.width = 4.0
	analyzer_beam.default_color = Color(0.31, 1.0, 0.85, 0.22)
	analyzer_beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	analyzer_beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	analyzer_beam.z_index = 7
	add_child(analyzer_beam)

func _update_analyzer(delta: float) -> void:
	if crafting_overlay.visible:
		analyzer_beam.clear_points()
		scan_target = null
		scan_progress = 0.0
		scan_bar.value = 0.0
		scan_label.text = "TECH BENCH OPEN"
		return

	var start := diver.global_position + Vector2(0, -8)
	var mouse_world := get_global_mouse_position()
	var delta_to_mouse := mouse_world - start
	var beam_length := minf(delta_to_mouse.length(), ANALYZER_RANGE)
	var end := start + delta_to_mouse.normalized() * beam_length
	if delta_to_mouse.length_squared() < 1.0:
		end = start + Vector2.RIGHT * ANALYZER_RANGE
	analyzer_beam.clear_points()
	analyzer_beam.add_point(to_local(start))
	analyzer_beam.add_point(to_local(end))

	var is_scanning := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var target := _target_on_beam(start, end)
	analyzer_beam.default_color = (
		Color(0.56, 1.0, 0.62, 0.83)
		if is_scanning and target != null
		else Color(0.31, 0.95, 1.0, 0.25)
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
	var target: AlienLifeform
	var nearest_distance := 78.0
	for lifeform in lifeforms:
		if lifeform.harvested or (require_unscanned and lifeform.scanned):
			continue
		var point := Geometry2D.get_closest_point_to_segment(lifeform.global_position, start, end)
		var distance := lifeform.global_position.distance_to(point)
		if distance < nearest_distance:
			nearest_distance = distance
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
			story_message = "%s recovered." % pickup.title
		pickup.collect()
	_save_game()
	_refresh_crafting_window()
	_refresh_hud()

func _sample_lifeform(lifeform: AlienLifeform) -> void:
	if lifeform.harvested:
		return
	inventory[lifeform.resource_id] += lifeform.yield_amount
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

func _save_game() -> void:
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
		"version": 2,
		"inventory": inventory,
		"unlocked_recipes": unlocked_recipes,
		"installed_techs": installed_techs,
		"signal_found": signal_found,
		"collected": collected_ids,
		"collected_lifeforms": collected_lifeforms,
		"scanned_lifeforms": scanned_lifeforms
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save game: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data))

func _load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_error("Could not read save game: %s" % error_string(FileAccess.get_open_error()))
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) not in [1, 2]:
		push_error("Save file is invalid or uses an unsupported version.")
		return

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
	signal_found = bool(parsed.get("signal_found", false))
	suit_upgraded = installed_techs.has("pressure_weave")
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
