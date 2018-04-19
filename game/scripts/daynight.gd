# based on a script by Khairul Hidayat, https://www.youtube.com/watch?v=iTkLEP3Kwko
extends Spatial

export var SPEED = 20.0;
const UPDATE_TIME = 1/30.0;

export var start_time = 8.0

var prev_time = 0.0
var time = 0.0;
var delay = 0.0;

var hour = 0
var minute = 0

var light

export var day_night = true

var sun = null
var sunmoon_angle
var sunmoon_lat
var env = null
var sky = null


# colors
var light_color
var ambient_color
var sky_color
var horizon_color
var gr_horizon_color

var night_fired = false

func _ready():
	
	time = start_time;
	prev_time = start_time;
	delay = 0.0;
	
	#target 60 fps
	Engine.set_target_fps(60)
	
	sun = get_parent().get_node("DirectionalLight")
	env = get_parent().get_node("WorldEnvironment").get_environment()
	sky = env.get_sky()

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.

	# set previous time
	prev_time = time
	
	# passage of time
	time += 1/60.0*SPEED*delta;
	if time >= 24.0:
		time -= 24.0;
	
	#update
	delay -= delta;
	if delay > 0.0:
		return;
	delay = UPDATE_TIME
	
	# set hours and minutes
	hour = floor(time)
	minute = (time - floor(time))*60
	
	if day_night:
		day_night_cycle(time)


func calculate_lightning(hour, minute):
	var lightningMin = 0.1
	var lightningMax = 1.0
	var time = (hour + (minute / 60.0)) / 24.0
	var light = lightningMax * sin(PI*time)
	return clamp(light, lightningMin, lightningMax)

func calculate_rotation(time):
	# fraction of 24h
	var fraction = time/24.0
	# inverted fraction
	var inv_fraction = 1.0-fraction
	var angle_midnight = 200 # this * 0.5 = ~90, fudged it for the shadows to be more noticeable in the morning/afternoon
	# set the angle in radians
	var angle = deg2rad(-(angle_midnight*inv_fraction))
	return angle
	
func calculate_sun_latitude(time):
	var lat_sunset = 180
	var lat_night = -40
	var latitude
	
	# fraction of daytime (from 6 to 18)
	var time_since_day = time-6
	if time_since_day > 0 and time < 20:
		var fraction_daytime = time_since_day/12.0
		latitude = (lat_sunset*fraction_daytime)
	elif time_since_day < 0 or time >= 20:
		latitude = lat_night
	
	
	return latitude
	
func get_light_color(time):
	if time >= 17.5 && time < 18:
		var d = (time-17.5)/0.5;
		light_color = Color(1-((1-42/255.0)*d), 1-((1-64/255.0)*d), 1-((1-141/255.0)*d));
	elif time >= 6.0 && time < 6.5:
		var d = (time-5.5)/0.5;
		light_color = Color((42/255.0)+((1-42/255.0)*d), (64/255.0)+((1-64/255.0)*d), (141/255.0)+((1-141/255.0)*d));
	elif time >= 18 or time < 5.5:
		light_color = Color(42/255.0, 64/255.0, 141/255.0);
	else:
		light_color = Color(1,1,1)
	
	#print("Time: " + str(time) + " " + str(light_color))
	
	return light_color
	
func set_colors(time):
	light_color = get_light_color(time)	
		
	sun.set_color(light_color)
	
	ambient_color = Color(169/255.0*light, 189/255.0*light, 242/255.0*light);
	
	# set ambient light colors
	env.set_ambient_light_color(ambient_color)
	env.set_ambient_light_energy(0.2+(0.2*light))
	
	# set sky colors
	# default sky color is 12, 116, 249
	sky_color = Color(12/255.0*light, 116/255.0*light, 0.972*light)
	# default horizon color is 142, 210, 232
	horizon_color = Color(142/255.0*light, 210/255.0*light, 232/255.0*light)
	# detault ground horizon color is 123, 201, 243
	gr_horizon_color = Color(123/255.0*light, 201/255.0*light, 243/255.0*light)
	sky.set_sky_top_color(sky_color)
	sky.set_sky_horizon_color(horizon_color)
	sky.set_ground_horizon_color(gr_horizon_color)	
	env.set_fog_color(horizon_color)


func day_night_cycle(time):
	#print(str(time))
	sunmoon_angle = calculate_rotation(time)
	sun.set_rotation(Vector3(sunmoon_angle, 0, 0))
	sunmoon_lat = calculate_sun_latitude(time)
	
	light = calculate_lightning(hour, minute);
	sun.set_param(Light.PARAM_ENERGY, light);
	
	set_colors(time)
	
	if time >= 5.5 && time < 6.0:
		night_fired = false
		# stuff done slightly before sunrise
		get_tree().get_nodes_in_group("roads")[0].reset_lite()
		#get_tree().call_group("roads", "reset_lite")
		#re-enable shadows
		sun.set_shadow(true)
		
		env.background_energy = 1
		
		# switching gi settings causes stutter
		#get_parent().get_node("GIProbe").set_interior(false)
	elif time >= 17.5 && not night_fired:
		#disable shadows
		sun.set_shadow(false)
		get_tree().get_nodes_in_group("roads")[0].lite_up()
		# so that emissives light effect is better visible
		env.background_energy = 0.1
		print("[DAYNIGHT] switch to night settings")
		night_fired = true
		# GI probe interior switch causes stutter
		#get_parent().get_node("GIProbe").set_interior(true)
		

	
	# set sun latitude
	sky.set_sun_latitude(sunmoon_lat)
	
	#env.set_background_param(Environment.BG_PARAM_COLOR, col);
	
