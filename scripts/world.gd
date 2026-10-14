extends Node2D
class_name OceanWorld

const BACKDROP := preload("res://assets/art/abyss_environment.svg")
const SURFACE_ART := preload("res://assets/art/surface_world.svg")
const LIFE_ATLAS := preload("res://assets/art/alien_life.svg")
const SEAWEED_TEXTURES := [
	preload("res://assets/kenney_fish_pack/background_seaweed_a.png"),
	preload("res://assets/kenney_fish_pack/background_seaweed_b.png"),
	preload("res://assets/kenney_fish_pack/background_seaweed_c.png"),
	preload("res://assets/kenney_fish_pack/background_seaweed_d.png"),
	preload("res://assets/kenney_fish_pack/background_seaweed_e.png"),
	preload("res://assets/kenney_fish_pack/background_seaweed_f.png"),
	preload("res://assets/kenney_fish_pack/background_seaweed_g.png"),
	preload("res://assets/kenney_fish_pack/background_seaweed_h.png")
]
const ROCK_TEXTURES := [
	preload("res://assets/kenney_fish_pack/background_rock_a.png"),
	preload("res://assets/kenney_fish_pack/background_rock_b.png")
]
const BUBBLE_TEXTURES := [
	preload("res://assets/kenney_fish_pack/bubble_a.png"),
	preload("res://assets/kenney_fish_pack/bubble_b.png"),
	preload("res://assets/kenney_fish_pack/bubble_c.png")
]
const ESCAPE_POD_ART := preload("res://assets/art/escape_pod.svg")
const TRENCH_FLOOR_ART := preload("res://assets/art/trench_floor.svg")

const WORLD_WIDTH := 4400.0
const WATER_SURFACE_Y := 0.0
const DAY_LENGTH_SECONDS := 240.0
const WEATHER_LENGTH_SECONDS := 54.0
const WEATHER_TYPES := ["CALM", "RAIN", "MIST", "SQUALL"]

var bubbles: Array[Sprite2D] = []
var bubble_rises: Array[float] = []
var surface_creatures: Array[Sprite2D] = []
var surface_creature_origins: Array[Vector2] = []
var elapsed := 0.0
var daylight := 1.0
var weather := "CALM"
var weather_intensity := 0.0
var ambient_tint := Color.WHITE

func _ready() -> void:
	var backdrop := Sprite2D.new()
	backdrop.texture = BACKDROP
	backdrop.position = Vector2(0, -380.0 + 1480.0)
	backdrop.scale.x = 1.48
	backdrop.z_index = -30
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(backdrop)

	var surface := Sprite2D.new()
	surface.texture = SURFACE_ART
	surface.position = Vector2(0.0, -465.0)
	surface.z_index = -20
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(surface)

	_add_escape_pod()
	_add_surface_creatures()
	_add_reef_life()
	_add_terrain()
	_add_trench_floor()
	_add_bubbles()
	_update_weather_state()

func _process(delta: float) -> void:
	elapsed += delta
	daylight = (cos(elapsed * TAU / DAY_LENGTH_SECONDS) + 1.0) * 0.5
	_update_weather_state()
	ambient_tint = Color(0.40, 0.56, 0.84).lerp(Color.WHITE, daylight)
	if weather == "SQUALL":
		ambient_tint = ambient_tint.lerp(Color(0.55, 0.67, 0.83), 0.38)
	elif weather == "MIST":
		ambient_tint = ambient_tint.lerp(Color(0.78, 0.86, 0.88), 0.18)

	for index in range(bubbles.size()):
		var bubble := bubbles[index]
		bubble.position.y -= bubble_rises[index] * delta
		bubble.position.x += sin(elapsed * 0.85 + float(index) * 2.1) * delta * 8.0
		if bubble.position.y < 160.0:
			bubble.position.y = 2150.0 + fmod(float(index) * 137.0, 460.0)
			bubble.position.x = sin(float(index) * 3.37) * 930.0

	for index in range(surface_creatures.size()):
		var creature := surface_creatures[index]
		var origin := surface_creature_origins[index]
		var direction := 1.0 if index % 2 == 0 else -1.0
		creature.position.x = origin.x + sin(elapsed * 0.08 + float(index)) * 310.0
		creature.position.y = origin.y + sin(elapsed * 0.7 + float(index) * 2.0) * 15.0
		creature.flip_h = sin(elapsed * 0.08 + float(index)) * direction < 0.0

	queue_redraw()

func _draw() -> void:
	_draw_sky_objects()
	_draw_water_surface()
	_draw_caustics()
	_draw_weather()

