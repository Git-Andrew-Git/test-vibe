extends Node2D
class_name AlienLifeform

var species_id := ""
var lifeform_id := ""
var specimen_name := ""
var resource_id := ""
var yield_amount := 1
var recipe_id := ""
var species_kind := "flora"
var aggressive := false
var sprite_texture: Texture2D
var harvested := false
var scanned := false
var icon: Sprite2D
var home_position := Vector2.ZERO
var swim_phase := 0.0
var stun_remaining := 0.0

func _ready() -> void:
	home_position = position
	swim_phase = float(hash(species_id)) * 0.001
	icon = Sprite2D.new()
	icon.texture = sprite_texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.scale = Vector2(0.92, 0.92)
	add_child(icon)

func _process(delta: float) -> void:
	if harvested:
		return
	if species_kind == "fauna":
		if stun_remaining > 0.0:
			stun_remaining = maxf(0.0, stun_remaining - delta)
		else:
			position.x = move_toward(
				position.x,
				home_position.x + sin(Time.get_ticks_msec() * 0.0003 + swim_phase) * 42.0,
				delta * 12.0
			)
			position.y = home_position.y + sin(Time.get_ticks_msec() * 0.0012 + swim_phase) * 10.0
	else:
		position.y = home_position.y + sin(Time.get_ticks_msec() * 0.001 + swim_phase) * 3.5

	if scanned:
		var pulse := 0.86 + sin(Time.get_ticks_msec() * 0.006 + swim_phase) * 0.12
		icon.modulate = Color(0.66, 1.0, 0.95, pulse)
	else:
		icon.modulate = Color.WHITE

func collect() -> void:
	harvested = true
	icon.hide()

func stun() -> void:
	stun_remaining = 5.0
	icon.modulate = Color(0.65, 0.88, 1.0)
