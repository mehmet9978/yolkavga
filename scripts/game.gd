extends Node

const INK := Color("101d2c")
const PAPER := Color("f1f4ed")
const MUTED := Color("aebdc4")
const YELLOW := Color("ffd24a")
const RED := Color("ff705e")
const GREEN := Color("7cdda4")
const FONT := preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
const TITLE_FONT := preload("res://assets/fonts/BarlowCondensed-Bold.ttf")

var arena: RoadArena
var ui: Control
var menu: Control
var hud: Control
var modal: Control
var notice: Label
var quip: Label
var timer_label: Label
var round_label: Label
var player_bar: ProgressBar
var bot_bar: ProgressBar
var player_meter: ProgressBar
var bot_meter: ProgressBar
var player_score: Label
var bot_score: Label
var combo_label: Label
var special_button: Button
var phase: String = "menu"
var previous_phase: String = "fight"
var round_number: int = 1
var round_time: float = 60.0
var transition_time: float = 0
var notice_time: float = 0
var quip_time: float = 0
var hit_freeze: float = 0
var ai_time: float = 0
var ai_axis: float = 0
var ai_guard_time: float = 0
var settings := {"volume": 0.65, "difficulty": 1, "shake": true, "vibration": true, "large_controls": false}
var held := {"left": false, "right": false, "guard": false}
var touch_actions: Dictionary = {}
var action_buttons: Dictionary = {}
var effects: Array[AudioStreamPlayer] = []
var sfx_index: int = 0
var music: AudioStreamPlayer
var rng := RandomNumberGenerator.new()
var menu_buttons: Array[Button] = []

func _ready() -> void:
	rng.randomize()
	load_settings()
	arena = $Arena
	arena.shake_enabled = settings.shake
	arena.player.landed.connect(on_hit)
	arena.bot.landed.connect(on_hit)
	for i in range(6):
		var audio := AudioStreamPlayer.new()
		add_child(audio)
		effects.append(audio)
	ui = Control.new()
	ui.name = "UI"
	$Interface.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_menu()
	build_hud()
	build_overlays()
	show_menu()
	get_viewport().size_changed.connect(layout)
	layout()
	get_tree().auto_accept_quit = false

