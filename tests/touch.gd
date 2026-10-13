extends SceneTree

var failed: int = 0

func _initialize() -> void:
	call_deferred("run")

func touch(index: int, pressed: bool, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	Input.parse_input_event(event)

func check(condition: bool, message: String) -> void:
	if not condition:
		failed += 1
		push_error(message)

func tap(position: Vector2) -> void:
	touch(0, true, position)
	await process_frame
	touch(0, false, position)
	await process_frame

func run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.settings.volume = 0
	await tap(game.menu_buttons[0].get_global_rect().get_center())
	check(game.phase == "countdown", "Dokunmayla ana menüden maç başlar")
	game._physics_process(3.1)
	var left: Vector2 = game.action_buttons.left.get_global_rect().get_center()
	var guard: Vector2 = game.action_buttons.guard.get_global_rect().get_center()
	touch(2, true, left)
	touch(3, true, guard)
	await process_frame
	check(game.action_held("left") and game.action_held("guard"), "İki dokunma aynı anda işlenir")
	touch(2, false, left)
	await process_frame
	check(not game.action_held("left") and game.action_held("guard"), "Bir dokunma bitince diğeri sürer")
	touch(3, false, guard)
	await process_frame
	check(not game.action_held("left") and not game.action_held("guard"), "Parmaklar kalkınca kontrol takılı kalmaz")
	game.arena.player.position.x = 0.6
	game.arena.bot.position.x = -0.6
	await tap(game.action_buttons.punch.get_global_rect().get_center())
	game.arena.player.tick(0.2)
	check(game.arena.bot.health == 92, "Dokunmatik yumruk tek isabet üretir")
	await tap(game.hud.get_node("Pause").get_global_rect().get_center())
	check(game.phase == "paused" and game.modal.visible, "Dokunmatik duraklatma açılır")
	print("PASS: 6 gerçek arayüz dokunma kontrolü doğrulandı." if failed == 0 else "FAIL: %d dokunma kontrolü başarısız." % failed)
	game.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
