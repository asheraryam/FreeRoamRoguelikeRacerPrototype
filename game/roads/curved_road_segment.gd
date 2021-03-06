tool
extends "helpers.gd"

# class member variables go here, for example:
var m = SpatialMaterial.new()
var points_center
var points_inner
var points_outer

# nav stuff
var points_inner_nav
var points_outer_nav

#sidewalks
export(bool) var sidewalks = false
var points_inner_side
var points_outer_side

export(bool) var barriers = true
var points_outer_barrier
var barrier_quads = []

var road_height = 0.01

#road variables
export var lane_width = 3
export var radius = 15
export(Vector2) var loc = Vector2(0,0)
export(bool) var left_turn = false
#export var angle = 120
export(int) var start_angle = 90
export(int) var end_angle = 180
#for matching the segments
var start_point
var last
var global_start
var global_end
var relative_end
var look_at_pos
var start_axis
var end_axis

#editor drawing
var positions  = PoolVector3Array()
var left_positions = PoolVector3Array()
var right_positions = PoolVector3Array()
var draw = null

#navmesh
var nav_vertices
var nav_vertices2
var global_vertices
var global_vertices2
# margin
var margin = 1.0
var left_nav_positions = PoolVector3Array()
var right_nav_positions = PoolVector3Array()

#for minimap
var mid_point
var global_positions = PoolVector3Array()

var start_vector = Vector3()
var end_vector = Vector3()
var start_ref
var end_ref



#mesh material
export(SpatialMaterial)    var material    = preload("res://assets/road_material.tres")
export(SpatialMaterial) var sidewalk_material = preload("res://assets/cement.tres")
export(Material) var barrier_material = preload("res://assets/barrier_material.tres")

#props
var streetlight

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#add_to_group("roads")
	
	draw = get_node("draw")
	if has_node("Position3D"):
		look_at_pos = get_node("Position3D")
	
	#draw_debug_point(loc, Color(1,1,1))
	streetlight = preload("res://objects/streetlight.scn")
	
	margin = float(lane_width)/2
	
	# angle fix
	if end_angle < 0:
		end_angle = 360+end_angle
	if start_angle < 0:
		start_angle = 360+start_angle
	
	
	points_center = get_circle_arc(loc, radius, start_angle, end_angle, not left_turn)
	#how many points do we need debugged?
	var nb_points = 32
	
	#for index in range(nb_points):
		#draw_debug_point(points_center[index], Color(0, 0, 0))
		
	
	points_inner = get_circle_arc(loc, radius-lane_width, start_angle, end_angle, not left_turn)
#	for index in range(nb_points):
#		draw_debug_point(points_inner[index], Color(0.5, 0.5, 0.5))
	points_inner_nav = get_circle_arc(loc, radius-lane_width+margin, start_angle, end_angle, not left_turn)
	
	points_outer = get_circle_arc(loc, radius+lane_width, start_angle, end_angle, not left_turn)
#	for index in range(nb_points):
#		draw_debug_point(points_outer[index], Color(1, 0.5, 0.5))
	points_outer_nav = get_circle_arc(loc, radius+lane_width-margin, start_angle, end_angle, not left_turn)
	
	if sidewalks:
		points_inner_side = get_circle_arc(loc, radius-(lane_width*1.5), start_angle, end_angle, not left_turn)
		points_outer_side = get_circle_arc(loc, radius+(lane_width*1.5), start_angle, end_angle, not left_turn)
		
	if barriers:
		points_outer_barrier = get_circle_arc(loc, radius+(lane_width*1.5)+0.5, start_angle, end_angle, not left_turn)
	
	
	fix_stuff()
	create_road()
	
	# debug
#	for p in points_inner_nav:
#		debug_cube(Vector3(p.x, 0, p.y))
#
#	for p in points_outer_nav:
#		debug_cube(Vector3(p.x, 0, p.y))

#----------------------------------

#func get_start_angle():
#	var ret = 90-angle/2
#	if (start_angle != null) and (start_angle > 0):
#		return start_angle
#	elif (end_angle != null) and (end_angle > 0):
#		return end_angle - angle
#	elif (angle > 0):
#		return ret
#	
#func get_end_angle():
#	var ret = 90+angle/2
#	
#	if (start_angle != null) and (start_angle > 0):
#		##allow specifying both start and end angles
#		if (end_angle != null) and (end_angle > 0):
#			return end_angle
#		else:
#			return start_angle + angle
#	elif (end_angle != null) and (end_angle > 0):
#		return end_angle
#	elif (angle > 0):
#		return ret