func style_box(color: Color, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func asset_style(color: String, shape: String = "rectangle", depth: bool = false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	var path := "res://assets/ui/%s/button_%s_%sflat.png" % [color, shape, "depth_" if depth else ""]
	style.texture = load(path)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 10)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style

func label(parent: Node, text: String, size: int, color: Color = PAPER) -> Label:
	var item := Label.new()
	parent.add_child(item)
	item.text = text
	item.add_theme_font_override("font", FONT)
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func button(parent: Node, text: String, color: String = "grey", callback: Callable = Callable()) -> Button:
	var item := Button.new()
	parent.add_child(item)
	item.text = text
	item.add_theme_font_override("font", TITLE_FONT)
	item.add_theme_font_size_override("font_size", 25)
	item.add_theme_color_override("font_color", INK)
	item.add_theme_color_override("font_hover_color", INK)
	item.add_theme_color_override("font_pressed_color", INK)
	item.add_theme_color_override("font_focus_color", INK)
	item.add_theme_color_override("font_disabled_color", Color("66737c"))
	item.add_theme_stylebox_override("normal", asset_style(color, "rectangle", true))
	item.add_theme_stylebox_override("hover", asset_style(color, "rectangle", true))
	item.add_theme_stylebox_override("pressed", asset_style(color))
	item.add_theme_stylebox_override("disabled", asset_style("grey"))
	item.add_theme_stylebox_override("focus", style_box(Color(1, 1, 1, 0.15), 8))
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if callback.is_valid():
		item.pressed.connect(func():
			sound("click_001")
			callback.call())
	return item

func panel(parent: Node, color: Color) -> Panel:
	var item := Panel.new()
	parent.add_child(item)
	item.add_theme_stylebox_override("panel", style_box(color, 18))
	return item

func build_menu() -> void:
	menu = Control.new()
	ui.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := panel(menu, Color(INK, 0.97))
	card.name = "MenuCard"
	card.position = Vector2(32, 30)
	card.size = Vector2(405, 660)
	var tag := label(card, "KAMYONET KASASI DÖVÜŞ KULÜBÜ", 18, YELLOW)
	tag.position = Vector2(28, 29)
	var title := label(card, "YOL\nKAVGA", 104)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_constant_override("line_spacing", -24)
	title.position = Vector2(23, 56)
	var subtitle := label(card, "Trafik akar. Muhabbet kaçar.", 24, MUTED)
	subtitle.position = Vector2(28, 280)
	var badge := label(card, "1 OYUNCU  /  1 BOT  /  BOL TANTANA", 18, YELLOW)
	badge.position = Vector2(28, 326)
	var names := ["KAVGAYI BAŞLAT", "AYARLAR", "NASIL OYNANIR", "EMEĞİ GEÇENLER"]
	var callbacks: Array[Callable] = [start_match, show_settings, show_help, show_credits]
	for i in names.size():
		var item := button(card, names[i], "yellow" if i == 0 else "grey", callbacks[i])
		item.position = Vector2(28, 368 + i * 61)
		item.size = Vector2(349, 51)
		menu_buttons.append(item)
	var footer := label(card, "ÜCRETSİZ HAZIR ASSETLER  ·  ÇEVRİMDIŞI", 16, MUTED)
	footer.position = Vector2(28, 624)
	var bubble := panel(menu, Color(INK, 0.88))
	bubble.name = "MenuBubble"
	bubble.size = Vector2(354, 73)
	var joke := label(bubble, "“Abi, kasada yer var dedin...”", 26)
	joke.position = Vector2(20, 7)
	var caption := label(bubble, "YER VAR. SAKİNLİK YOK.", 16, YELLOW)
	caption.position = Vector2(20, 40)
	var route := label(menu, "KOCAELİ ÇEVRE YOLU  •  SAAT 17.41", 18, INK)
	route.name = "Route"
	var edition := label(menu, "KASA KARIŞTI!", 20, INK)
	edition.name = "Edition"

func health_group(side: bool) -> Control:
	var group := panel(hud, Color(INK, 0.94))
	group.name = "BotHealth" if side else "PlayerHealth"
	group.size = Vector2(440, 115)
	var name_label := label(group, "KASA ABİSİ   /   BOT" if side else "SEN   /   YOLCU", 23, RED if side else YELLOW)
	name_label.position = Vector2(18, 8)
	var score := label(group, "○  ○", 23, YELLOW)
	score.position = Vector2(357, 8)
	var health := ProgressBar.new()
	group.add_child(health)
	health.position = Vector2(18, 44)
	health.size = Vector2(404, 29)
	health.show_percentage = false
	health.add_theme_stylebox_override("background", style_box(Color("394653"), 3))
	health.add_theme_stylebox_override("fill", asset_style("red" if side else "green"))
	if side:
		health.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	var meter := ProgressBar.new()
	group.add_child(meter)
	meter.position = Vector2(18, 84)
	meter.size = Vector2(275, 10)
	meter.show_percentage = false
	meter.add_theme_stylebox_override("background", style_box(Color("394653"), 2))
	meter.add_theme_stylebox_override("fill", asset_style("yellow"))
	var meter_name := label(group, "TANTANA", 14, MUTED)
	meter_name.position = Vector2(307, 77)
	if side:
		bot_bar = health
		bot_meter = meter
		bot_score = score
	else:
		player_bar = health
		player_meter = meter
		player_score = score
	return group

func build_hud() -> void:
	hud = Control.new()
	ui.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_group(false)
	health_group(true)
	var clock := panel(hud, Color(INK, 0.96))
	clock.name = "Clock"
	clock.size = Vector2(112, 115)
	timer_label = label(clock, "60", 57, YELLOW)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.position = Vector2(0, 1)
	timer_label.size = Vector2(112, 68)
	round_label = label(clock, "RAUND 1", 17, MUTED)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.position = Vector2(0, 77)
	round_label.size.x = 112
	var pause_button := button(hud, "II", "grey", pause_game)
	pause_button.name = "Pause"
	pause_button.size = Vector2(64, 52)
	combo_label = label(hud, "", 28, YELLOW)
	combo_label.name = "Combo"
	var left_controls := panel(hud, Color(INK, 0.86))
	left_controls.name = "LeftControls"
	left_controls.size = Vector2(410, 115)
	action_button(left_controls, "left", "SOL\nA", Vector2(12, 12), Vector2(100, 90), "grey", true)
	action_button(left_controls, "right", "SAĞ\nD", Vector2(122, 12), Vector2(100, 90), "grey", true)
	action_button(left_controls, "guard", "SAVUN\nS", Vector2(235, 12), Vector2(163, 90), "blue", true)
	var attacks := panel(hud, Color(INK, 0.86))
	attacks.name = "Attacks"
	attacks.size = Vector2(449, 115)
	action_button(attacks, "punch", "YUMRUK\nJ", Vector2(12, 12), Vector2(125, 90), "yellow", false)
	action_button(attacks, "kick", "TEKME\nK", Vector2(148, 12), Vector2(125, 90), "red", false)
	special_button = action_button(attacks, "special", "TANTANA\nL", Vector2(285, 12), Vector2(151, 90), "yellow", false)
	var hint := label(hud, "YAKLAŞ  →  VUR  →  SAVUN  →  TANTANAYI DOLDUR", 16, PAPER)
	hint.name = "ControlHint"

func action_button(parent: Node, action: String, text: String, pos: Vector2, dimensions: Vector2, color: String, hold: bool) -> Button:
	var item := button(parent, text, color)
	item.position = pos
	item.size = dimensions
	item.focus_mode = Control.FOCUS_NONE
	item.add_theme_font_size_override("font_size", 23)
	action_buttons[action] = item
	if hold:
		item.button_down.connect(func(): held[action] = true)
		item.button_up.connect(func(): held[action] = false)
	else:
		item.pressed.connect(func(): request_attack(action))
	return item

func build_overlays() -> void:
	notice = label(ui, "", 75, YELLOW)
	notice.name = "Announcement"
	notice.add_theme_font_override("font", TITLE_FONT)
	notice.add_theme_color_override("font_outline_color", INK)
	notice.add_theme_constant_override("outline_size", 10)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.size = Vector2(900, 115)
	quip = label(ui, "", 26)
	quip.name = "Quip"
	quip.add_theme_color_override("font_outline_color", INK)
	quip.add_theme_constant_override("outline_size", 7)
	quip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quip.size = Vector2(850, 48)
	modal = Control.new()
	ui.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.visible = false

func layout() -> void:
	var screen: Vector2 = get_viewport().get_visible_rect().size
	menu.get_node("MenuBubble").position = Vector2(screen.x - 390, 166)
	menu.get_node("Route").position = Vector2(screen.x - 333, 32)
	menu.get_node("Edition").position = Vector2(screen.x - 165, screen.y - 51)
	hud.get_node("PlayerHealth").position = Vector2(24, 22)
	hud.get_node("BotHealth").position = Vector2(screen.x - 464, 22)
	hud.get_node("Clock").position = Vector2(screen.x / 2 - 56, 22)
	hud.get_node("Pause").position = Vector2(screen.x - 88, 154)
	hud.get_node("Combo").position = Vector2(40, 160)
	var controls_scale: float = 1.12 if settings.large_controls else 1.0
	hud.get_node("LeftControls").scale = Vector2.ONE * controls_scale
	hud.get_node("Attacks").scale = Vector2.ONE * controls_scale
	hud.get_node("LeftControls").position = Vector2(24, screen.y - 24 - 115 * controls_scale)
	hud.get_node("Attacks").position = Vector2(screen.x - 24 - 449 * controls_scale, screen.y - 24 - 115 * controls_scale)
	hud.get_node("ControlHint").position = Vector2(28, screen.y - 164)
	notice.position = Vector2(screen.x / 2 - 450, screen.y * 0.36)
	quip.position = Vector2(screen.x / 2 - 425, screen.y * 0.72)
	if modal.has_node("Card"):
		var card: Control = modal.get_node("Card")
		card.position = (screen - card.size) / 2

func show_menu() -> void:
	clear_inputs()
	phase = "menu"
	menu.show()
	hud.hide()
	modal.hide()
	notice.hide()
	quip.hide()
	arena.driving = true
	arena.set_menu_camera(true)
	arena.player.active = false
	arena.bot.active = false
	arena.player.freeze_animation(false)
	arena.bot.freeze_animation(false)
	arena.player.reset_round(0.95)
	arena.bot.reset_round(-0.95)
	menu_buttons[0].grab_focus()

func start_match() -> void:
	menu.hide()
	modal.hide()
	hud.show()
	arena.set_menu_camera(false)
	arena.driving = true
	arena.player.wins = 0
	arena.bot.wins = 0
	round_number = 1
	start_round()

func start_round() -> void:
	clear_inputs()
	arena.player.freeze_animation(false)
	arena.bot.freeze_animation(false)
	arena.player.reset_round(0.95)
	arena.bot.reset_round(-0.95)
	arena.player.active = false
	arena.bot.active = false
	phase = "countdown"
	transition_time = 3.0
	round_time = 60.0
	ai_time = 0.5
	ai_guard_time = 0
	ai_axis = 0
	hit_freeze = 0
	notice_time = 0
	round_label.text = "RAUND %d" % round_number
	announce("3", 0)
	say("Şoför: “Kasayı dağıtmayın yeter!”", 3.0)
	refresh_hud()

func _physics_process(delta: float) -> void:
	if phase in ["paused", "menu", "result"]:
		return
	if notice_time > 0:
		notice_time -= delta
		if notice_time <= 0:
			notice.hide()
	if quip_time > 0:
		quip_time -= delta
		if quip_time <= 0:
			quip.hide()
	if phase == "countdown":
		transition_time -= delta
		notice.text = str(ceili(transition_time))
		if transition_time <= 0:
			phase = "fight"
			arena.player.active = true
			arena.bot.active = true
			announce("KASA KARIŞTI!", 0.9)
		return
	if phase == "intermission":
		transition_time -= delta
		if transition_time <= 0:
			if arena.player.wins >= 2 or arena.bot.wins >= 2:
				show_result()
			else:
				round_number += 1
				start_round()
		return
	if hit_freeze > 0:
		hit_freeze -= delta
		if hit_freeze <= 0:
			arena.player.freeze_animation(false)
			arena.bot.freeze_animation(false)
		return
	round_time = maxf(0, round_time - delta)
	var left: bool = action_held("left") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right: bool = action_held("right") or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	# Camera looks toward +Z, so screen-left corresponds to world +X.
	arena.player.move_axis = float(left) - float(right)
	arena.player.guard = action_held("guard") or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	update_bot(delta)
	arena.player.tick(delta)
	arena.bot.tick(delta)
	refresh_hud()
	if arena.player.health <= 0 or arena.bot.health <= 0 or round_time <= 0:
		finish_round()

func update_bot(delta: float) -> void:
	ai_time -= delta
	ai_guard_time = maxf(0, ai_guard_time - delta)
	arena.bot.guard = ai_guard_time > 0
	var distance: float = absf(arena.bot.position.x - arena.player.position.x)
	if distance > 1.5 and arena.bot.busy <= 0:
		ai_axis = signf(arena.player.position.x - arena.bot.position.x)
	elif ai_time <= 0:
		ai_axis = 0
	arena.bot.move_axis = ai_axis
	if ai_time > 0 or arena.bot.busy > 0:
		return
	var level: int = settings.difficulty
	ai_time = rng.randf_range(0.45, 0.80) if level == 0 else rng.randf_range(0.24, 0.48)
	if level == 2:
		ai_time *= 0.75
	if distance > 2.1:
		return
	var chance: float = rng.randf()
	if chance < [0.12, 0.25, 0.36][level]:
		ai_guard_time = rng.randf_range(0.25, 0.7)
	elif arena.bot.meter >= 100 and chance > 0.5:
		arena.bot.attack("special")
	elif chance < 0.78:
		arena.bot.attack("punch")
	else:
		arena.bot.attack("kick")

func request_attack(kind: String) -> void:
	if phase != "fight":
		return
	if kind == "special" and arena.player.meter < 100:
		say("Tantana dolunca ortalığı karıştır!", 1.5)
		return
	if arena.player.attack(kind) and kind == "special":
		say("“O KASA BENİM KASAM!”", 1.2)

func on_hit(attacker: RoadFighter, defender: RoadFighter, damage: int, blocked: bool, kind: String) -> void:
	arena.impact(defender, blocked)
	sound("impactMetal_heavy_000" if blocked else ("impactPunch_heavy_000" if kind != "punch" else "impactPunch_medium_000"))
	hit_freeze = 0.035 if blocked else 0.07
	arena.player.freeze_animation(true)
	arena.bot.freeze_animation(true)
	if settings.vibration and defender == arena.player:
		Input.vibrate_handheld(25 if blocked else 45)
	if attacker.combo >= 2 and not blocked:
		say("%d VURUŞ!  “Abi, bozuk para döküldü!”" % attacker.combo, 0.8)
	elif rng.randf() < 0.26:
		var jokes := ["“Sinyal ver bari!”", "“Usta, sağa çek!”", "“Kasa boş, sinirler dolu!”", "“Çay döküldü, çay!”", "“Burası ring mi, nakliye mi?”"]
		say(jokes[rng.randi_range(0, jokes.size() - 1)], 1.15)
	refresh_hud()

func finish_round() -> void:
	phase = "intermission"
	clear_inputs()
	arena.player.active = false
	arena.bot.active = false
	arena.player.freeze_animation(false)
	arena.bot.freeze_animation(false)
	transition_time = 2.7
	if arena.player.health == arena.bot.health:
		announce("BERABERE!", 0)
		say("İkiniz de aynı kasanın yolcususunuz.", 2.6)
	elif arena.player.health > arena.bot.health:
		arena.player.wins += 1
		arena.player.play_clip("Wave")
		announce("RAUND SENİN!", 0)
		say("“Nakliye ücretine dahil mi bu?”", 2.6)
	else:
		arena.bot.wins += 1
		arena.bot.play_clip("Wave")
		announce("KASA ABİSİ KAZANDI!", 0)
		say("Bir sonraki raundda hesabı kapatırsın.", 2.6)
	refresh_hud()

func refresh_hud() -> void:
	player_bar.value = arena.player.health
	bot_bar.value = arena.bot.health
	player_meter.value = arena.player.meter
	bot_meter.value = arena.bot.meter
	player_score.text = ("●" if arena.player.wins > 0 else "○") + "  " + ("●" if arena.player.wins > 1 else "○")
	bot_score.text = ("●" if arena.bot.wins > 0 else "○") + "  " + ("●" if arena.bot.wins > 1 else "○")
	timer_label.text = "%02d" % ceili(round_time)
	combo_label.text = "%d VURUŞ!" % arena.player.combo if arena.player.combo >= 2 else ""
	special_button.modulate = Color.WHITE if arena.player.meter >= 100 else Color(0.64, 0.67, 0.68)

func announce(text: String, duration: float) -> void:
	notice.text = text
	notice.show()
	notice_time = duration

func say(text: String, duration: float) -> void:
	quip.text = text
	quip.show()
	quip_time = duration

func open_modal(title: String, height: float = 520) -> Panel:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.show()
	var shade := ColorRect.new()
	modal.add_child(shade)
	shade.color = Color(0.03, 0.07, 0.12, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := panel(modal, INK)
	card.name = "Card"
	card.size = Vector2(640, height)
	var heading := label(card, title, 46, YELLOW)
	heading.position = Vector2(30, 18)
	layout()
	return card

func close_modal() -> void:
	modal.hide()
	menu_buttons[0].grab_focus()

func show_settings() -> void:
	var card := open_modal("AYARLAR", 540)
	label(card, "SES SEVİYESİ", 23).position = Vector2(32, 98)
	var slider := HSlider.new()
	card.add_child(slider)
	slider.position = Vector2(255, 100)
	slider.size = Vector2(345, 34)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = settings.volume
	slider.value_changed.connect(func(value):
		settings.volume = value
		apply_volume()
		save_settings())
	label(card, "BOT ZORLUĞU", 23).position = Vector2(32, 158)
	var difficulty := OptionButton.new()
	card.add_child(difficulty)
	difficulty.position = Vector2(255, 150)
	difficulty.size = Vector2(345, 47)
	difficulty.add_theme_font_override("font", FONT)
	difficulty.add_theme_font_size_override("font_size", 24)
	for text in ["ACEMİ  ·  Hafif atışma", "NORMAL  ·  Kasa kavgası", "USTA  ·  Sinirli mesai"]:
		difficulty.add_item(text)
	difficulty.select(settings.difficulty)
	difficulty.item_selected.connect(func(index):
		settings.difficulty = index
		save_settings())
	var options := [["shake", "Kamera sarsıntısı"], ["vibration", "Telefon titreşimi"], ["large_controls", "Büyük dokunmatik düğmeler"]]
	for i in options.size():
		var key: String = options[i][0]
		var check := CheckButton.new()
		card.add_child(check)
		check.text = options[i][1]
		check.position = Vector2(27, 224 + 58 * i)
		check.size = Vector2(580, 46)
		check.add_theme_font_override("font", FONT)
		check.add_theme_font_size_override("font_size", 25)
		check.button_pressed = settings[key]
		check.toggled.connect(func(value):
			settings[key] = value
			arena.shake_enabled = settings.shake
			layout()
			save_settings())
	label(card, "Ayarların bu cihazda otomatik kaydedilir.", 18, MUTED).position = Vector2(32, 407)
	var back := button(card, "TAMAM", "yellow", close_modal)
	back.position = Vector2(32, 461)
	back.size = Vector2(576, 50)
	back.grab_focus()

func show_help() -> void:
	var card := open_modal("KASANIN KURALLARI", 595)
	var rows := [
		["01  YAKLAŞ", "Sol / sağ düğmelerine basılı tut. Klavye: A / D veya oklar."],
		["02  VUR", "Yumruk: J  ·  Tekme: K. Tekme daha uzağa erişir, daha yavaştır."],
		["03  SAVUN", "Savunma düğmesine veya S'ye basılı tut; hasar azalır."],
		["04  TANTANA", "Vurarak veya savunarak sarı barı doldur. Dolunca L ile özel vur."],
		["05  KAZAN", "İki raund alan kazanır. 60 saniye sonunda daha fazla can kazanır."]
	]
	for i in rows.size():
		label(card, rows[i][0], 23, YELLOW).position = Vector2(32, 90 + i * 76)
		var text := label(card, rows[i][1], 21, PAPER)
		text.position = Vector2(32, 119 + i * 76)
		text.size.x = 572
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(card, "Telefon: birden fazla düğmeye aynı anda dokunabilirsin.\nDuraklat: II veya Esc. Android geri tuşu da duraklatır.", 19, MUTED).position = Vector2(32, 484)
	var back := button(card, "ANLAŞILDI", "yellow", close_modal)
	back.position = Vector2(32, 535)
	back.size = Vector2(576, 43)
	back.grab_focus()

func show_credits() -> void:
	var card := open_modal("EMEĞİ GEÇENLER", 535)
	var body := label(card, "KENNEY  /  CC0\nAraçlar, yol ve şehir modelleri, arayüz, efektler, sesler.\n\nQUATERNIUS  /  CC0\nUltimate Modular Men: hazır karakterler ve dövüş animasyonları.\n\nBARLOW CONDENSED  /  SIL OPEN FONT LICENSE\nJeremy Tribby · Yazı tipi.\n\nGODOT ENGINE  /  MIT\nGodot 4.6 · Android uyumlu oyun motoru.", 22, PAPER)
	body.position = Vector2(32, 92)
	body.size.x = 576
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(card, "Tam kaynak listesi ve lisans metinleri repoda: docs/ASSETS.md", 18, MUTED).position = Vector2(32, 423)
	var back := button(card, "GERİ", "yellow", close_modal)
	back.position = Vector2(32, 462)
	back.size = Vector2(576, 48)
	back.grab_focus()

func pause_game() -> void:
	if phase not in ["fight", "countdown", "intermission"]:
		return
	previous_phase = phase
	phase = "paused"
	clear_inputs()
	arena.driving = false
	arena.player.freeze_animation(true)
	arena.bot.freeze_animation(true)
	var card := open_modal("MOLA VERDİK", 355)
	label(card, "Şoför de bir çay içsin. Maç burada bekliyor.", 24, MUTED).position = Vector2(32, 95)
	var resume := button(card, "DEVAM ET", "yellow", resume_game)
	resume.position = Vector2(32, 162)
	resume.size = Vector2(576, 53)
	var restart := button(card, "YENİ MAÇ", "grey", start_match)
	restart.position = Vector2(32, 224)
	restart.size = Vector2(280, 50)
	var back := button(card, "ANA MENÜ", "grey", show_menu)
	back.position = Vector2(328, 224)
	back.size = Vector2(280, 50)
	resume.grab_focus()

func resume_game() -> void:
	modal.hide()
	phase = previous_phase
	arena.driving = true
	arena.player.freeze_animation(false)
	arena.bot.freeze_animation(false)

func show_result() -> void:
	phase = "result"
	notice.hide()
	quip.hide()
	var victory: bool = arena.player.wins >= 2
	var card := open_modal("KASANIN KRALI SENSİN!" if victory else "BU SEFER KASA ABİSİ!", 395)
	label(card, "%d  —  %d" % [arena.player.wins, arena.bot.wins], 70, PAPER).position = Vector2(245, 89)
	label(card, "“Abi, bunu nakliye faturasına yazma.”" if victory else "Bir rövanş alırsın. Daha yol bitmedi.", 25, MUTED).position = Vector2(32, 187)
	var retry := button(card, "RÖVANŞ", "yellow", start_match)
	retry.position = Vector2(32, 271)
	retry.size = Vector2(280, 60)
	var back := button(card, "ANA MENÜ", "grey", show_menu)
	back.position = Vector2(328, 271)
	back.size = Vector2(280, 60)
	retry.grab_focus()
	sound("confirmation_001" if victory else "error_001")

func action_held(action: String) -> bool:
	return held.get(action, false) or action in touch_actions.values()

func clear_inputs() -> void:
	held = {"left": false, "right": false, "guard": false}
	touch_actions.clear()
	if arena != null:
		arena.player.move_axis = 0
		arena.bot.move_axis = 0
		arena.player.guard = false
		arena.bot.guard = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not event.pressed:
			touch_actions.erase(event.index)
		elif phase == "fight":
			for action in action_buttons:
				if action_buttons[action].get_global_rect().has_point(event.position):
					if action in held:
						touch_actions[event.index] = action
					else:
						request_attack(action)
					get_viewport().set_input_as_handled()
					break
	elif event is InputEventScreenDrag and touch_actions.has(event.index):
		var action: String = touch_actions[event.index]
		if not action_buttons[action].get_global_rect().grow(24).has_point(event.position):
			touch_actions.erase(event.index)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			back_action()
			get_viewport().set_input_as_handled()
		elif phase == "fight":
			match event.physical_keycode:
				KEY_J: request_attack("punch")
				KEY_K: request_attack("kick")
				KEY_L: request_attack("special")

func back_action() -> void:
	if phase == "paused":
		resume_game()
	elif phase in ["fight", "countdown", "intermission"]:
		pause_game()
	elif modal.visible and phase == "menu":
		close_modal()
	elif phase == "result":
		show_menu()
	else:
		var card := open_modal("YOLCULUK BİTSİN Mİ?", 265)
		label(card, "Kasaya yine bekleriz.", 24, MUTED).position = Vector2(32, 95)
		var exit := button(card, "ÇIK", "red", func(): get_tree().quit())
		exit.position = Vector2(32, 160)
		exit.size = Vector2(280, 58)
		var back := button(card, "KAL", "yellow", close_modal)
		back.position = Vector2(328, 160)
		back.size = Vector2(280, 58)
		back.grab_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(arena):
			back_action()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(arena):
			pause_game()

func sound(name: String) -> void:
	if effects.is_empty() or settings.volume <= 0:
		return
	var audio := effects[sfx_index % effects.size()]
	sfx_index += 1
	audio.stream = load("res://assets/audio/" + name + ".ogg")
	audio.volume_db = linear_to_db(float(settings.volume)) - 4.0
	audio.play()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in settings:
			settings[key] = config.get_value("settings", key, settings[key])
	settings.volume = clampf(float(settings.volume), 0, 1)
	settings.difficulty = clampi(int(settings.difficulty), 0, 2)

func save_settings() -> void:
	var config := ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	config.save("user://settings.cfg")

func apply_volume() -> void:
	for audio in effects:
		audio.volume_db = linear_to_db(maxf(0.0001, float(settings.volume))) - 4.0
