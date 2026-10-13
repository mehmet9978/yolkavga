class_name RoadFighter
extends Node3D

signal landed(attacker, defender, damage: int, blocked: bool, kind: String)

const ATTACKS := {
	"punch": {"damage": 8, "reach": 1.65, "windup": 0.16, "duration": 0.42, "clip": "Punch_Right"},
	"kick": {"damage": 13, "reach": 2.1, "windup": 0.29, "duration": 0.70, "clip": "Kick_Right"},
	"special": {"damage": 25, "reach": 2.65, "windup": 0.25, "duration": 1.05, "clip": "Sword_Slash"}
}

var health: int = 100
var meter: float = 0.0
var wins: int = 0
var opponent: RoadFighter
var guard: bool = false
var move_axis: float = 0.0
var active: bool = false
var model: Node3D
var animator: AnimationPlayer
var clips: Dictionary = {}
var state: String = "idle"
var attack_kind: String = ""
var attack_elapsed: float = 0.0
var attack_landed: bool = false
var busy: float = 0.0
var invulnerable: float = 0.0
var combo: int = 0
var combo_window: float = 0.0
var facing: float = 1.0

func setup(path: String) -> void:
	model = load(path).instantiate()
	add_child(model)
	animator = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(animator != null, "Hazır karakterde AnimationPlayer bulunamadı.")
	for full_name in animator.get_animation_list():
		var short_name: String = String(full_name).get_slice("|", 1)
		if short_name.is_empty():
			short_name = String(full_name)
		clips[short_name] = full_name
		if short_name.begins_with("Idle") or short_name in ["Walk", "Run"]:
			animator.get_animation(full_name).loop_mode = Animation.LOOP_LINEAR
	play_clip("Idle")

func reset_round(x: float) -> void:
	health = 100
	meter = 0.0
	position = Vector3(x, 0, 0)
	guard = false
	move_axis = 0
	busy = 0
	invulnerable = 0
	state = "idle"
	attack_kind = ""
	combo = 0
	combo_window = 0
	face_opponent()
	play_clip("Idle")

func play_clip(clip: String, speed: float = 1.0) -> void:
	if clips.has(clip):
		animator.play(clips[clip], 0.08, speed)

func face_opponent() -> void:
	if opponent != null:
		facing = 1.0 if opponent.position.x >= position.x else -1.0
		rotation.y = facing * PI / 2.0

func attack(kind: String) -> bool:
	if not active or health <= 0 or busy > 0 or not ATTACKS.has(kind):
		return false
	if kind == "special":
		if meter < 100.0:
			return false
		meter = 0
	guard = false
	face_opponent()
	state = "attack"
	attack_kind = kind
	attack_elapsed = 0
	attack_landed = false
	busy = ATTACKS[kind].duration
	play_clip(ATTACKS[kind].clip, 1.5 if kind == "punch" else 1.3)
	return true

func tick(delta: float) -> void:
	if not active or health <= 0:
		return
	invulnerable = maxf(0, invulnerable - delta)
	combo_window = maxf(0, combo_window - delta)
	if combo_window <= 0:
		combo = 0
	busy = maxf(0, busy - delta)
	if state == "attack":
		attack_elapsed += delta
		if not attack_landed and attack_elapsed >= ATTACKS[attack_kind].windup:
			attack_landed = true
			resolve_hit()
		if busy <= 0:
			state = "idle"
			play_clip("Idle")
		return
	if busy > 0:
		return
	face_opponent()
	if guard:
		if state != "guard":
			state = "guard"
			play_clip("Idle_Sword")
		return
	if absf(move_axis) > 0.1:
		var next_x: float = clampf(position.x + move_axis * delta * 2.25, -1.9, 1.9)
		if opponent == null or absf(next_x - opponent.position.x) >= 0.7:
			position.x = next_x
		if state != "walk":
			state = "walk"
			play_clip("Walk", 1.4)
	elif state != "idle":
		state = "idle"
		play_clip("Idle")

func resolve_hit() -> void:
	if opponent == null or opponent.health <= 0 or opponent.invulnerable > 0:
		return
	if absf(opponent.position.x - position.x) > ATTACKS[attack_kind].reach:
		return
	var blocked: bool = opponent.guard and opponent.busy <= 0
	var damage: int = ATTACKS[attack_kind].damage
	if blocked:
		damage = maxi(1, int(damage * 0.20))
		opponent.meter = minf(100, opponent.meter + 9)
		opponent.invulnerable = 0.12
	else:
		combo += 1
		combo_window = 1.1
		if attack_kind != "special":
			meter = minf(100, meter + 14)
		opponent.meter = minf(100, opponent.meter + 5)
		opponent.state = "hurt"
		opponent.busy = 0.24
		opponent.invulnerable = 0.25
		opponent.play_clip("HitRecieve", 1.5)
		opponent.position.x = clampf(opponent.position.x + facing * (0.12 if attack_kind == "punch" else 0.22), -1.9, 1.9)
		opponent.combo = 0
	opponent.health = maxi(0, opponent.health - damage)
	if opponent.health == 0:
		opponent.state = "ko"
		opponent.play_clip("Death")
	landed.emit(self, opponent, damage, blocked, attack_kind)

func freeze_animation(frozen: bool) -> void:
	animator.speed_scale = 0.0 if frozen else 1.0