func draw_debug_point(loc, color):
	.addTestColor(m, color, null, loc.x, road_height, loc.y, 0.05,0.05,0.05)

	

func fix_stuff():
	#debug
	debug()
	
	#fix rotations
	#if (!left_turn):
	set_rotation(Vector3(0,0,0))

	#fix issue
	if (get_parent().get_name() == "Placer"):
		#let the placer do its work
		get_parent().place_road()

func debug():
	start_point = Vector3(points_center[0].x, road_height, points_center[0].y) 
	Logger.road_print("Position of start point is " + String(start_point))
	#addTestColor(m, Color(0, 1,0), "start_cube", start_point.x, start_point.y, start_point.z, 0.1, 0.1, 0.1)

	last = Vector3(points_center[points_center.size()-1].x, road_height, points_center[points_center.size()-1].y)
	Logger.road_print("Position of last point is " + String(last))
	
	#var loc3d = Vector3(loc.x, 0, loc.y)
	#if (left_turn):
		#transform so that we're at our start point
		#var trans = Vector3(-start_point.x, 0, -start_point.z)
		#set_translation(trans+loc3d)
	#else:
	#	set_rotation_deg(Vector3(0, -180, 0))
		#var trans = Vector3(start_point.x, 0, start_point.z)
		#set_translation(trans+loc3d)
	
	global_end = get_global_transform().xform_inv(last)
	global_start = get_global_transform().xform_inv(start_point)
	
	#global_end = get_global_transform().xform_inv(last)
	#global_start = get_global_transform().xform_inv(start_point)
	#relative_end = start_point-last 
	
	relative_end = global_start - global_end
	Logger.road_print("Last relative to start is " + String(relative_end))
	
	var mid_loc = points_center[(round(32/2))]
	mid_point = Vector3(mid_loc.x, road_height, mid_loc.y)
	
#make the sidewalk
func make_quad(index_one, index_two, inner):
	var right_side = null
	var left_side = null
	if inner:
		if (left_turn):
			left_side = points_inner_side
			right_side = points_inner
		else:
			left_side = points_inner
			right_side = points_inner_side
	else:
		if (left_turn):
			left_side = points_outer
			right_side = points_outer_side
		else:
			left_side = points_outer_side
			right_side = points_outer
	
	if (index_one != index_two):
			var start = Vector3(right_side[index_one].x, road_height, right_side[index_one].y)
			var left = Vector3(left_side[index_one].x, road_height, left_side[index_one].y)
			var ahead_right = Vector3(right_side[index_two].x, road_height, right_side[index_two].y)
			var ahead_left = Vector3(left_side[index_two].x, road_height, left_side[index_two].y)
#			
#			if (left_turn):
#				addRoadCurve(sidewalk_material, start, left, ahead_left, ahead_right, false)
#			else:
			# the final parameter flips uvs
			addRoadCurve(sidewalk_material, start, left, ahead_left, ahead_right, false)
			# to be two-sided :P
			addRoadCurve(sidewalk_material, left, start, ahead_right, ahead_left, false)

#make the mesh (less objects)
func make_strip_single(index_one, index_two, parent):
	var right_side = null
	var left_side = null
	var center_line = null

	# necessary to draw left turn since the arc turns the other way	
	if left_turn:
		center_line = points_center
		left_side = points_inner
		right_side = points_outer
	else:
		center_line = points_center #curve_one
		left_side = points_outer #curve_three
		right_side = points_inner #curve_two
	
	

	if (left_side != null):
		if (index_one != index_two):
			var zero = Vector3(right_side[index_one].x, road_height, right_side[index_one].y)
			var one = Vector3(center_line[index_one].x, road_height, center_line[index_one].y)
			var two = Vector3(center_line[index_two].x, road_height, center_line[index_two].y)
			var three = Vector3(right_side[index_two].x, road_height, right_side[index_two].y)
			var four = Vector3(left_side[index_one].x, road_height, left_side[index_one].y)
			var five = Vector3(left_side[index_two].x, road_height, left_side[index_two].y)
			
			
			addRoadCurveTest(material, zero, one, two, three, four, five, parent)
			
						
		else:
			print("Bad indexes given")
	else:
		print("No sides given")

