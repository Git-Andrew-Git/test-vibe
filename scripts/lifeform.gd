extends Node2D
class_name AlienLifeform

var species_id := ""
var lifeform_id := ""
var specimen_name := ""
var resource_id := ""
var yield_amount := 1
var recipe_id := ""
var species_kind := "flora"
var flora_behavior := ""
var ability := ""
var ability_cooldown := 3.0
var ability_active_time := 0.0
var aggressive := false
var hunter_target: Node2D
var sprite_texture: Texture2D
var harvested := false
var scanned := false
var icon: Sprite2D
var swim_appendages: Array[Line2D] = []
var home_position := Vector2.ZERO
var swim_phase := 0.0
var stun_remaining := 0.0
var behavior_time := 0.0

func _ready() -> void:
	home_position = position
	swim_phase = float(hash(species_id)) * 0.001
	icon = Sprite2D.new()
	icon.texture = sprite_texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.scale = Vector2(0.23, 0.23)
	add_child(icon)
	if species_kind == "fauna":
		_create_swim_appendages()

func _process(delta: float) -> void:
	if harvested:
		return
	behavior_time += delta
	stun_remaining = maxf(0.0, stun_remaining - delta)
	ability_cooldown = maxf(0.0, ability_cooldown - delta)
	ability_active_time = maxf(0.0, ability_active_time - delta)
	_animate_swim_appendages()
	if species_kind == "fauna":
		queue_redraw()
	if ability_active_time > 0.0:
		queue_redraw()
	if species_kind == "fauna":
		if stun_remaining > 0.0:
			return
		if ability == "electric_lunge" and is_instance_valid(hunter_target):
			var lunge_distance := global_position.distance_to(hunter_target.global_position)
			if lunge_distance < 300.0 and ability_cooldown <= 0.0:
				var lunge_direction := (hunter_target.global_position - global_position).normalized()
				var lunge_offset := lunge_direction * minf(95.0, lunge_distance)
				global_position += lunge_offset
				home_position += lunge_offset
				activate_ability()
				ability_cooldown = 5.0
		position.x = move_toward(
			position.x,
			home_position.x + sin(Time.get_ticks_msec() * 0.0003 + swim_phase) * 42.0,
			delta * 12.0
		)
		position.y = home_position.y + sin(Time.get_ticks_msec() * 0.0012 + swim_phase) * 10.0
	elif flora_behavior == "stalk":
		if stun_remaining > 0.0:
			return
		if is_instance_valid(hunter_target) and global_position.distance_to(hunter_target.global_position) < 390.0:
			var direction := (hunter_target.global_position - global_position).normalized()
			global_position += direction * minf(30.0 * delta, global_position.distance_to(hunter_target.global_position))
			icon.rotation = direction.x * 0.16
			if global_position.distance_to(hunter_target.global_position) < 190.0 and ability_cooldown <= 0.0:
				activate_ability()
				ability_cooldown = 6.0
		else:
			position = position.move_toward(
				home_position + Vector2(sin(behavior_time * 0.7 + swim_phase) * 18.0, 0.0),
				delta * 7.0
			)
	else:
		match flora_behavior:
			"sway":
				icon.rotation = sin(behavior_time * 1.2 + swim_phase) * 0.12
				position.y = home_position.y + sin(behavior_time * 1.7 + swim_phase) * 5.0
			"creep":
				position.x = home_position.x + sin(behavior_time * 0.35 + swim_phase) * 24.0
				position.y = home_position.y + sin(behavior_time * 0.7 + swim_phase) * 2.0
			"pulse":
				position.y = home_position.y + sin(behavior_time * 1.1 + swim_phase) * 7.0
				var pulse := 0.92 + sin(behavior_time * 2.2 + swim_phase) * 0.08
				icon.scale = Vector2.ONE * pulse

	if scanned:
		var pulse := 0.86 + sin(Time.get_ticks_msec() * 0.006 + swim_phase) * 0.12
		if stun_remaining > 0.0:
			icon.modulate = Color(0.65, 0.88, 1.0, pulse)
		else:
			icon.modulate = Color(0.66, 1.0, 0.95, pulse)
	else:
		icon.modulate = Color(0.65, 0.88, 1.0) if stun_remaining > 0.0 else Color.WHITE

func collect() -> void:
	harvested = true
	icon.hide()

