extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const TEST_SAVE_PATH := "user://quiet_trench_smoke_test.json"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_remove_test_save()

	var game: Variant = MAIN_SCENE.instantiate()
	game.save_path = TEST_SAVE_PATH
	root.add_child(game)
	await process_frame

	var world: OceanWorld = game.get_child(0)
	_expect(world.fish_schools.size() >= 25, "The ocean is populated by swimming fish.")
	_expect(world.bubbles.size() >= 40, "The ocean has animated ambient bubbles.")
	_expect(game.diver.diver_sprite.texture != null, "The diver uses the illustrated game sprite.")
	_expect(game.pickups[0].icon.texture != null, "Salvage uses its illustrated pickup sprite.")
	game.diver.global_position = Vector2(0, 577)
	game._process(0.0)
	_expect(
		float(game.atmosphere_material.get_shader_parameter("depth_ratio")) > 0.45,
		"Water atmosphere becomes darker with depth."
	)

	_expect(game.pickups.size() == 7, "The world creates the expected salvage and story pickups.")
	_collect(game, "metal_a")
	_collect(game, "metal_b")
	_collect(game, "metal_c")
	_collect(game, "kelp_a")
	_expect(game.inventory.metal == 3, "Salvage collection adds Driftmetal.")
	_expect(game.inventory.kelp == 1, "Salvage collection adds Lumen kelp.")

	game.diver.global_position = Vector2(-185, 77)
	game._craft_upgrade()
	_expect(game.suit_upgraded, "The pressure weave can be crafted at the pod.")
	_expect(game.diver.depth_limit == 1050.0, "Crafting increases the diver's pressure limit.")
	_expect(game.inventory.metal == 0 and game.inventory.kelp == 0, "Crafting consumes its materials.")

	_collect(game, "signal_fragment")
	_expect(game.signal_found, "The deep signal fragment advances the story.")

	var loaded_game: Variant = MAIN_SCENE.instantiate()
	loaded_game.save_path = TEST_SAVE_PATH
	root.add_child(loaded_game)
	await process_frame
	_expect(loaded_game.suit_upgraded, "The pressure upgrade persists in the local save.")
	_expect(loaded_game.signal_found, "Story progress persists in the local save.")
	_expect(loaded_game.inventory.metal == 0 and loaded_game.inventory.kelp == 0, "The saved inventory reloads.")
	_expect(_pickup_is_collected(loaded_game, "signal_fragment"), "Collected story items stay collected after reload.")

	loaded_game.diver.global_position = Vector2(0, 200)
	loaded_game.oxygen = 0.0
	loaded_game.oxygen_empty_time = 4.9
	loaded_game._process(0.2)
	_expect(loaded_game.diver.global_position.y <= 145.0, "An empty oxygen tank triggers emergency surface rescue.")
	_expect(loaded_game.oxygen > 0.0, "Emergency rescue restores oxygen.")

	game.queue_free()
	loaded_game.queue_free()
	await process_frame
	_remove_test_save()
	if failures == 0:
		print("All gameplay smoke checks passed.")
		quit(0)
	else:
		push_error("%d gameplay smoke check(s) failed." % failures)
		quit(1)

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

func _remove_test_save() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		var error := DirAccess.remove_absolute(absolute_path)
		if error != OK:
			push_error("Could not remove smoke-test save file: %s" % error_string(error))
