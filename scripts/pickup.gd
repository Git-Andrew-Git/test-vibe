extends Node2D
class_name SalvagePickup

const ICONS := {
	"metal": preload("res://assets/art/driftmetal.svg"),
	"kelp": preload("res://assets/art/lumen_kelp.svg"),
	"story": preload("res://assets/art/signal_fragment.svg")
}

var pickup_id := ""
var title := ""
var category := ""
var amount := 1
var collected := false
var story_text := ""
var icon: Sprite2D

func _ready() -> void:
	icon = Sprite2D.new()
	icon.texture = ICONS[category]
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(icon)

func collect() -> void:
	collected = true
	icon.hide()