func _draw_sky_objects() -> void:
	var orbit := elapsed * TAU / DAY_LENGTH_SECONDS
	var sky_x := sin(orbit) * 1120.0
	var sun_height := 450.0 + cos(orbit) * 260.0
	var alpha := clampf(daylight * 1.6, 0.0, 1.0)
	if alpha > 0.02:
		draw_circle(Vector2(sky_x, -sun_height), 64.0, Color(1.0, 0.83, 0.47, alpha * 0.16))
		draw_circle(Vector2(sky_x, -sun_height), 30.0, Color(1.0, 0.91, 0.69, alpha))
	var night_alpha := 1.0 - daylight
	if night_alpha > 0.02:
		draw_circle(Vector2(-sky_x, -sun_height), 25.0, Color(0.80, 0.94, 1.0, night_alpha))
		for index in range(22):
			var star_x := sin(float(index) * 17.3) * 1460.0
			var star_y := -200.0 - fmod(float(index) * 79.0, 670.0)
			var twinkle := 0.3 + 0.7 * absf(sin(elapsed * 1.2 + float(index)))
			draw_circle(Vector2(star_x, star_y), 1.4, Color(0.82, 0.96, 1.0, night_alpha * twinkle))

	for index in range(5):
		var cloud_x := fposmod(float(index) * 960.0 + elapsed * 7.0, 4200.0) - 2100.0
		var cloud_y := -610.0 - float(index % 2) * 100.0
		var cloud_color := Color(0.81, 0.94, 0.94, 0.52 * daylight)
		if weather == "MIST":
			cloud_color = Color(0.75, 0.84, 0.89, 0.72)
		draw_circle(Vector2(cloud_x, cloud_y), 68.0, cloud_color)
		draw_circle(Vector2(cloud_x + 56.0, cloud_y + 14.0), 53.0, cloud_color)
		draw_circle(Vector2(cloud_x - 48.0, cloud_y + 17.0), 49.0, cloud_color)

func _draw_water_surface() -> void:
	var points := PackedVector2Array()
	var storm_factor := 1.0 if weather == "SQUALL" else 0.0
	var wave_height := lerpf(6.0, 19.0, storm_factor)
	for index in range(161):
		var x := -2200.0 + float(index) * 27.5
		var y := WATER_SURFACE_Y + sin(x * 0.009 + elapsed * 2.3) * wave_height
		y += sin(x * 0.021 - elapsed * 1.45) * wave_height * 0.32
		points.append(Vector2(x, y))
	for index in range(points.size() - 1):
		var first := points[index]
		var second := points[index + 1]
		var wave_color := Color(0.56, 0.96, 0.91, 0.94 * daylight + 0.24)
		draw_line(first, second, wave_color, 5.0 if weather == "SQUALL" else 3.0, true)
		draw_line(first + Vector2(0.0, 12.0), second + Vector2(0.0, 12.0), Color(0.13, 0.73, 0.81, 0.38), 2.0, true)
		draw_colored_polygon(PackedVector2Array([
			first,
			second,
			second + Vector2(0.0, 32.0),
			first + Vector2(0.0, 32.0)
		]), Color(0.55, 0.96, 0.94, 0.08))

func _draw_caustics() -> void:
	var sun_strength := daylight * (0.32 if weather == "CALM" else 0.12)
	for index in range(13):
		var x := -1160.0 + float(index) * 190.0 + sin(elapsed * 0.3 + float(index)) * 50.0
		var sway := sin(elapsed * 0.4 + float(index) * 1.7) * 38.0
		var color := Color(0.56, 0.98, 0.89, sun_strength)
		draw_line(Vector2(x, 45.0), Vector2(x + sway, 360.0), color, 5.0, true)
		draw_line(Vector2(x + 12.0, 90.0), Vector2(x + sway + 21.0, 420.0), Color(color, sun_strength * 0.42), 2.0, true)

func _draw_weather() -> void:
	if weather == "RAIN" or weather == "SQUALL":
		var rain_alpha := 0.26 if weather == "RAIN" else 0.46
		for index in range(94):
			var x := fposmod(float(index) * 83.0 + elapsed * (260.0 if weather == "SQUALL" else 145.0), 4200.0) - 2100.0
			var y := -850.0 + fposmod(float(index) * 119.0 + elapsed * (530.0 if weather == "SQUALL" else 340.0), 820.0)
			draw_line(Vector2(x, y), Vector2(x - 9.0, y + 27.0), Color(0.70, 0.88, 0.96, rain_alpha), 1.4, true)
	if weather == "MIST":
		for index in range(4):
			var x := fposmod(float(index) * 1100.0 + elapsed * 22.0, 4400.0) - 2200.0
			var y := -140.0 + float(index) * 44.0 + sin(elapsed * 0.2 + float(index)) * 12.0
			draw_rect(Rect2(x, y, 780.0, 28.0), Color(0.81, 0.91, 0.93, 0.12))

