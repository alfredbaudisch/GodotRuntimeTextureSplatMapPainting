extends Viewport

onready var brush = $Brush

func move_brush(position : Vector2):
	set_update_mode(UPDATE_ONCE)
	brush.set_position(position)

func brush_size():
	return brush.texture.get_height()
