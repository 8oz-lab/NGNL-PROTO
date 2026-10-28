class_name Hero
extends CharacterBody3D
## Sora oder Shiro: lädt das Modell, spielt Stehen/Gehen/Rennen und bewegt sich mit Kollision.

@export var display_name := "Sora"
@export var skill := ""
@export var model_scene: PackedScene
@export var height := 1.72

const WALK_SPEED := 3.3
const RUN_SPEED := 6.2

var model: Node3D
var anim: AnimationPlayer
var _idle := ""
var _walk := ""
var _run := ""
var _current := ""


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = height * 0.9
	shape.shape = capsule
	shape.position.y = height * 0.45
	add_child(shape)

	model = model_scene.instantiate()
	add_child(model)
	Toon.apply_to(model, 0.006)
	_fit_height()
	_setup_animations()


## Skaliert das Modell auf die gewünschte Körpergröße, Füße auf y = 0.
func _fit_height() -> void:
	var box := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var b: AABB = (global_transform.affine_inverse() * m.global_transform) * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first or box.size.y <= 0.0:
		return
	var k := height / box.size.y
	model.scale *= k
	model.position.y -= box.position.y * k
	model.position.x -= (box.position.x + box.size.x * 0.5) * k
	model.position.z -= (box.position.z + box.size.z * 0.5) * k


func _setup_animations() -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	anim = players[0]
	for n in anim.get_animation_list():
		var lower := String(n).to_lower()
		if lower.begins_with("standing") or lower.begins_with("idle"):
			_idle = n
		elif lower.begins_with("walk"):
			_walk = n
		elif lower.begins_with("run"):
			_run = n
		var a := anim.get_animation(n)
		a.loop_mode = Animation.LOOP_LINEAR
		_strip_root_motion(a)
	if _walk == "":
		_walk = _idle
	if _run == "":
		_run = _walk
	play_state("idle")


## Die Animationen bewegen die Hüfte nach vorne; das übernimmt hier die Spielfigur selbst.
func _strip_root_motion(a: Animation) -> void:
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(a.track_get_path(t)).contains("Hips"):
			continue
		var count := a.track_get_key_count(t)
		if count < 2:
			continue
		var first: Vector3 = a.track_get_key_value(t, 0)
		for k in range(1, count):
			var v: Vector3 = a.track_get_key_value(t, k)
			a.track_set_key_value(t, k, Vector3(first.x, v.y, first.z))


func play_state(state: String) -> void:
	if anim == null:
		return
	var name := _idle
	if state == "walk":
		name = _walk
	elif state == "run":
		name = _run
	if name == "" or name == _current:
		return
	_current = name
	anim.play(name, 0.22)
	anim.speed_scale = 1.3 if state == "walk" else 1.0


## Bewegt die Figur in Weltrichtung (Länge 0–1).
func drive(direction: Vector3, sprint: bool, delta: float) -> void:
	direction.y = 0.0
	var amount := minf(direction.length(), 1.0)
	if amount > 0.1:
		var dir := direction.normalized()
		var speed := (RUN_SPEED if sprint else WALK_SPEED) * amount
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		var target := atan2(dir.x, dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target, minf(1.0, delta * 12.0))
		play_state("run" if sprint else "walk")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		play_state("idle")
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()


## Läuft hinter der führenden Figur her.
func follow(leader: Hero, sprint: bool, delta: float) -> void:
	var to := leader.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > 10.0:
		global_position = leader.global_position + Vector3(-1.0, 0.0, 1.0)
		return
	if dist > 1.5:
		var fast := sprint or dist > 4.0
		drive(to.normalized() * minf(1.0, (dist - 1.3)), fast, delta)
	else:
		drive(Vector3.ZERO, false, delta)
