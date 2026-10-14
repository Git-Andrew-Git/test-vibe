extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const TEST_SAVE_PATH := "user://quiet_trench_smoke_test.json"
const LEGACY_SAVE_PATH := "user://quiet_trench_legacy_test.json"
const TEST_SETTINGS_PATH := "user://quiet_trench_settings_test.json"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_remove_save(TEST_SAVE_PATH)
	_remove_save(LEGACY_SAVE_PATH)
	_remove_save(TEST_SETTINGS_PATH)
	var game: Variant = MAIN_SCENE.instantiate()
	game.save_path = TEST_SAVE_PATH
	game.settings_path = TEST_SETTINGS_PATH
	root.add_child(game)
	await process_frame

	var world: OceanWorld = game.get_child(0)
	_expect(not _contains_earth_fish(world), "No un-interactable Earth-like fish are present.")
	_expect(world.bubbles.size() >= 40, "The ocean has animated ambient bubbles.")
	_expect(world.get_node_or_null("TrenchFloor") != null, "A visible illustrated trench landscape anchors the deep.")
	_expect(game.diver.diver_sprite.texture != null, "The smaller diver uses the illustrated sprite.")
	_expect(game.lifeforms.size() == 27, "All eight alien species have interactable specimens.")
	_expect(game.pickups.size() == 10, "The world contains salvage and a story pickup.")
	_expect(game.analyzer_beam != null, "The analyzer has an aiming beam.")
	_expect(game.ANALYZER_HALF_ANGLE * 2.0 == 30.0, "The analyzer beam covers a 30-degree cone.")
	_expect(is_equal_approx(game.ANALYZER_RANGE, 780.0), "The analyzer beam has a finite 780-unit reach.")
	_expect(game.diver.HORIZONTAL_LIMIT >= 1400.0, "The diver can explore the expanded horizontal world.")
	_expect(game.health == 100.0, "The diver starts with 100 health.")
	_expect(not game.radio_panel.visible, "The last radio message is hidden until the radio is opened.")
	game._toggle_radio()
	_expect(game.radio_panel.visible, "The radio button reveals the latest message.")
	game._toggle_radio()

	game.diver.global_position = Vector2(0, 577)
	game._process(0.016)
	_expect(game.world_tint.color != Color.WHITE, "Water atmosphere darkens with depth.")

	var moon_jelly: AlienLifeform = _first_lifeform(game, "moon_jelly")
	_expect(
		game._recipe_detail_text("fins").contains("UNDISCOVERED")
		and not game._recipe_detail_text("fins").contains("Ribbon"),
		"Unknown technology hides its name, ingredients, and scan target."
	)
	game.discovered_materials["ribbon_silk"] = true
	var partial_lead: String = game._recipe_detail_text("fins")
	_expect(
		partial_lead.contains("Ribbon silk") and not partial_lead.contains("Ember kelp")
		and not partial_lead.contains("Current-rider"),
		"A recovered ingredient reveals only that known recipe fragment."
	)
	game.discovered_materials.clear()
	var scan_start := moon_jelly.global_position + Vector2(-100, 0)
	var scan_end := moon_jelly.global_position + Vector2(100, 0)
	_expect(
		game._target_on_beam(scan_start, scan_end) == moon_jelly,
		"The mouse-directed analyzer beam can target a lifeform."
	)
	_expect(
		game._recipe_detail_text("deep_tank").begins_with("UNDISCOVERED"),
		"Unscanned technology is visibly marked unknown."
	)
	game._advance_scan(moon_jelly, 1.0)
	_expect(moon_jelly.scanned, "Holding a stable analyzer lock completes a scan.")
	_expect(game.unlocked_recipes.has("deep_tank"), "Scanning reveals the Moon-jelly tank technology.")
	_expect(
		game._recipe_detail_text("deep_tank").begins_with("MISSING:")
		and not game._has_recipe_materials(game.RECIPES.deep_tank),
		"Known but uncraftable technology reports its missing materials."
	)

	var stored_harvested: Array[bool] = []
	for lifeform in game.lifeforms:
		stored_harvested.append(lifeform.harvested)
		lifeform.harvested = true
	moon_jelly.harvested = false
	var cone_origin: Vector2 = game.diver.global_position
	moon_jelly.global_position = cone_origin + Vector2(300.0, 65.0)
	_expect(
		game._target_in_cone(cone_origin, Vector2.RIGHT, false) == moon_jelly,
		"A lifeform inside the 30-degree analyzer cone is targetable."
	)
	moon_jelly.global_position = cone_origin + Vector2(300.0, 110.0)
	_expect(
		game._target_in_cone(cone_origin, Vector2.RIGHT) == null,
		"A lifeform outside the analyzer cone is not targetable."
	)
	moon_jelly.global_position = cone_origin + Vector2(game.ANALYZER_RANGE + 100.0, 0.0)
	_expect(
		game._target_in_cone(cone_origin, Vector2.RIGHT) == null,
		"A lifeform beyond analyzer reach is not targetable."
	)
	for index in range(game.lifeforms.size()):
		game.lifeforms[index].harvested = stored_harvested[index]

	var seen_species := {}
	for lifeform in game.lifeforms:
		seen_species[lifeform.species_id] = true
		if not lifeform.scanned:
			game.scan_target = null
			game._advance_scan(lifeform, 1.0)
	_expect(seen_species.size() == 8, "Every fauna and flora type is represented.")
	_expect(game.unlocked_recipes.size() == game.RECIPES.size(), "Every species unlocks a technology recipe.")
	var riftstalker: AlienLifeform = _first_lifeform(game, "riftstalker")
	var dart_start := riftstalker.global_position + Vector2(-100, 0)
	var dart_end := riftstalker.global_position + Vector2(100, 0)
	_expect(
		game._target_on_beam(dart_start, dart_end, false) == riftstalker,
		"Scanned hostile fauna remains targetable by the tranquilizer."
	)
	for lifeform in game.lifeforms:
		game._sample_lifeform(lifeform)
		_expect(lifeform.harvested, "%s can be sampled." % lifeform.specimen_name)
	_expect(game.inventory["moon_mucus"] == 3, "Moon-jelly specimens produce their recipe ingredient.")
	_expect(game.inventory["ribbon_silk"] == 3, "Ribbon gliders produce their recipe ingredient.")
	_expect(game.inventory["shell_plate"] == 3, "Glassbacks produce their recipe ingredient.")
	_expect(game.inventory["electric_filament"] == 2, "Riftstalkers produce their recipe ingredient.")
	_expect(game.inventory["ember_kelp"] == 4, "Ember kelp produces its recipe ingredient.")
	_expect(game.inventory["veil_moss"] == 4, "Veil moss produces its recipe ingredient.")
	_expect(game.inventory["spire_coral"] == 4, "Spire coral produces its recipe ingredient.")
	_expect(game.inventory["abyssal_bloom"] == 4, "Lantern blooms produce their recipe ingredient.")

	_collect(game, "metal_a")
	_collect(game, "metal_b")
	_collect(game, "metal_c")
	_collect(game, "kelp_a")
	_expect(game.inventory["driftmetal"] == 3, "Salvage collection adds Driftmetal.")
	_expect(game.inventory["lumen_kelp"] == 1, "Salvage collection adds Lumen kelp.")
	game._toggle_crafting_window(true)
	_expect(game.crafting_overlay.visible, "F opens the technology bench.")
	game._craft_recipe("pressure_weave")
	_expect(game.suit_upgraded, "The pressure weave can be crafted.")
	_expect(game.diver.depth_limit == 1050.0, "The pressure weave increases the depth limit.")
	_expect(
		game.inventory["driftmetal"] == 0 and game.inventory["lumen_kelp"] == 0,
		"Crafting consumes its materials."
	)

	game._craft_recipe("fins")
	_expect(game.diver.has_fins, "Crafted fins enable the Shift boost.")
	var swim_speed: float = game.diver._effective_movement_speed(false)
	var boosted_speed: float = game.diver._effective_movement_speed(true)
	_expect(
		is_equal_approx(boosted_speed, swim_speed * game.diver.BOOST_MULTIPLIER),
		"Holding Shift increases movement speed when fins are installed."
	)
	game._craft_recipe("deep_tank")
	_expect(game.oxygen_capacity == 230.0, "The scrubber tank increases oxygen capacity.")
	_expect(game.diver.depth_limit == 1650.0, "The scrubber tank increases safe dive depth.")
	game._craft_recipe("lamp")
	_expect(game.lamp_light != null and game.lamp_light.texture != null, "The lamp creates a functioning light.")
	game._craft_recipe("submersible")
	_expect(game.diver.depth_limit == 2400.0, "The pocket sub extends the pressure limit.")
	_expect(game.diver.has_submersible and game.diver.submersible_sprite.visible, "The pocket sub equips a visible vehicle around the diver.")
	game._craft_recipe("tranquilizer")
	game._fire_dart_at(riftstalker)
	_expect(riftstalker.stun_remaining > 0.0, "The tranquilizer stuns hostile alien fauna.")
	game.dart_cooldown = 0.0
	game.health = 42.0
	game._craft_recipe("medkit")
	_expect(game.health == 100.0, "Repair gel restores health when crafted.")
	_expect(not game._is_technology_built("medkit"), "Consumed repair gel remains craftable.")

	_collect(game, "signal_fragment")
	_expect(game.signal_found, "The deep signal fragment advances the story.")
	game._toggle_crafting_window(false)
	var loaded_game: Variant = MAIN_SCENE.instantiate()
	loaded_game.save_path = TEST_SAVE_PATH
	loaded_game.settings_path = TEST_SETTINGS_PATH
	root.add_child(loaded_game)
	await process_frame
	_expect(loaded_game.suit_upgraded, "The pressure upgrade persists in the local save.")
	_expect(loaded_game.signal_found, "Story progress persists in the local save.")
	_expect(loaded_game.installed_techs.has("fins"), "Installed technology persists in the local save.")
	_expect(loaded_game.diver.global_position == game.diver.global_position, "The saved diver location reloads.")
	_expect(loaded_game.unlocked_recipes.size() == loaded_game.RECIPES.size(), "Scanned recipes persist.")
	_expect(loaded_game.lifeforms.all(func(lifeform: AlienLifeform) -> bool: return lifeform.harvested), "Sampled specimens remain harvested after reload.")
	_expect(_pickup_is_collected(loaded_game, "signal_fragment"), "Collected story items stay collected after reload.")

	loaded_game.diver.global_position = Vector2(0, 200)
	loaded_game.oxygen = 0.0
	loaded_game.oxygen_empty_time = 4.9
	loaded_game._process(0.2)
	_expect(loaded_game.diver.global_position.y <= 145.0, "An empty tank triggers emergency surface rescue.")
	_expect(loaded_game.oxygen > 0.0, "Emergency rescue restores oxygen.")

	var legacy_game: Variant = await _test_legacy_save()
	if legacy_game != null:
		_expect(legacy_game.inventory["driftmetal"] == 2, "Older saves migrate their Driftmetal count.")
		_expect(legacy_game.inventory["lumen_kelp"] == 1, "Older saves migrate their Lumen kelp count.")
		_expect(legacy_game.installed_techs.has("pressure_weave"), "Older pressure upgrades migrate.")
		legacy_game.queue_free()

	var escape_event := InputEventKey.new()
	escape_event.physical_keycode = KEY_ESCAPE
	escape_event.pressed = true
	game._unhandled_input(escape_event)
	_expect(game.pause_menu_open and game.get_tree().paused, "Escape opens a pausing menu.")
	_expect(game.pause_overlay.color.a > 0.85, "The pause overlay is darker and less transparent.")
	game._show_settings(true)
	_expect(game.settings_panel_visible, "Settings can be opened from the pause menu.")
	_expect(
		game.AUTOSAVE_INTERVALS.has(30) and game.AUTOSAVE_INTERVALS.has(60)
		and game.AUTOSAVE_INTERVALS.has(300) and game.AUTOSAVE_INTERVALS.has(600)
		and game.AUTOSAVE_INTERVALS.has(900) and game.AUTOSAVE_INTERVALS.has(1800),
		"Autosave intervals include 30 seconds, 1, 5, 10, 15, and 30 minutes."
	)
	var old_interact_events: Array = InputMap.action_get_events("interact")
	game.awaiting_keybinding = "interact"
	var rebind_event := InputEventKey.new()
	rebind_event.physical_keycode = KEY_G
	game._apply_keybinding(rebind_event)
	_expect(game._action_key_text("interact").contains("G"), "The keybinding menu can remap an action.")
	InputMap.action_erase_events("interact")
	for assigned_event in old_interact_events:
		InputMap.action_add_event("interact", assigned_event)
	game._save_settings()
	game._load_settings()
	_expect(game._action_key_text("interact").contains("E"), "Key bindings persist in settings.")
	game.settings_data["master_volume"] = 1.0
	game._apply_settings()
	game._show_settings(false)
	game._set_pause_menu(false)
	game.diver.global_position = Vector2(0, 90)
	game.inventory["driftmetal"] = 99
	game._set_pause_menu(true)
	game._load_from_menu()
	_expect(game.inventory["driftmetal"] == 0, "Load Game restores the last saved inventory.")
	_expect(game.diver.global_position.y == 1320.0, "Load Game restores the last saved location.")
	game._set_pause_menu(false)
	game.settings_data["autosave_interval"] = 30
	game._update_autosave(30.0)
	_expect(FileAccess.file_exists(TEST_SAVE_PATH), "Autosave writes progress after its configured interval.")

	game.queue_free()
	loaded_game.queue_free()
	await process_frame
	_remove_save(TEST_SAVE_PATH)
	_remove_save(LEGACY_SAVE_PATH)
	_remove_save(TEST_SETTINGS_PATH)
	if failures == 0:
		print("All gameplay smoke checks passed.")
		quit(0)
	else:
		push_error("%d gameplay smoke check(s) failed." % failures)
		quit(1)

