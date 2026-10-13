class_name RoadArena
extends Node3D

var road_tiles: Array[Node3D] = []
var roadside: Array[Node3D] = []
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
var camera_home := Vector3(0.4, 7.5, -13.8)

func _ready() -> void:
	rng.randomize()
	camera = $Camera
	truck = $Truck
	var body := asset("vehicles/truck-flat", truck)
	body.scale = Vector3(3.2, 2.6, 3.0)
	# Every visible mesh is an instance of a downloaded CC0 model.
	var ground := asset("roads/tile-low", $Scenery)
	ground.position = Vector3(0, -1.1, 0)
	ground.scale = Vector3(200, 1, 260)
	for i in range(15):
		var tile := asset("roads/road-straight", $Scenery)
		tile.position = Vector3(0, 0, (i - 6) * 16.0)
		tile.rotation.y = PI / 2
		tile.scale = Vector3(16, 1.5, 24)
		road_tiles.append(tile)
	var buildings := ["a", "b", "d", "f", "g"]
	for side in [-1, 1]:
		for i in range(12):
			var block := Node3D.new()
			$Scenery.add_child(block)
			block.position = Vector3(side * 16.5, 0, (i - 5) * 18.0)
			var house := asset("city/building-type-" + buildings[i % 5], block)
			house.scale = Vector3.ONE * rng.randf_range(3.0, 4.8)
			house.rotation.y = side * PI / 2
			var tree := asset("city/tree-large" if i % 2 == 0 else "city/tree-small", block)
			tree.position = Vector3(-side * 3.0, 0, 6)
			tree.scale = Vector3.ONE * 3.0
			var lamp := asset("roads/light-curved", block)
			lamp.position = Vector3(-side * 4.3, 0, -5)
			lamp.scale = Vector3.ONE * 3.0
			lamp.rotation.y = side * PI / 2
			roadside.append(block)
	var cars := ["sedan", "van", "taxi", "suv", "police"]
	for i in range(12):
		var car := asset("vehicles/" + cars[i % cars.size()], $Traffic)
		var oncoming: bool = i % 3 == 0
		car.position = Vector3(-7.0 if oncoming else 7.0, 0.1, -70.0 + i * 15)
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
	return instance

func set_menu_camera(enabled: bool) -> void:
	menu_mode = enabled
	camera_home = Vector3(2.8, 6.8, -12.2) if enabled else Vector3(0.2, 6.7, -11.8)
	camera.position = camera_home
	camera.look_at(Vector3(2.35 if enabled else 0.0, 2.1, -1.0))

func _process(delta: float) -> void:
	if not driving:
		return
	elapsed += delta
	for tile in road_tiles:
		tile.position.z -= 17.0 * delta
		if tile.position.z < -104:
			tile.position.z += 240
	for block in roadside:
		block.position.z -= 17.0 * delta
		if block.position.z < -100:
			block.position.z += 216
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