func make_point_array(index_one, index_two):
	var right_side = null
	var left_side = null
	var center_line = null
	
	if left_turn:
		center_line = points_center
		left_side = points_inner
		right_side = points_outer
	else:
		center_line = points_center #curve_one
		left_side = points_outer #curve_three
		right_side = points_inner #curve_two
	

	if (left_side != null):
		if (index_one != index_two):
			var zero = Vector3(right_side[index_one].x, road_height, right_side[index_one].y) #right_side.get_point_pos(index_one)
			var one = Vector3(center_line[index_one].x, road_height, center_line[index_one].y) #center_line.get_point_pos(index_one)
			var two = Vector3(center_line[index_two].x, road_height, center_line[index_two].y) #center_line.get_point_pos(index_two)
			var three = Vector3(right_side[index_two].x, road_height, right_side[index_two].y) #right_side.get_point_pos(index_two)
			var four = Vector3(left_side[index_one].x, road_height, left_side[index_one].y) #left_side.get_point_pos(index_one)
			var five = Vector3(left_side[index_two].x, road_height, left_side[index_two].y) #left_side.get_point_pos(index_two)
			
			return [zero, one, two, three, four, five]
						
		else:
			print("Bad indexes given")
	else:
		print("No sides given")


func getQuads(array):
	var quad_one = [array[0], array[1], array[2], array[3], false]
	var quad_two = [array[1], array[4], array[5], array[2], true]
	
	return [quad_one, quad_two]

func optimizedmeshCreate(quads, material):
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("plane")
	add_child(node)
	
	for qu in quads:
		addQuad(qu[0], qu[1], qu[2], qu[3], material, surface, qu[4])
	
	surface.generate_normals()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)
	
	# yay GD 3
	node.create_convex_collision()


#make the mesh
#func make_strip(index_one, index_two, right):
#	var right_side = null
#	var left_side = null
#
#	if (right):
#		right_side = curve_two
#		left_side = curve_one
#	else:
#		right_side = curve_one
#		left_side = curve_three
#	
#note: right, left, right_ahead, left_ahead
#	if (left_side != null):
#		if (index_one != index_two):
#			var start = right_side.get_point_pos(index_one)
#			var left = left_side.get_point_pos(index_one)
#			var ahead_right = right_side.get_point_pos(index_two)
#			var ahead_left = left_side.get_point_pos(index_two)
			
#			if (right):
#				addRoadCurve(material, start, left, ahead_left, ahead_right, false)
#			else:
#				addRoadCurve(material, start, left, ahead_left, ahead_right, true)
#		else:
#			print("Bad indexes given!")
#	else:
#		print("No sides given")

func get_global_positions():
	global_positions.push_back(get_global_transform().xform(start_point))
	global_positions.push_back(get_global_transform().xform(mid_point))
	global_positions.push_back(get_global_transform().xform(last))
	
	#global_positions.push_back(get_global_transform().xform(positions[0]))
	#global_positions.push_back(get_global_transform().xform(mid_point))
	#global_positions.push_back(get_global_transform().xform(positions[31]))
		
	return global_positions

	
			
func create_road():
	
	#clear to prevent weird stuff
	positions.resize(0)
	left_positions.resize(0)
	right_positions.resize(0)
	global_positions.resize(0)
	
	var nb_points = 32
	
	for index in range(nb_points-1):
		positions.push_back(Vector3(points_center[index].x, road_height, points_center[index].y))
		positions.push_back(Vector3(points_center[index+1].x, road_height, points_center[index+1].y))
		left_positions.push_back(Vector3(points_outer[index].x, road_height, points_outer[index].y))
		left_positions.push_back(Vector3(points_outer[index+1].x, road_height, points_outer[index+1].y))
		right_positions.push_back(Vector3(points_inner[index].x, road_height, points_inner[index].y))
		right_positions.push_back(Vector3(points_inner[index+1].x, road_height, points_inner[index+1].y))
			
	# add the final position that we're missing
	positions.push_back(Vector3(points_center[points_center.size()-1].x, road_height, points_center[points_center.size()-1].y))
	left_positions.push_back(Vector3(points_outer[points_outer.size()-1].x, road_height, points_outer[points_outer.size()-1].y))
	right_positions.push_back(Vector3(points_inner[points_inner.size()-1].x, road_height, points_inner[points_inner.size()-1].y))
	