func _test_legacy_save() -> Variant:
	var file := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_expect(false, "A legacy save fixture can be created.")
		return null
	file.store_string(JSON.stringify({
		"version": 1,
		"metal": 2,
		"kelp": 1,
		"upgraded": true,
		"signal_found": false,
		"collected": []
	}))
	file.close()
	var game: Variant = MAIN_SCENE.instantiate()
	game.save_path = LEGACY_SAVE_PATH
	game.settings_path = TEST_SETTINGS_PATH
	root.add_child(game)
	await process_frame
	return game

func _first_lifeform(game: Variant, species_id: String) -> AlienLifeform:
	for lifeform in game.lifeforms:
		if lifeform.species_id == species_id:
			return lifeform
	return null

func _contains_earth_fish(world: OceanWorld) -> bool:
	for child in world.get_children():
		if child is Sprite2D and (child as Sprite2D).texture.resource_path.get_file().begins_with("fish_"):
			return true
	return false

func _collect(game: Variant, pickup_id: String) -> void:
	for pickup in game.pickups:
		if pickup.pickup_id == pickup_id:
			game.diver.global_position = pickup.global_position
			game._interact()
			_expect(pickup.collected, "Pickup '%s' can be collected." % pickup_id)
			return
	_expect(false, "Pickup '%s' exists." % pickup_id)

func _pickup_is_collected(game: Variant, pickup_id: String) -> bool:
	for pickup in game.pickups:
		if pickup.pickup_id == pickup_id:
			return pickup.collected
	return false

func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures += 1
		push_error("FAIL: %s" % description)

func _remove_save(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var error := DirAccess.remove_absolute(absolute_path)
		if error != OK:
			push_error("Could not remove smoke-test save file: %s" % error_string(error))
