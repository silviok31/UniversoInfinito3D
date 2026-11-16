extends Node3D

const SAVE_PATH := "user://survival.json"
const WORLD_SIZE := 90.0
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var joystick_base: Control
var joystick_knob: ColorRect
var touch_origin := Vector2.ZERO
var touch_id := -1
var touch_vector := Vector2.ZERO
var look_id := -1
var health := 100.0
var hunger := 100.0
var thirst := 100.0
var wood := 0
var stone := 0
var shelters := 0
var time_alive := 0.0
var resources: Array[Node3D] = []
var environment_root: Node3D
var camera_yaw := 0.0
var camera_pitch := -0.28
var message := "Colete madeira e pedra para construir um abrigo"
var message_timer := 8.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()
	_load_game()
	_update_hud()

func _material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func _box(parent: Node3D, name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.44, 0.63, 0.75)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.71, 0.78)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	add_child(ground)
	_box(ground, "Terrain", Vector3(WORLD_SIZE, 1, WORLD_SIZE), Vector3(0, -0.5, 0), Color(0.22, 0.34, 0.21))
	var shape := CollisionShape3D.new()
	var collision := BoxShape3D.new()
	collision.size = Vector3(WORLD_SIZE, 1, WORLD_SIZE)
	shape.shape = collision
	shape.position.y = -0.5
	ground.add_child(shape)
	environment_root = Node3D.new()
	environment_root.name = "ProceduralWorld"
	add_child(environment_root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 731992
	for i in range(85):
		var x := rng.randf_range(-42, 42)
		var z := rng.randf_range(-42, 42)
		if Vector2(x, z).length() < 7: continue
		var item := Node3D.new()
		item.position = Vector3(x, 0, z)
		item.set_meta("kind", "wood" if i % 3 != 0 else "stone")
		environment_root.add_child(item)
		if item.get_meta("kind") == "wood":
			_box(item, "Trunk", Vector3(0.55, 3, 0.55), Vector3(0, 1.5, 0), Color(0.35, 0.21, 0.12))
			_box(item, "Leaves", Vector3(2.2, 2.5, 2.2), Vector3(0, 3.4, 0), Color(0.09 + rng.randf_range(0, 0.07), 0.29, 0.14))
		else:
			_box(item, "Rock", Vector3(rng.randf_range(0.8, 1.6), 0.8, 1.2), Vector3(0, 0.4, 0), Color(0.35, 0.38, 0.39))
		resources.append(item)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Survivor"
	player.position = Vector3(0, 1, 0)
	add_child(player)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collider.shape = capsule
	player.add_child(collider)
	_box(player, "Suit", Vector3(0.65, 1.0, 0.4), Vector3(0, 0, 0), Color(0.16, 0.25, 0.32))
	_box(player, "Helmet", Vector3(0.52, 0.48, 0.5), Vector3(0, 0.75, 0), Color(0.75, 0.82, 0.86))
	_box(player, "Visor", Vector3(0.44, 0.25, 0.05), Vector3(0, 0.78, -0.27), Color(0.07, 0.22, 0.29))
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)

func _make_button(title: String, anchor: Vector2, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.anchor_left = anchor.x
	btn.anchor_right = anchor.x
	btn.anchor_top = anchor.y
	btn.anchor_bottom = anchor.y
	btn.offset_left = -156
	btn.offset_right = -16
	btn.offset_top = -74
	btn.offset_bottom = -16
	btn.add_theme_font_size_override("font_size", 19)
	btn.pressed.connect(callback)
	get_node("HUD").add_child(btn)
	return btn

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20, 16)
	hud.add_theme_font_size_override("font_size", 21)
	hud.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.add_theme_constant_override("shadow_offset_x", 2)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(hud)
	_make_button("COLETAR", Vector2(1, 1), _collect)
	var build_btn := _make_button("ABRIGO", Vector2(1, 1), _build_shelter)
	build_btn.offset_top = -142
	build_btn.offset_bottom = -84
	var eat_btn := _make_button("COMER", Vector2(1, 1), _eat)
	eat_btn.offset_top = -210
	eat_btn.offset_bottom = -152
	var save_btn := _make_button("SALVAR", Vector2(1, 0), _save_game)
	save_btn.offset_top = 16
	save_btn.offset_bottom = 70
	joystick_base = Control.new()
	joystick_base.anchor_top = 1
	joystick_base.anchor_bottom = 1
	joystick_base.offset_left = 30
	joystick_base.offset_right = 190
	joystick_base.offset_top = -190
	joystick_base.offset_bottom = -30
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(joystick_base)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.15, 0.19, 0.42)
	bg.size = Vector2(160, 160)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(bg)
	joystick_knob = ColorRect.new()
	joystick_knob.color = Color(0.6, 0.85, 0.94, 0.75)
	joystick_knob.size = Vector2(62, 62)
	joystick_knob.position = Vector2(49, 49)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_knob)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.42 and touch_id == -1:
			touch_id = event.index
			touch_origin = joystick_base.global_position + Vector2(80, 80)
			_set_joystick(event.position)
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			touch_vector = Vector2.ZERO
			joystick_knob.position = Vector2(49, 49)
		elif event.pressed and event.position.x >= get_viewport().get_visible_rect().size.x * 0.42 and look_id == -1:
			look_id = event.index
		elif not event.pressed and event.index == look_id:
			look_id = -1
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_set_joystick(event.position)
		elif event.index == look_id:
			camera_yaw -= event.relative.x * 0.005
			camera_pitch = clampf(camera_pitch - event.relative.y * 0.004, -0.85, 0.25)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_yaw -= event.relative.x * 0.005
		camera_pitch = clampf(camera_pitch - event.relative.y * 0.004, -0.85, 0.25)

