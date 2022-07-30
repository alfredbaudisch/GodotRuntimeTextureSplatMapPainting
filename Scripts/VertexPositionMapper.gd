extends Node

var meshtool
var mesh
var mesh_instance

var transform_vertex_to_global = true

var _face_count := 0
var _world_normals := PoolVector3Array()
var _world_vertices := []
var _local_face_vertices := []

func set_mesh(_mesh_instance):
	mesh_instance = _mesh_instance
	mesh = _mesh_instance.mesh
	
	meshtool = MeshDataTool.new()
	meshtool.create_from_surface(mesh, 0)	
		
	_face_count = meshtool.get_face_count()
	_world_normals.resize(_face_count)
	
	_load_mesh_data()
	
func _resize_pools():
	pass

func _load_mesh_data():
	for idx in range(_face_count):
		_world_normals[idx] = mesh_instance.global_transform.basis.xform(meshtool.get_face_normal(idx))
		
		var fv1 = meshtool.get_face_vertex(idx, 0)
		var fv2 = meshtool.get_face_vertex(idx, 1)
		var fv3 = meshtool.get_face_vertex(idx, 2)
		
		_local_face_vertices.append([fv1, fv2, fv3])		
		
		_world_vertices.append([
			mesh_instance.global_transform.xform(meshtool.get_vertex(fv1)),
			mesh_instance.global_transform.xform(meshtool.get_vertex(fv2)),
			mesh_instance.global_transform.xform(meshtool.get_vertex(fv3)),
		])
		
func get_face(point, normal, epsilon = 0.2):
	for idx in range(_face_count):
		var world_normal = _world_normals[idx]
		
		if !equals_with_epsilon(world_normal, normal, epsilon):
			continue
			
		var vertices = _world_vertices[idx]		
		
		var bc = is_point_in_triangle(point, vertices[0], vertices[1], vertices[2])		
		if bc:
			return [idx, vertices, bc]
			
	return null

func get_uv_coords(point, normal, transform = true):
	# Gets the uv coordinates on the mesh given a point on the mesh and normal
	# these values can be obtained from a raycast
	transform_vertex_to_global = transform
	
	var face = get_face(point, normal)
	if face == null:
		return null
		
	var bc = face[2]
#
	var uv1 = meshtool.get_vertex_uv(_local_face_vertices[face[0]][0])
	var uv2 = meshtool.get_vertex_uv(_local_face_vertices[face[0]][1])
	var uv3 = meshtool.get_vertex_uv(_local_face_vertices[face[0]][2])
	
	return (uv1 * bc.x) + (uv2 * bc.y) + (uv3 * bc.z)	

func equals_with_epsilon(v1, v2, epsilon):
	if (v1.distance_to(v2) < epsilon):
		return true
	return false
	
func cart2bary(p : Vector3, a : Vector3, b : Vector3, c: Vector3) -> Vector3:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	return Vector3(u, v, w)

func transfer_point(from : Basis, to : Basis, point : Vector3) -> Vector3:
	return (to * from.inverse()).xform(point)
	
func bary2cart(a : Vector3, b : Vector3, c: Vector3, barycentric: Vector3) -> Vector3:
	return barycentric.x * a + barycentric.y * b + barycentric.z * c
	
func is_point_in_triangle(point, v1, v2, v3):
	var bc = cart2bary(point, v1, v2, v3)	
	
	if (bc.x < 0 or bc.x > 1) or (bc.y < 0 or bc.y > 1) or (bc.z < 0 or bc.z > 1):
		return null
		
	return bc
