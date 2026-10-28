class_name CameraRig
extends Node3D
## Kamera hinter der Figur: Maus ziehen dreht, Mausrad zoomt, der SpringArm verhindert Blick durch Wände.

var target: Node3D
var yaw := 0.0
var pitch := -0.42
var distance := 7.5

var _arm: SpringArm3D
var camera: Camera3D
var _dragging := false


func _ready() -> void:
	_arm = SpringArm3D.new()
	_arm.spring_length = distance
	_arm.margin = 0.3
	add_child(_arm)
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.current = true
	_arm.add_child(camera)


func exclude(body: CollisionObject3D) -> void:
	_arm.add_excluded_object(body.get_rid())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance * 0.9, 3.0, 16.0)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance * 1.1, 3.0, 16.0)
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		yaw -= mm.relative.x * 0.0055
		pitch = clampf(pitch - mm.relative.y * 0.004, -1.25, -0.1)


func _process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position + Vector3(0.0, 1.25, 0.0)
	global_position = global_position.lerp(goal, minf(1.0, delta * 10.0))
	rotation = Vector3(pitch, yaw, 0.0)
	_arm.spring_length = lerpf(_arm.spring_length, distance, minf(1.0, delta * 8.0))


## Blickrichtung der Kamera auf dem Boden (für die Steuerung).
func flat_basis() -> Basis:
	return Basis(Vector3.UP, yaw)