func _update_weather_state() -> void:
	var next_weather: String = WEATHER_TYPES[int(floor(elapsed / WEATHER_LENGTH_SECONDS)) % WEATHER_TYPES.size()]
	if weather != next_weather:
		weather = next_weather
	weather_intensity = (
		0.82 if weather == "SQUALL"
		else 0.52 if weather == "RAIN"
		else 0.34 if weather == "MIST"
		else 0.0
	)

func _add_surface_creatures() -> void:
	for index in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = LIFE_ATLAS
		atlas.region = Rect2i(128 if index % 2 == 0 else 0, 0, 128, 128)
		var creature := Sprite2D.new()
		creature.texture = atlas
		creature.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		creature.position = Vector2(-1300.0 + float(index) * 860.0, -70.0 - float(index % 2) * 100.0)
		creature.scale = Vector2(0.40, 0.40)
		creature.modulate = Color(0.73, 1.0, 0.94, 0.92)
		creature.z_index = -4
		add_child(creature)
		surface_creatures.append(creature)
		surface_creature_origins.append(creature.position)

func _add_reef_life() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 98241

	for index in range(36):
		var side := -1.0 if index % 2 == 0 else 1.0
		var plant := Sprite2D.new()
		plant.texture = SEAWEED_TEXTURES[random.randi_range(0, SEAWEED_TEXTURES.size() - 1)]
		var depth := random.randf_range(540.0, 1900.0)
		plant.position = Vector2(
			side * random.randf_range(390.0, 930.0),
			depth + 40.0
		)
		var scale_factor := random.randf_range(1.35, 2.45)
		plant.scale = Vector2(scale_factor, scale_factor)
		plant.modulate = Color(1.0, 1.0, 1.0, random.randf_range(0.72, 0.98))
		plant.z_index = -4 if side > 0.0 else 1
		add_child(plant)

	for index in range(48):
		var rock := Sprite2D.new()
		rock.texture = ROCK_TEXTURES[random.randi_range(0, ROCK_TEXTURES.size() - 1)]
		var side := -1.0 if index % 2 == 0 else 1.0
		rock.position = Vector2(
			side * random.randf_range(500.0, 1030.0),
			random.randf_range(360.0, 1750.0)
		)
		rock.scale = Vector2.ONE * random.randf_range(0.8, 2.0)
		var fade := 1.0 - clampf((rock.position.y - 300.0) / 3100.0, 0.0, 0.4)
		rock.modulate = Color(0.65, 0.9, 1.0, fade)
		rock.z_index = -8
		add_child(rock)

func _add_escape_pod() -> void:
	var pod := Sprite2D.new()
	pod.texture = ESCAPE_POD_ART
	pod.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pod.position = Vector2(-185.0, -88.0)
	pod.scale = Vector2(1.06, 1.06)
	pod.z_index = 2
	add_child(pod)

func _add_terrain() -> void:
	_add_rock_formation(
		"WestCave",
		PackedVector2Array([
			Vector2(-1420, 520), Vector2(-1360, 440), Vector2(-1220, 425),
			Vector2(-1040, 452), Vector2(-880, 425), Vector2(-650, 450),
			Vector2(-505, 480), Vector2(-465, 760), Vector2(-700, 785),
			Vector2(-980, 770), Vector2(-1260, 800), Vector2(-1440, 755)
		]),
		Color(0.11, 0.29, 0.44)
	)
	_add_rock_formation(
		"EastCave",
		PackedVector2Array([
			Vector2(460, 1060), Vector2(535, 985), Vector2(730, 960),
			Vector2(920, 995), Vector2(1100, 950), Vector2(1300, 990),
			Vector2(1410, 1060), Vector2(1440, 1330), Vector2(1190, 1360),
			Vector2(940, 1340), Vector2(690, 1380), Vector2(485, 1340)
		]),
		Color(0.13, 0.26, 0.40)
	)
	_add_rock_formation(
		"CentralPinnacle",
		PackedVector2Array([
			Vector2(-250, 1640), Vector2(-180, 1540), Vector2(-80, 1515),
			Vector2(40, 1560), Vector2(155, 1530), Vector2(275, 1600),
			Vector2(320, 1780), Vector2(180, 1825), Vector2(-130, 1810)
		]),
		Color(0.13, 0.31, 0.45)
	)
	_add_cave_roof("WestCaveRoof", Rect2(-1380.0, 320.0, 860.0, 60.0))
	_add_cave_roof("EastCaveRoof", Rect2(520.0, 820.0, 790.0, 60.0))
	_add_cave_shadow("WestCaveShadow", Rect2(-1270.0, 380.0, 720.0, 41.0))
	_add_cave_shadow("EastCaveShadow", Rect2(590.0, 880.0, 660.0, 66.0))
	_add_terrain_floor("TrenchGround", Rect2(-2200.0, 2290.0, 4400.0, 360.0))

