extends Node2D
class_name OceanWorld

const BACKDROP := preload("res://assets/art/abyss_environment.svg")
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
const WATER_TOP := -380.0
const DEPTH_TINT := Color(0.46, 0.67, 0.91, 0.84)

var bubbles: Array[Sprite2D] = []
var bubble_rises: Array[float] = []
var elapsed := 0.0

func _ready() -> void:
	var backdrop := Sprite2D.new()
	backdrop.texture = BACKDROP
	backdrop.position = Vector2(0, WATER_TOP + 1480.0)
	backdrop.scale.x = 1.48
	backdrop.z_index = -30
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(backdrop)

	_add_escape_pod()
	_add_reef_life()
	_add_trench_floor()
	_add_bubbles()

func _process(delta: float) -> void:
	elapsed += delta
	for index in range(bubbles.size()):
		var bubble := bubbles[index]
		bubble.position.y -= bubble_rises[index] * delta
		bubble.position.x += sin(elapsed * 0.85 + float(index) * 2.1) * delta * 8.0
		if bubble.position.y < 160.0:
			bubble.position.y = 2050.0 + fmod(float(index) * 137.0, 460.0)
			bubble.position.x = sin(float(index) * 3.37) * 930.0

func _add_reef_life() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 98241

	for index in range(36):
		var side := -1.0 if index % 2 == 0 else 1.0
		var plant := Sprite2D.new()
		plant.texture = SEAWEED_TEXTURES[random.randi_range(0, SEAWEED_TEXTURES.size() - 1)]
		var depth := random.randf_range(500.0, 1030.0)
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
			random.randf_range(320.0, 1110.0)
		)
		rock.scale = Vector2.ONE * random.randf_range(0.8, 2.0)
		var fade := 1.0 - clampf((rock.position.y - 300.0) / 2600.0, 0.0, 0.4)
		rock.modulate = Color(0.65, 0.9, 1.0, fade)
		rock.z_index = -8
		add_child(rock)

func _add_escape_pod() -> void:
	var pod := Sprite2D.new()
	pod.texture = ESCAPE_POD_ART
	pod.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pod.position = Vector2(-185.0, 88.0)
	pod.scale = Vector2(1.06, 1.06)
	pod.z_index = 2
	add_child(pod)

func _add_trench_floor() -> void:
	var terrain_sprite := Sprite2D.new()
	terrain_sprite.name = "TrenchFloor"
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
