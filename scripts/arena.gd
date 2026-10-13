class_name RoadArena
extends Node3D

@export var grass_material: StandardMaterial3D
@export var meadow_material: StandardMaterial3D
@export var leaf_material: StandardMaterial3D
@export var pine_material: StandardMaterial3D
@export var bark_material: StandardMaterial3D
@export var earth_material: StandardMaterial3D
@export var road_material: StandardMaterial3D

var road_tiles: Array[Node3D] = []
var roadside: Array[Node3D] = []
var highway_signs: Array[Node3D] = []
var traffic: Array[Node3D] = []
var traffic_speeds: Array[float] = []
var player: RoadFighter
var bot: RoadFighter
var driving: bool = true
var shake_enabled: bool = true
var shaking: float = 0.0
var elapsed: float = 0.0
var menu_mode: bool = true
var rng := RandomNumberGenerator.new()
var truck: Node3D
var camera: Camera3D
var camera_home := Vector3(0.2, 5.9, -12.1)

const ROAD_LENGTH := 480.0
const LANDSCAPE_LENGTH := 308.0

func _ready() -> void:
	rng.randomize()
	camera = $Camera
	truck = $Truck
	var body := asset("vehicles/truck-flat", truck)
	body.scale = Vector3(3.2, 2.6, 3.0)
	# All terrain, foliage and road geometry comes from downloaded CC0 models.
	var ground := asset("nature/ground_grass", $Scenery)
	ground.name = "Meadow"
	ground.position = Vector3(0, -0.10, 0)
	ground.scale = Vector3(900, 1, 900)
	for mesh in mesh_nodes(ground):
		mesh.material_override = meadow_material
	configure_meshes(ground, 0, false)
	build_highway()
	build_woodland()
	build_signs()
	var cars := ["sedan", "van", "taxi", "suv", "police"]
	for i in range(12):
		var car := asset("vehicles/" + cars[i % cars.size()], $Traffic)
		var oncoming: bool = i % 3 == 0
		var lane_x: float = (-9.6 if i % 2 == 0 else -15.6) if oncoming else 6.0
		car.position = Vector3(lane_x, 0.1, -70.0 + i * 15)
		car.scale = Vector3.ONE * 1.65
		car.rotation.y = PI if oncoming else 0.0
		traffic.append(car)
		traffic_speeds.append(30.0 if oncoming else rng.randf_range(6.0, 14.0))
	var fighters := Node3D.new()
	fighters.name = "Fighters"
	truck.add_child(fighters)
	fighters.position = Vector3(0, 1.96, -1.75)
	player = RoadFighter.new()
	player.name = "Player"
	fighters.add_child(player)
	player.setup("res://assets/characters/casual-character.glb")
	bot = RoadFighter.new()
	bot.name = "Bot"
	fighters.add_child(bot)
	bot.setup("res://assets/characters/worker.glb")
	player.opponent = bot
	bot.opponent = player
	player.reset_round(0.95)
	bot.reset_round(-0.95)
	var plate := Label3D.new()
	truck.add_child(plate)
	plate.text = "41 KVG 001"
	plate.font = load("res://assets/fonts/BarlowCondensed-Bold.ttf")
	plate.font_size = 44
	plate.pixel_size = 0.004
	plate.position = Vector3(0, 0.9, -4.18)
	plate.rotation.y = PI
	plate.modulate = Color(0.08, 0.12, 0.15)
	set_menu_camera(true)

func asset(path: String, parent: Node3D) -> Node3D:
	var instance: Node3D = load("res://assets/" + path + ".glb").instantiate()
	parent.add_child(instance)
	if path.begins_with("nature/"):
		for mesh in mesh_nodes(instance):
			for surface in mesh.mesh.get_surface_count():
				var source: Material = mesh.get_active_material(surface)
				var material_name: String = source.resource_name.to_lower()
				var replacement: StandardMaterial3D
				if material_name == "grass":
					replacement = grass_material
				elif material_name.begins_with("leafs"):
					replacement = pine_material if "dark" in material_name else leaf_material
				elif material_name.begins_with("woodbark"):
					replacement = bark_material
				elif material_name == "dirt":
					replacement = earth_material
				if replacement != null:
					mesh.set_surface_override_material(surface, replacement)
	return instance

