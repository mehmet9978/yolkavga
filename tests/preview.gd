extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "menu"
	if mode != "menu":
		game.start_match()
		game.set_physics_process(false)
		game._physics_process(3.1)
		game.notice.hide()
		game.quip.hide()
		game.arena.player.position.x = 0.55
		game.arena.bot.position.x = -0.65
		game.arena.player.play_clip("Punch_Right")
		game.arena.bot.play_clip("Idle_Sword")
		game.arena.player.animator.advance(0.45)
		game.arena.bot.animator.advance(0.45)
		game.arena.player.freeze_animation(true)
		game.arena.bot.freeze_animation(true)
		game.arena.player.meter = 72
		game.arena.bot.health = 68
		game.refresh_hud()
		if mode == "settings":
			game.show_settings()
		elif mode == "help":
			game.show_help()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/yolkavga/docs/" + mode + ".png")
	print("PREVIEW: " + mode)
	game.queue_free()
	await process_frame
	quit()
