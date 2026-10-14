extends Node2D

const DiverScript = preload("res://scripts/diver.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const WorldScript = preload("res://scripts/world.gd")
const DEPTH_SHADER = preload("res://shaders/depth_atmosphere.gdshader")

const STARTING_OXYGEN := 150.0
const STARTING_DEPTH_LIMIT := 500.0
const UPGRADED_DEPTH_LIMIT := 1050.0
const SAVE_PATH := "user://quiet_trench_save.json"

var save_path := SAVE_PATH
var diver: OceanDiver
var pickups: Array[SalvagePickup] = []
var inventory := {"metal": 0, "kelp": 0}
var oxygen := STARTING_OXYGEN
var depth_limit := STARTING_DEPTH_LIMIT
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
var atmosphere_material: ShaderMaterial
var oxygen_fill_style: StyleBoxFlat

func _ready() -> void:
	var world := Node2D.new()
	world.set_script(WorldScript)
	world.z_index = -10
	add_child(world)
	_create_atmosphere()

	diver = DiverScript.new()
	diver.name = "Diver"
	diver.position = Vector2(35, 90)
	add_child(diver)

	_create_pickups()
	_load_game()
	_create_hud()
	_refresh_hud()

func _process(delta: float) -> void:
	var depth := maxf(0.0, diver.global_position.y - 77.0)
	atmosphere_material.set_shader_parameter("depth_ratio", clampf(depth / UPGRADED_DEPTH_LIMIT, 0.0, 1.0))
	if diver.global_position.y <= 145.0:
		oxygen = minf(STARTING_OXYGEN, oxygen + 34.0 * delta)
		oxygen_empty_time = 0.0
	else:
		oxygen = maxf(0.0, oxygen - (1.8 + depth * 0.006) * delta)

	if oxygen <= 0.0 and diver.global_position.y > 145.0:
		oxygen_empty_time += delta
		if oxygen_empty_time >= 5.0:
			diver.global_position = Vector2(0, 90)
			oxygen = STARTING_OXYGEN
			oxygen_empty_time = 0.0
			story_message = "Your emergency beacon hauls you back to the surface. The pod's lights flicker."

	_refresh_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if key_event.physical_keycode == KEY_E:
		_interact()
	elif key_event.physical_keycode == KEY_F:
		_craft_upgrade()

func _create_pickups() -> void:
	_add_pickup("metal_a", "Driftmetal", "metal", 1, Vector2(-180, 270))
	_add_pickup("kelp_a", "Lumen kelp", "kelp", 1, Vector2(200, 345))
	_add_pickup("metal_b", "Driftmetal", "metal", 1, Vector2(135, 420))
	_add_pickup("kelp_b", "Lumen kelp", "kelp", 1, Vector2(-255, 465))
	_add_pickup("metal_c", "Driftmetal", "metal", 1, Vector2(330, 485))
	_add_pickup("metal_deep", "Abyssal alloy", "metal", 2, Vector2(-190, 810))
	_add_pickup(
		"signal_fragment",
		"Signal fragment",
		"story",
		0,
		Vector2(80, 930),
		"An old recording crackles to life: \"We did not make the trench. It was here before the water.\""
	)

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
	controls.text = "MOVE  WASD / ARROWS     INTERACT  E     CRAFT  F"
	controls.add_theme_color_override("font_color", Color(0.80, 0.91, 1.0))
	controls.add_theme_font_size_override("font_size", 13)
	controls_panel.add_child(controls)

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
	var atmosphere := CanvasLayer.new()
	atmosphere.layer = 1
	add_child(atmosphere)

	var darkness := ColorRect.new()
	darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere_material = ShaderMaterial.new()
	atmosphere_material.shader = DEPTH_SHADER
	darkness.material = atmosphere_material
	atmosphere.add_child(darkness)

func _refresh_hud() -> void:
	if status_label == null:
		return

	var depth := maxf(0.0, diver.global_position.y - 77.0)
	depth_label.text = "DEPTH  %03d m     PRESSURE RATING  %03d m" % [roundi(depth), roundi(depth_limit)]
	oxygen_bar.value = oxygen
	oxygen_fill_style.bg_color = (
		Color(1.0, 0.34, 0.36)
		if oxygen <= STARTING_OXYGEN * 0.25
		else Color(1.0, 0.72, 0.36)
		if oxygen <= STARTING_OXYGEN * 0.5
		else Color(0.18, 0.92, 0.78)
	)
	inventory_label.text = "SALVAGE   Driftmetal %d     Lumen kelp %d" % [inventory.metal, inventory.kelp]
	objective_label.text = (
		"UPGRADE READY  F at the pod"
		if not suit_upgraded and inventory.metal >= 3 and inventory.kelp >= 1
		else "Find 3 Driftmetal + 1 Lumen kelp to craft a pressure weave."
		if not suit_upgraded
		else "DESCEND  Follow the signal below %d m." % roundi(UPGRADED_DEPTH_LIMIT * 0.75)
		if not signal_found
		else "SIGNAL RECOVERED  The trench predates the ocean. Your story continues..."
	)
	status_label.text = story_message

	var nearby := _nearest_pickup()
	if nearby != null:
		prompt_label.text = "[E]  Collect %s" % nearby.title
	elif diver.global_position.y <= 145.0 and absf(diver.global_position.x + 185.0) <= 130.0:
		prompt_label.text = (
			"[F]  Craft pressure weave  (3 Driftmetal + 1 Lumen kelp)"
			if not suit_upgraded
			else "POD STATION  Oxygen replenished"
		)
	elif depth >= depth_limit - 2.0:
		prompt_label.text = "Pressure wall. Craft the pressure weave at the surface pod."
	elif oxygen_empty_time > 0.0:
		prompt_label.text = "OXYGEN DEPLETED  Emergency return in progress..."
	else:
		prompt_label.text = ""
	prompt_label.get_parent().visible = not prompt_label.text.is_empty()

func _nearest_pickup() -> SalvagePickup:
	var nearest: SalvagePickup
	var nearest_distance := 94.0
	for pickup in pickups:
		if pickup.collected:
			continue
		var distance := diver.global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = pickup
	return nearest

func _interact() -> void:
	var pickup := _nearest_pickup()
	if pickup == null:
		return
	if pickup.category == "story":
		signal_found = true
		story_message = pickup.story_text
	else:
		inventory[pickup.category] += pickup.amount
		story_message = "%s recovered." % pickup.title
	pickup.collect()
	_save_game()
	_refresh_hud()

func _craft_upgrade() -> void:
	if suit_upgraded:
		return
	if diver.global_position.y > 145.0 or absf(diver.global_position.x + 185.0) > 130.0:
		return
	if inventory.metal < 3 or inventory.kelp < 1:
		story_message = "The pod's fabricator needs 3 Driftmetal and 1 Lumen kelp."
		return

	inventory.metal -= 3
	inventory.kelp -= 1
	suit_upgraded = true
	depth_limit = UPGRADED_DEPTH_LIMIT
	diver.depth_limit = depth_limit
	story_message = "Pressure weave fitted. The trench signal is coming from far below."
	_save_game()
	_refresh_hud()

func _save_game() -> void:
	var collected_ids: Array[String] = []
	for pickup in pickups:
		if pickup.collected:
			collected_ids.append(pickup.pickup_id)
	var data := {
		"version": 1,
		"metal": inventory.metal,
		"kelp": inventory.kelp,
		"upgraded": suit_upgraded,
		"signal_found": signal_found,
		"collected": collected_ids
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
	if not parsed is Dictionary or parsed.get("version") != 1:
		push_error("Save file is invalid or uses an unsupported version.")
		return

	inventory.metal = maxi(0, int(parsed.get("metal", 0)))
	inventory.kelp = maxi(0, int(parsed.get("kelp", 0)))
	suit_upgraded = bool(parsed.get("upgraded", false))
	signal_found = bool(parsed.get("signal_found", false))
	if signal_found:
		story_message = "The old recording says the trench was here before the water."
	elif suit_upgraded:
		story_message = "Pressure weave fitted. The trench signal is coming from far below."
	if suit_upgraded:
		depth_limit = UPGRADED_DEPTH_LIMIT
		diver.depth_limit = depth_limit
	var collected: Array = parsed.get("collected", [])
	for pickup in pickups:
		if pickup.pickup_id in collected:
			pickup.collect()
