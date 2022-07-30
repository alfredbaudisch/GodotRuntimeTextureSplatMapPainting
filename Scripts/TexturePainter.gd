extends Spatial

onready var mesh_instance = $"../Actors/Mesh/High"
onready var mesh_instance_low_poly = $"../Actors/Mesh/Low"
onready var uv_positions = $"../UVPosition"

onready var viewport0 = $"../DrawViewport0"

var mesh
var material
var recheck := false
var from
var to

var amount_rays = 1

var texture : Texture
var tex_size : Vector2

const ray_length = 1000

func _ready():
	mesh = mesh_instance.get_mesh()
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	uv_positions.set_mesh(mesh_instance_low_poly)

	material = mesh_instance.get_surface_material(0)
	material.set_shader_param("SplatMapTexture", viewport0.get_texture())
	
	texture  = viewport0.get_texture()
	tex_size = viewport0.get_texture().get_size()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		recheck = event.is_pressed()

func _physics_process(delta):
	if recheck:
		var space_state = get_world().direct_space_state;
			
		for ray_idx in range(amount_rays):
			var to
			
			if ray_idx <= 2:
				to = $"../Player1st/SpringArm/Camera".global_transform.xform(Vector3(0,ray_idx * viewport0.brush_size() * .2,-1000))
			else:
				to = $"../Player1st/SpringArm/Camera".global_transform.xform(Vector3(0, (ray_idx - 2) * viewport0.brush_size() * .2 * -1,-1000))
						
			var result = space_state.intersect_ray(
				$"../Player1st/SpringArm/Camera".global_transform.origin,
				to, [self], 16);
				
			if result.size() > 0:
				var uv = uv_positions.get_uv_coords(result.position, result.normal, true)
				
				if uv:
					get("viewport" + str(ray_idx)).move_brush(uv * tex_size)


func _on_Button_pressed():
	# To save the render target splat map on disk !!change the path!!
	viewport0.get_texture().get_data().save_png("D:/buffer0.png")
	pass