#	# to perfect the connection
#	if has_node("last_pos"):
#		get_node("last_pos").set_translation(positions[positions.size()-1])
#		get_node("last_pos").set_rotation(Vector3(0,0,0))
#		get_node("last_pos").rotate_object_local(Vector3(0,0,1), deg2rad(end_angle))
#		get_node("last_pos").translate_object_local(Vector3(0, 0, lane_width))
#
#	if has_node("last_pos2"):
#		get_node("last_pos2").set_translation(positions[positions.size()-1])
#		get_node("last_pos").set_rotation(Vector3(0,0,0))
#		get_node("last_pos2").rotate_object_local(Vector3(0,0,1), deg2rad(end_angle))
#		get_node("last_pos2").translate_object_local(Vector3(0,0, -lane_width))
#
#	if has_node("last_pos3"):
#		get_node("last_pos3").set_translation(positions[positions.size()-1])
	
	# 2D because 3D doesn't have tangent()
	var start_axis_2d = -(points_center[0]-loc).tangent().normalized()*10
	var end_axis_2d = -(points_center[points_center.size()-1]-loc).tangent().normalized()*10
		
	if left_turn:
		start_axis_2d = -start_axis_2d
		end_axis_2d = -end_axis_2d
		
	
	start_axis = Vector3(start_axis_2d.x, road_height, start_axis_2d.y)
	end_axis = Vector3(end_axis_2d.x, road_height, end_axis_2d.y)
		
	start_ref = positions[0]+start_axis
	end_ref = positions[positions.size()-1]+end_axis
	var inv_end_ref = positions[positions.size()-1]-end_axis
	
	#B-A = from a to b
	start_vector = (start_ref-positions[0])
	end_vector = (positions[positions.size()-1] - end_ref)
	
	
	#only mesh in game because meshing in editor can take >900 ms
	# we need meshes to bake navmesh
	if Engine.is_editor_hint() or not Engine.is_editor_hint():
		var quads = []
		#dummy to be able to get the road mesh faster
		#var road_mesh = Spatial.new()
		#road_mesh.set_name("road_mesh")
		#add_child(road_mesh)
		
		for index in range(nb_points-1):
			var array = make_point_array(index, index+1)
			quads.append(getQuads(array)[0])
			quads.append(getQuads(array)[1])
			
			#make_strip_single(index, index+1, road_mesh)
			
			if sidewalks:
				make_quad(index, index+1, true)
				make_quad(index, index+1, false)
				
			if barriers and index > 5 and index < 25:
				var barrier_array = make_barrier_array(index)
				var got = get_barrier_quads(barrier_array)
				barrier_quads.append(got[0])
				barrier_quads.append(got[1])
				#	make_barrier(index, barrier_material, node)
			
			#nav
			#left_nav_positions.push_back(Vector3(points_outer_nav[index].x, road_height, points_outer_nav[index].y))
			#left_nav_positions.push_back(Vector3(points_outer_nav[index+1].x, road_height, points_outer_nav[index+1].y))
			#right_nav_positions.push_back(Vector3(points_inner_nav[index].x, road_height, points_inner_nav[index].y))
			#right_nav_positions.push_back(Vector3(points_inner_nav[index+1].x, road_height, points_inner_nav[index+1].y))
			
			#B-A = from a to b
			#start_vector = Vector3(positions[1]-positions[0])
			#end_vector = Vector3(positions[positions.size()-1] - positions[positions.size()-2])
		
		# add the final position that we're missing
		#left_nav_positions.push_back(Vector3(points_outer_nav[points_outer_nav.size()-1].x, road_height, points_outer_nav[points_outer_nav.size()-1].y))
		#right_nav_positions.push_back(Vector3(points_inner_nav[points_inner_nav.size()-1].x, road_height, points_inner_nav[points_inner_nav.size()-1].y))
		
		# add the final quad
		var array = make_point_array(points_center.size()-2, points_center.size()-1)
		quads.append(getQuads(array)[0])
		quads.append(getQuads(array)[1])
		
		#optimized mesh
		optimizedmeshCreate(quads, material)
		
		if barriers:
			# optimized barriers
			make_barrier(barrier_quads, barrier_material)
			
		#generate navi vertices
		#nav_vertices = get_navi_vertices()
		#nav_vertices2 = get_navi_vertices_alt()		
						
		placeStreetlight()
	if not Engine.is_editor_hint():	
		# disable the emissiveness
		reset_lite()
		
	if not Engine.is_editor_hint():
		# kill debug draw in game
		draw.queue_free()
		
	#draw an immediate line in editor instead
	else:
		#B-A = from a to b
		#start_vector = Vector3(positions[1]-positions[0])
		#end_vector = Vector3(positions[positions.size()-1] - positions[positions.size()-2])
		
		placeStreetlight()
		# debug
		#var start_positions = [left_positions[0], positions[0], right_positions[0]]
		
		#var end_positions = [left_positions[positions.size()-1], positions[positions.size()-1], right_positions[positions.size()-1]]

	
		var debug_pos = [positions[0], Vector3(loc.x, road_height, loc.y)]
		var debug_inner = [right_positions[0], Vector3(loc.x, road_height, loc.y)]
		var debug_outer = [left_positions[0], Vector3(loc.x, road_height, loc.y)]
		
		var debug_pos2 = [positions[positions.size()-1], Vector3(loc.x, road_height, loc.y)]
		var debug_inner2 = [right_positions[right_positions.size()-1], Vector3(loc.x, road_height, loc.y)]
		var debug_outer2 = [left_positions[left_positions.size()-1], Vector3(loc.x, road_height, loc.y)]
		
		var debug_start_axis = [positions[0], start_ref]
		var debug_end_axis = [positions[positions.size()-1], end_ref]
	
		if (draw != null):
			draw.draw_line(positions)
			draw.draw_line(left_positions)
			draw.draw_line(right_positions)
			# debug
			#draw.draw_line(start_positions)
			#draw.draw_line(end_positions)
			
			
			draw.draw_line(debug_pos)
			draw.draw_line(debug_pos2)
			
			draw.draw_line(debug_start_axis)
			draw.draw_line(debug_end_axis)
			
			#draw.draw_line(debug_inner)
			#draw.draw_line(debug_inner2)
			
			#draw.draw_line(debug_outer)
			#draw.draw_line(debug_outer2)
		
