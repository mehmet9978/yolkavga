extends SceneTree

var failures: Array[String] = []
var checks: int = 0
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func advance(fighter: RoadFighter, seconds: float) -> void:
	for i in ceili(seconds * 60):
		fighter.tick(1.0 / 60.0)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.settings.volume = 0.0
	game.set_physics_process(false)
	var player: RoadFighter = game.arena.player
	var bot: RoadFighter = game.arena.bot
	check(game.phase == "menu" and game.menu.visible, "Ana menü açılır")
	check(player.clips.has("Punch_Right") and player.clips.has("Kick_Right"), "Hazır dövüş animasyonları yüklenir")
	check(game.arena.traffic.size() == 12, "Trafik araçları yüklenir")
	game.show_settings()
	check(game.modal.visible, "Ayarlar açılır")
	game.close_modal()
	game.show_help()
	check(game.modal.visible, "Nasıl oynanır açılır")
	game.close_modal()
	game.show_credits()
	check(game.modal.visible, "Asset kredileri açılır")
	game.start_match()
	check(game.phase == "countdown" and player.health == 100, "Maç geri sayımla başlar")
	game._physics_process(3.1)
	check(game.phase == "fight" and player.active, "Geri sayım sonunda dövüş başlar")
	var screen_before: float = game.arena.camera.unproject_position(player.global_position).x
	game.held.left = true
	game._physics_process(0.1)
	check(game.arena.camera.unproject_position(player.global_position).x < screen_before, "Sol düğme kamerada sola hareket ettirir")
	game.clear_inputs()
	player.position.x = -0.6
	bot.position.x = 0.6
	check(player.attack("punch"), "Yumruk başlatılabilir")
	check(not player.attack("kick"), "Saldırı sırasında yeni saldırı engellenir")
	advance(player, 0.5)
	check(bot.health == 92, "Yumruk yalnız bir kez hasar verir")
	check(player.meter == 14, "Başarılı yumruk tantana doldurur")
	bot.reset_round(0.6)
	bot.active = true
	bot.guard = true
	player.attack("kick")
	advance(player, 0.8)
	check(bot.health == 98, "Savunma tekme hasarını azaltır")
	check(bot.meter == 9, "Savunma özel hareket barını doldurur")
	check(not player.attack("special"), "Boş barla özel saldırı yapılamaz")
	player.meter = 100
	bot.guard = false
	bot.busy = 0
	bot.invulnerable = 0
	bot.health = 100
	check(player.attack("special"), "Dolu barla özel saldırı yapılır")
	advance(player, 1.1)
	check(bot.health == 75 and player.meter == 0, "Özel saldırı 25 hasar verir ve barı tüketir")
	player.position.x = -1.9
	bot.reset_round(1.9)
	bot.active = true
	player.attack("punch")
	advance(player, 0.5)
	check(bot.health == 100, "Menzil dışındaki yumruk isabet etmez")
	player.position.x = -0.8
	bot.position.x = 0.8
	player.move_axis = -1
	advance(player, 2)
	check(player.position.x >= -1.9, "Dövüşçü kasadan çıkamaz")
	var before: float = game.round_time
	game.pause_game()
	game._physics_process(10)
	check(game.phase == "paused" and game.round_time == before, "Duraklatmada maç saati durur")
	check(not game.arena.driving, "Duraklatmada trafik durur")
	game.resume_game()
	check(game.phase == "fight" and game.arena.driving, "Maç kaldığı yerden devam eder")
	var left := InputEventScreenTouch.new()
	left.index = 2
	left.pressed = true
	left.position = game.action_buttons.left.get_global_rect().get_center()
	game._input(left)
	var guard := InputEventScreenTouch.new()
	guard.index = 3
	guard.pressed = true
	guard.position = game.action_buttons.guard.get_global_rect().get_center()
	game._input(guard)
	check(game.action_held("left") and game.action_held("guard"), "İki parmakla hareket ve savunma birlikte çalışır")
	left.pressed = false
	game._input(left)
	check(not game.action_held("left") and game.action_held("guard"), "Bir parmak kalkınca diğer kontrol korunur")
	game.clear_inputs()
	game.arena.player.health = 90
	game.arena.bot.health = 20
	game.round_time = 0
	game.finish_round()
	check(player.wins == 1 and game.phase == "intermission", "Süre bitince daha çok canı olan raund kazanır")
	game._physics_process(3)
	check(game.round_number == 2 and game.phase == "countdown", "İkinci raund başlar")
	game._physics_process(3.1)
	bot.health = 0
	game.finish_round()
	game._physics_process(3)
	check(game.phase == "result" and player.wins == 2, "İki raund kazanınca sonuç ekranı açılır")
	game.start_match()
	check(player.wins == 0 and bot.wins == 0 and game.round_number == 1, "Rövanş skorları sıfırlar")
	game._physics_process(3.1)
	player.health = 100
	bot.health = 100
	game.finish_round()
	check(player.wins == 0 and bot.wins == 0, "Beraberlikte kimse puan almaz")
	game.show_menu()
	check(game.phase == "menu" and not game.hud.visible, "Ana menüye dönülür")
	game.rng.seed = 42
	game.start_match()
	for i in range(12000):
		game._physics_process(1.0 / 60.0)
		if game.phase == "result":
			break
	check(game.phase == "result" and bot.wins == 2, "Bot iki tam raundu oynayıp maçı bitirebilir")
	if failures.is_empty():
		print("PASS: %d oyun kontrolü doğrulandı." % checks)
	else:
		print("FAIL: %d / %d kontrol başarısız." % [failures.size(), checks])
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