func _create_swim_appendages() -> void:
	var appendage_count := 5 if species_id == "moon_jelly" else 3
	var tint := Color(0.65, 1.0, 0.95, 0.88)
	if species_id == "ribbon_glider":
		tint = Color(0.64, 0.9, 1.0, 0.9)
	elif species_id == "riftstalker":
		tint = Color(1.0, 0.51, 0.77, 0.92)
	for index in range(appendage_count):
		var appendage := Line2D.new()
		appendage.width = 3.0 if species_id == "moon_jelly" else 3.8
		appendage.default_color = tint
		appendage.begin_cap_mode = Line2D.LINE_CAP_ROUND
		appendage.end_cap_mode = Line2D.LINE_CAP_ROUND
		appendage.joint_mode = Line2D.LINE_JOINT_ROUND
		appendage.antialiased = true
		appendage.z_index = 1
		add_child(appendage)
		swim_appendages.append(appendage)

func _animate_swim_appendages() -> void:
	for index in range(swim_appendages.size()):
		var appendage := swim_appendages[index]
		var phase := behavior_time * (4.2 if species_id == "moon_jelly" else 3.2)
		var offset := float(index) - float(swim_appendages.size() - 1) * 0.5
		var wave := sin(phase + float(index) * 0.9 + swim_phase)
		var points := PackedVector2Array()
		if species_id == "moon_jelly":
			var start_x := offset * 12.0
			points.append(Vector2(start_x, 25.0))
			points.append(Vector2(start_x + wave * 5.0, 43.0))
			points.append(Vector2(start_x - wave * 10.0, 60.0))
			points.append(Vector2(start_x + wave * 15.0, 77.0))
		elif species_id == "ribbon_glider":
			var glider_side := -1.0 if index == 0 else 1.0
			var glider_start := Vector2(glider_side * 28.0, offset * 12.0)
			points.append(glider_start)
			points.append(glider_start + Vector2(glider_side * 13.0, wave * 8.0))
			points.append(glider_start + Vector2(glider_side * 27.0, -wave * 12.0))
			points.append(glider_start + Vector2(glider_side * 39.0, wave * 17.0))
		else:
			var body_side := -1.0 if index % 2 == 0 else 1.0
			var body_start := Vector2(body_side * 27.0, offset * 9.0)
			points.append(body_start)
			points.append(body_start + Vector2(body_side * 12.0, wave * 7.0))
			points.append(body_start + Vector2(body_side * 22.0, 10.0 + wave * 12.0))
			points.append(body_start + Vector2(body_side * 31.0, 18.0 - wave * 13.0))
		appendage.points = points

func stun() -> void:
	stun_remaining = 5.0
	icon.modulate = Color(0.65, 0.88, 1.0)

func activate_ability() -> void:
	ability_active_time = 0.9
	queue_redraw()

func _draw() -> void:
	if ability_active_time <= 0.0:
		return
	var progress := 1.0 - ability_active_time / 0.9
	var radius := 24.0 + progress * 150.0
	var tint := Color(0.35, 1.0, 0.78, 1.0)
	match ability:
		"current_burst":
			tint = Color(0.34, 0.88, 1.0)
		"shell_guard":
			tint = Color(0.62, 0.83, 1.0)
		"electric_lunge":
			tint = Color(0.95, 0.42, 1.0)
		"warm_current":
			tint = Color(1.0, 0.65, 0.29)
		"healing_spores":
			tint = Color(1.0, 0.51, 0.84)
		"vine_snare":
			tint = Color(1.0, 0.35, 0.39)
		"lure_flash":
			tint = Color(1.0, 0.95, 0.48)
	var alpha := clampf(1.0 - progress, 0.0, 1.0)
	for ring in range(3):
		var ring_radius := radius - float(ring) * 19.0
		draw_arc(
			Vector2.ZERO,
			ring_radius,
			float(ring) * 0.54,
			TAU - float(ring) * 0.37,
			36,
			Color(tint, alpha * (0.82 - float(ring) * 0.16)),
			3.0 if ring == 0 else 1.8,
			true
		)
	if ability == "electric_lunge":
		for bolt in range(5):
			var bolt_x := float(bolt - 2) * 11.0
			draw_line(
				Vector2(bolt_x, -28.0),
				Vector2(bolt_x + 7.0, -7.0),
				Color(tint, alpha),
				2.8,
				true
			)
			draw_line(
				Vector2(bolt_x + 7.0, -7.0),
				Vector2(bolt_x - 3.0, 12.0),
				Color(tint, alpha),
				2.8,
				true
			)
	elif ability == "vine_snare":
		for tendril in range(4):
			var side := -1.0 if tendril % 2 == 0 else 1.0
			var start := Vector2(side * 17.0, 8.0)
			var end := Vector2(side * radius * 0.72, -radius * 0.4)
			draw_line(start, end, Color(tint, alpha), 3.0, true)