#		if has_node("Position3D"):
#			#print("We have position marker")
#			#get_node("Position3D").set_translation(end_ref)
#			# because look_at() uses -Z not +Z!
#			get_node("Position3D").set_translation(inv_end_ref)
		
	
#props
func placeStreetlight():
	var light = streetlight.instance()
	light.set_name("Streetlight")
	add_child(light)
	
	var num = (positions.size()/2)
	var center = Vector3(0,0,0)
	
	# test
	#debug_cube(right_positions[num])
	#debug_cube(center)
	

	var dist = 2
	# B-A: A->B
	var dir = (center-right_positions[num])
	var offset = dir.normalized() * dist
	
	#var offset = Vector3(-2,0,0)
	
	# place
	#debug_cube(right_positions[num]+offset)
	light.set_translation(right_positions[num]+offset)
	
	# rotations
	if (left_turn): #or abs(get_parent().get_parent().get_rotation_degrees().y) > 178:
		light.set_rotation_degrees(Vector3(0,90,0))
		#get_node("Debug").set_rotation_degrees(Vector3(0,90,0))
	else:
		light.set_rotation_degrees(Vector3(0,0,0))
		#get_node("Debug").set_rotation_degrees(Vector3(0,0,0))



# visual barrier
func make_barrier_array(index):
	var one = Vector3(points_outer_barrier[index].x, road_height, points_outer_barrier[index].y)
	var two = Vector3(points_outer_barrier[index+1].x, road_height, points_outer_barrier[index+1].y)
	var three = Vector3(points_outer_barrier[index+1].x, 2, points_outer_barrier[index+1].y)
	var four = Vector3(points_outer_barrier[index].x, 2, points_outer_barrier[index].y)
	
	var flip = false
	if (!left_turn):
		flip = true
		
	return [one, two, three, four, flip]
	
func get_barrier_quads(array):
	var quad_one = [array[0], array[1], array[2], array[3], array[4]]
	var quad_two = [array[3], array[2], array[1], array[0], array[4]]
	
	return [quad_one, quad_two]


func make_barrier(quads, material):
	#Create a node building that will hold the mesh
	var node = MeshInstance.new()
	node.set_name("barrier")
	add_child(node)
	
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for qu in quads:
		addQuad(qu[0], qu[1], qu[2], qu[3], material, surface, qu[4])
	
	# outside
	#addQuad(one, two, three, four, material, surface, flip)
	# inside
	#addQuad(four, three, two, one, material, surface, flip)
	
	surface.generate_normals()
	
	#Set the created mesh to the node
	node.set_mesh(surface.commit())	
	
	#Turn off shadows
	node.set_cast_shadows_setting(0)

func global_to_local_vert(pos):
	return get_global_transform().xform_inv(pos)
	
func send_positions(map):
	#print(get_name() + " sending position to map")
	global_positions = get_global_positions()
	map.add_positions(global_positions)