func _set_joystick(pos: Vector2) -> void:
	touch_vector = ((pos - touch_origin) / 65.0).limit_length(1.0)
	joystick_knob.position = Vector2(49, 49) + touch_vector * 49.0

func _physics_process(delta: float) -> void:
	var keyboard := Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))).normalized()
	var axis := touch_vector if touch_vector.length() > 0.08 else keyboard
	var move := Vector3(axis.x, 0, axis.y).rotated(Vector3.UP, camera_yaw)
	player.velocity.x = move.x * 5.0
	player.velocity.z = move.z * 5.0
	player.velocity.y -= 18.0 * delta
	player.move_and_slide()
	if move.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-move.x, -move.z), delta * 9.0)
	var offset := Vector3(0, 3.0, 6.2).rotated(Vector3.RIGHT, camera_pitch).rotated(Vector3.UP, camera_yaw)
	camera.global_position = camera.global_position.lerp(player.global_position + offset, minf(1.0, delta * 8.0))
	camera.look_at(player.global_position + Vector3.UP * 0.5)

func _process(delta: float) -> void:
	time_alive += delta
	hunger = maxf(0, hunger - delta * 0.18)
	thirst = maxf(0, thirst - delta * 0.27)
	if hunger <= 0 or thirst <= 0:
		health = maxf(0, health - delta * 1.2)
	if health <= 0:
		_respawn()
	message_timer -= delta
	_update_hud()

func _update_hud() -> void:
	if hud == null: return
	var status := "UNIVERSO INFINITO 3D | SOBREVIVÊNCIA\nVida: %d  Fome: %d  Sede: %d\nMadeira: %d  Pedra: %d  Abrigos: %d\nTempo: %ds" % [int(health), int(hunger), int(thirst), wood, stone, shelters, int(time_alive)]
	if message_timer > 0: status += "\n" + message
	hud.text = status

func _notify(msg: String) -> void:
	message = msg
	message_timer = 4.0

func _collect() -> void:
	var closest: Node3D = null
	var distance := 3.8
	for item in resources:
		if not is_instance_valid(item): continue
		var d := item.global_position.distance_to(player.global_position)
		if d < distance:
			closest = item
			distance = d
	if closest == null:
		_notify("Chegue mais perto de uma árvore ou rocha")
		return
	if closest.get_meta("kind") == "wood":
		wood += 2
		_notify("+2 madeira coletada")
	else:
		stone += 2
		_notify("+2 pedra coletada")
	resources.erase(closest)
	closest.queue_free()

func _build_shelter() -> void:
	if wood < 6 or stone < 4:
		_notify("Abrigo exige 6 madeiras e 4 pedras")
		return
	wood -= 6
	stone -= 4
	shelters += 1
	var shelter := Node3D.new()
	shelter.position = player.global_position + Vector3(0, -0.2, -4).rotated(Vector3.UP, camera_yaw)
	environment_root.add_child(shelter)
	_box(shelter, "Floor", Vector3(4, 0.3, 4), Vector3(0, 0.15, 0), Color(0.42, 0.29, 0.17))
	for x in [-1.7, 1.7]:
		for z in [-1.7, 1.7]:
			_box(shelter, "Pillar", Vector3(0.25, 2.5, 0.25), Vector3(x, 1.25, z), Color(0.33, 0.19, 0.1))
	_box(shelter, "Roof", Vector3(4.6, 0.4, 4.6), Vector3(0, 2.65, 0), Color(0.23, 0.23, 0.25))
	_notify("Abrigo construído! +20 de vida")
	health = minf(100, health + 20)
	_save_game()

func _eat() -> void:
	if wood < 1:
		_notify("Colete 1 madeira para acender uma fogueira")
		return
	wood -= 1
	hunger = minf(100, hunger + 25)
	thirst = minf(100, thirst + 15)
	_notify("Suprimentos preparados na fogueira (+fome e sede)")

func _respawn() -> void:
	player.global_position = Vector3(0, 2, 0)
	health = 100
	hunger = 65
	thirst = 65
	_notify("Você desmaiou e retornou ao ponto inicial")

func _save_game() -> void:
	var data := {"health": health, "hunger": hunger, "thirst": thirst, "wood": wood, "stone": stone, "shelters": shelters, "time": time_alive, "pos": [player.position.x, player.position.y, player.position.z]}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_notify("Falha ao salvar")
		return
	file.store_string(JSON.stringify(data))
	_notify("Jogo salvo no dispositivo")

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary: return
	health = float(data.get("health", 100))
	hunger = float(data.get("hunger", 100))
	thirst = float(data.get("thirst", 100))
	wood = int(data.get("wood", 0))
	stone = int(data.get("stone", 0))
	shelters = int(data.get("shelters", 0))
	time_alive = float(data.get("time", 0))
	var pos = data.get("pos", [0, 1, 0])
	if pos is Array and pos.size() == 3:
		player.position = Vector3(float(pos[0]), maxf(1, float(pos[1])), float(pos[2]))