func _add_rock_formation(formation_name: String, points: PackedVector2Array, color: Color) -> void:
	var rock := Polygon2D.new()
	rock.name = formation_name
	rock.polygon = points
	rock.color = color
	rock.z_index = -2
	add_child(rock)

	var highlight := Line2D.new()
	highlight.points = PackedVector2Array(points.slice(0, 7))
	highlight.width = 7.0
	highlight.default_color = Color(0.42, 0.77, 0.78, 0.55)
	highlight.z_index = -1
	add_child(highlight)

	var body := StaticBody2D.new()
	body.name = "%sCollision" % formation_name
	body.collision_layer = 2
	body.collision_mask = 0
	var collision := CollisionPolygon2D.new()
	collision.polygon = points
	body.add_child(collision)
	add_child(body)

func _add_cave_roof(roof_name: String, bounds: Rect2) -> void:
	var roof := Polygon2D.new()
	roof.name = roof_name
	roof.polygon = PackedVector2Array([
		bounds.position,
		bounds.position + Vector2(bounds.size.x, 0.0),
		bounds.position + bounds.size,
		bounds.position + Vector2(0.0, bounds.size.y)
	])
	roof.color = Color(0.09, 0.24, 0.37)
	roof.z_index = 0
	add_child(roof)
	var body := StaticBody2D.new()
	body.collision_layer = 2
	var collision := CollisionPolygon2D.new()
	collision.polygon = roof.polygon
	body.add_child(collision)
	add_child(body)

func _add_cave_shadow(shadow_name: String, bounds: Rect2) -> void:
	var shadow := Polygon2D.new()
	shadow.name = shadow_name
	shadow.polygon = PackedVector2Array([
		bounds.position,
		bounds.position + Vector2(bounds.size.x, 0.0),
		bounds.position + bounds.size,
		bounds.position + Vector2(0.0, bounds.size.y)
	])
	shadow.color = Color(0.008, 0.025, 0.06, 0.94)
	shadow.z_index = 1
	add_child(shadow)

func _add_terrain_floor(floor_name: String, bounds: Rect2) -> void:
	var ground := Polygon2D.new()
	ground.name = floor_name
	ground.polygon = PackedVector2Array([
		bounds.position,
		bounds.position + Vector2(bounds.size.x, 0.0),
		bounds.position + bounds.size,
		bounds.position + Vector2(0.0, bounds.size.y)
	])
	ground.color = Color(0.06, 0.12, 0.25)
	ground.z_index = -2
	add_child(ground)
	var body := StaticBody2D.new()
	body.collision_layer = 2
	var collision := CollisionPolygon2D.new()
	collision.polygon = ground.polygon
	body.add_child(collision)
	add_child(body)

func _add_trench_floor() -> void:
	var terrain_sprite := Sprite2D.new()
	terrain_sprite.name = "TrenchFloorArt"
	terrain_sprite.texture = TRENCH_FLOOR_ART
	terrain_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	terrain_sprite.position = Vector2(0.0, 2240.0)
	terrain_sprite.scale = Vector2(1.48, 1.0)
	terrain_sprite.z_index = -3
	add_child(terrain_sprite)

func _add_bubbles() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 22117
	for index in range(46):
		var bubble := Sprite2D.new()
		bubble.texture = BUBBLE_TEXTURES[random.randi_range(0, BUBBLE_TEXTURES.size() - 1)]
		bubble.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bubble.position = Vector2(
			random.randf_range(-1000.0, 1000.0),
			random.randf_range(160.0, 2450.0)
		)
		var scale_factor := random.randf_range(0.38, 0.92)
		bubble.scale = Vector2.ONE * scale_factor
		bubble.modulate = Color(0.80, 1.0, 1.0, random.randf_range(0.22, 0.63))
		bubble.z_index = -1
		add_child(bubble)
		bubbles.append(bubble)
		bubble_rises.append(random.randf_range(8.0, 24.0))