func lite_up():
	#print("Lit up road")
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_shader_param("emission_energy", 3)
	material.set_shader_param("emission", Color(0,0,1))
	#material.set_feature(SpatialMaterial.FEATURE_EMISSION, true)
	#material.set_emission(Color(0,0,1))
	
func reset_lite():
	#print("Reset lite")
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_shader_param("emission_energy", 0)
	#material.set_feature(SpatialMaterial.FEATURE_EMISSION, false)

func rain_shine():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_shader_param("roughness", 0.2)
	material.set_shader_param("metallic", 0.85)
	
func no_rain():
	var material = get_node("plane").get_mesh().surface_get_material(0)
	material.set_shader_param("roughness", 1.0)
	material.set_shader_param("metallic", 0.0)
	#material.set_roughness(1.0)
	#material.set_metallic(0.0)
	
func debug_cube(loc):
	var mesh = CubeMesh.new()
	mesh.set_size(Vector3(0.5,0.5,0.5))
	var node = MeshInstance.new()
	node.set_mesh(mesh)
	node.set_name("Debug")
	add_child(node)
	node.set_translation(loc)

		
# navmesh
#func get_navi_vertices():
#	var nav_vertices = PoolVector3Array()
#	for index in range (positions.size()): #0 #1
#		nav_vertices.push_back(positions[index]) #0 #2
#		nav_vertices.push_back(right_nav_positions[index]) #1 #3
#
#	return nav_vertices
#
#func get_navi_vertices_alt():
#	var nav_vertices = PoolVector3Array()
#	for index in range (positions.size()): #0 #1
#		nav_vertices.push_back(left_nav_positions[index]) #0 #2
#		nav_vertices.push_back(positions[index]) #1 #3
#
#	return nav_vertices
#
#func make_navi(index, index_two, index_three, index_four):
#	var navi = navQuad(index, index_two, index_three, index_four)
#	return navi
#
#func navQuad(one, two, three, four):
#	var quad = []
#
#	quad.push_back(one)
#	quad.push_back(two)
#	quad.push_back(three)
#	quad.push_back(four)
#
#	return quad
#
#func makeNav(index, nav_mesh):
#	var navi_poly = make_navi(index+1, index, index+2, index+3)
#	nav_mesh.add_polygon(navi_poly)
#
#func navMesh(vertices, left):
#	#print("Making navmesh")
#	var nav_polygones = []
#
#	var nav_mesh = NavigationMesh.new()
#
#
#	if (vertices.size() <= 0):
#		nav_vertices = PoolVector3Array()
#		nav_vertices.resize(0)
#
#		#this gives us 124 nav vertices for left lane
#		nav_vertices = get_navi_vertices()
#	else:
#		nav_vertices = vertices
#
#	nav_mesh.set_vertices(nav_vertices)
#
#	# skip every 4 verts
#	for i in range(0,124,4):
#		makeNav(i, nav_mesh)
#
#	# add the actual navmesh and enable it
#	var nav_mesh_inst = NavigationMeshInstance.new()
#	nav_mesh_inst.set_navigation_mesh(nav_mesh)
#	nav_mesh_inst.set_enabled(true)
#
#	# assign lane
#	if (left):
#		nav_mesh_inst.add_to_group("left_lane")
#		nav_mesh_inst.set_name("nav_mesh_left_lane_turn")
#	else:
#		nav_mesh_inst.add_to_group("right_lane")
#		nav_mesh_inst.set_name("nav_mesh_right_lane_turn")
#
#	add_child(nav_mesh_inst)
#
#func get_key_navi_vertices():
#	var key_nav_vertices = PoolVector3Array()
#	key_nav_vertices.push_back(nav_vertices[0])
#	key_nav_vertices.push_back(nav_vertices[1])
#	key_nav_vertices.push_back(nav_vertices[nav_vertices.size()-1])
#	key_nav_vertices.push_back(nav_vertices[nav_vertices.size()-2])
#
#	return key_nav_vertices
#
#func move_key_navi_vertices(index1, pos1, index2, pos2):
#	nav_vertices.set(index1, pos1)
#	print("Setting vertex " + String(index1) + " to " + String(pos1))
#	nav_vertices.set(index2, pos2)
#	print("Setting vertex " + String(index2) + " to " + String(pos2))
#	#print("New vertices " + String(nav_vertices[index1]) + " & " + String(nav_vertices[index2]))
#
#func move_key_nav2_vertices(index1, pos1, index2, pos2):
#	nav_vertices2.set(index1, pos1)
#	nav_vertices2.set(index2, pos2)
#