func mesh_nodes(instance: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if instance is MeshInstance3D:
		meshes.append(instance)
	for child in instance.find_children("*", "MeshInstance3D", true, false):
		meshes.append(child)
	return meshes

func configure_meshes(instance: Node3D, distance: float, shadows: bool = true) -> void:
	for mesh in mesh_nodes(instance):
		mesh.visibility_range_end = distance
		mesh.visibility_range_end_margin = 12.0 if distance > 0 else 0.0
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func build_highway() -> void:
	for i in range(30):
		var section := Node3D.new()
		section.name = "HighwaySection%d" % i
		$Scenery.add_child(section)
		section.position.z = (i - 6) * 16.0
		for center_x in [3.0, -12.6]:
			var asphalt := asset("roads/road-straight", section)
			asphalt.position.x = center_x
			asphalt.rotation.y = PI / 2
			asphalt.scale = Vector3(16, 1.5, 12)
			for mesh in mesh_nodes(asphalt):
				mesh.material_override = road_material
			configure_meshes(asphalt, 0, false)
		# The grass median separates two independently flowing carriageways.
		for edge_x in [-18.9, -6.5, -3.1, 9.3]:
			var rail := asset("highway/railDouble", section)
			# Imported Racing Kit rails include a quarter-turn and an offset.
			rail.position = Vector3(edge_x + 1.3, 0.065, 2.4)
			rail.rotation.y = PI / 2
			rail.scale = Vector3(16.0, 2.8, 2.0)
			configure_meshes(rail, 145, false)
		if i % 2 == 0:
			for offset_z in [-4.0, 4.0]:
				var shrub := asset("nature/plant_bushLarge", section)
				shrub.position = Vector3(-4.8, 0, offset_z)
				shrub.scale = Vector3(4.5, 3.8, 4.5)
				configure_meshes(shrub, 125, false)
		road_tiles.append(section)

func build_woodland() -> void:
	var trees := ["tree_oak", "tree_pineRoundA", "tree_detailed", "tree_default_dark", "tree_pineTallA"]
	for side in [-1, 1]:
		for i in range(14):
			var block := Node3D.new()
			block.name = "Woodland_%d_%d" % [side, i]
			$Scenery.add_child(block)
			block.position = Vector3(12.2 if side == 1 else -22.0, 0, (i - 4) * 22.0)
			for j in range(4):
				var tree := asset("nature/" + trees[(i * 3 + j) % trees.size()], block)
				tree.position = Vector3(side * (j * 3.4 + rng.randf_range(-0.7, 0.7)), 0, -8.0 + j * 5.0)
				tree.scale = Vector3.ONE * rng.randf_range(3.2, 5.3)
				tree.rotation.y = rng.randf_range(0, TAU)
				configure_meshes(tree, 185, j < 2)
			for j in range(3):
				var plant := asset("nature/plant_bushDetailed" if j == 0 else "nature/grass_large", block)
				plant.position = Vector3(-side * rng.randf_range(0.5, 1.7), 0, -7.0 + j * 7.0)
				plant.scale = Vector3.ONE * (3.3 if j == 0 else 2.5)
				configure_meshes(plant, 105, false)
			var flowers := asset("nature/flower_yellowA" if i % 2 == 0 else "nature/flower_redA", block)
			flowers.position = Vector3(-side * 2.0, 0, 2)
			flowers.scale = Vector3.ONE * 2.0
			configure_meshes(flowers, 85, false)
			if i % 3 == 0:
				var rock := asset("nature/rock_largeA" if i % 2 == 0 else "nature/rock_largeC", block)
				rock.position = Vector3(side * 7.0, 0, 8)
				rock.scale = Vector3.ONE * 2.2
				configure_meshes(rock, 140, false)
			if i % 4 == 0:
				var bank := asset("nature/rock_largeA" if i % 2 == 0 else "nature/rock_largeC", block)
				bank.position = Vector3(side * 35.0, -0.10, 2)
				bank.scale = Vector3(65, rng.randf_range(50.0, 75.0), 76)
				for mesh in mesh_nodes(bank):
					mesh.material_override = grass_material
				configure_meshes(bank, 0, false)
			if i % 3 == 1:
				var lamp := asset("roads/light-curved", block)
				lamp.position = Vector3(-side * 2.5, 0, -4)
				lamp.scale = Vector3.ONE * 6.0
				lamp.rotation.y = side * PI / 2
				configure_meshes(lamp, 135, false)
			if i % 7 == 0:
				var house := asset("city/building-type-d", block)
				house.position = Vector3(side * 14.0, 0, 11)
				house.scale = Vector3.ONE * 2.8
				configure_meshes(house, 165, false)
			roadside.append(block)

func build_signs() -> void:
	for i in range(2):
		var sign := asset("roads/sign-highway-detailed", $Scenery)
		sign.name = "RouteSign%d" % i
		sign.position = Vector3(6.1 if i == 0 else -4.8, 0, 70 if i == 0 else 12)
		sign.rotation.y = -PI / 2
		sign.scale = Vector3(5.0, 9.0, 5.0) if i == 0 else Vector3.ONE * 3.3
		configure_meshes(sign, 190, false)
		# Label is a UI annotation on a downloaded sign, not generated artwork.
		var text := Label3D.new()
		sign.add_child(text)
		text.text = "İSTANBUL  D-100" if i == 0 else "KOCAELİ  D-100"
		text.font = load("res://assets/fonts/BarlowCondensed-Bold.ttf")
		text.font_size = 84
		text.pixel_size = 0.00085
		text.position = Vector3(-0.040, 0.755, 0)
		text.rotation.y = -PI / 2
		text.outline_size = 1
		text.modulate = Color(1, 0.97, 0.84)
		highway_signs.append(sign)

func set_menu_camera(enabled: bool) -> void:
	menu_mode = enabled
	camera_home = Vector3(2.8, 6.1, -12.5) if enabled else Vector3(0.2, 5.9, -12.1)
	camera.position = camera_home
	camera.look_at(Vector3(2.35 if enabled else 0.0, 2.4, -1.0))

func _process(delta: float) -> void:
	if not driving:
		return
	elapsed += delta
	# Scroll the existing meadow texture at the same speed as the scenery.
	meadow_material.uv1_offset.y = fmod(elapsed * 17.0 * 39.37008 * meadow_material.uv1_scale.y / 900.0, 1.0)
	for tile in road_tiles:
		tile.position.z -= 17.0 * delta
		if tile.position.z < -104:
			tile.position.z += ROAD_LENGTH
	for block in roadside:
		block.position.z -= 17.0 * delta
		if block.position.z < -100:
			block.position.z += LANDSCAPE_LENGTH
	for sign in highway_signs:
		sign.position.z -= 17.0 * delta
		if sign.position.z < -100:
			sign.position.z += ROAD_LENGTH
	for i in traffic.size():
		traffic[i].position.z -= traffic_speeds[i] * delta
		if traffic[i].position.z < -85:
			traffic[i].position.z = 100 + rng.randf_range(0, 20)
	truck.position.y = sin(elapsed * 7) * 0.025
	truck.rotation.z = sin(elapsed * 2.1) * 0.007
	shaking = maxf(0, shaking - delta)
	camera.position = camera_home
	if shaking > 0 and shake_enabled:
		camera.position += Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), 0) * shaking * 0.22

func impact(defender: RoadFighter, blocked: bool) -> void:
	shaking = 0.22 if blocked else 0.42
	var flash := Sprite3D.new()
	add_child(flash)
	flash.texture = load("res://assets/fx/spark_06.png" if blocked else "res://assets/fx/star_04.png")
	flash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash.no_depth_test = true
	flash.pixel_size = 0.007
	flash.global_position = defender.global_position + Vector3(0, 1.2, 0)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 1.8, 0.17)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)
