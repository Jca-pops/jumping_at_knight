extends CharacterBody2D
@onready var liquid_map:TileMapLayer = $"../TileMap/Liquid"
@onready var liquid_fire: TileMapLayer = $"../TileMap/LiquidFire"
@onready var liquid_lava: TileMapLayer = $"../TileMap/LiquidLava"
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var HEALTH: int = 100:
	set(updated_health):
		HEALTH = updated_health
		health_update.emit(updated_health)
	get:
		return HEALTH
@onready var SPEED: float = 130.0

signal health_update(current_health: int)

const LAND_SPEED: float = 130.0
const SWIM_SPEED: float = 75.0
const JUMP_VELOCITY: float = -300.0
const SWIM_VELOCITY: float = -120.0
const GRAVITY: float = 980.0
var frame_count: int = 0
var is_dead: bool = false

const damage_coords = [
	{"start_x": 7, "end_x": 15, "y":1}
]


func handle_jump_on_floor(game_gravity, delta):
	if not is_on_floor():
		velocity.y += game_gravity.y * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	return
		
func handle_liquid_swim(game_gravity, delta):
	if not is_on_floor():
		velocity.y += game_gravity.y * delta
		
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = SWIM_VELOCITY
	return
		
func handle_death_movement(game_gravity, delta):
	if not is_on_floor():
		velocity.y += game_gravity.y * delta
	return
		
func get_gravity_modifer(gravity_speed):
	match gravity_speed:
		"swim":
			return Vector2(0, GRAVITY * 0.5)
		"land":
			return Vector2(0, GRAVITY * 1)
		"death":
			return Vector2(0, GRAVITY * 0.7)
	
func adjust_health(amount:int):
	frame_count+=1
	if frame_count % 10 == 0: 
		HEALTH -= amount
		frame_count = 0
		print(HEALTH)
	if HEALTH <= 0:
		HEALTH = 0
		player_died()
	
func liquid_check() -> bool:
	var water_pos = liquid_map.to_local(global_position)
	var fire_pos = liquid_fire.to_local(global_position)
	var lava_pos = liquid_lava.to_local(global_position)
	# -y to allow the tile detection to favor where the majority of the player is and not just where its is standing.
	water_pos.y -= 0.5
	fire_pos.y -= 0.5
	lava_pos.y -= 0.5
	
	var water_coord = liquid_map.local_to_map(water_pos)
	var fire_coord = liquid_fire.local_to_map(fire_pos)
	var lava_coord = liquid_lava.local_to_map(lava_pos)
	
	var liquid_layer_check = liquid_map.get_cell_tile_data(water_coord)
	var fire_layer_check = liquid_fire.get_cell_tile_data(fire_coord)
	var lava_layer_check = liquid_lava.get_cell_tile_data(lava_coord)
	
	var is_liquid = false
	if liquid_layer_check:
		is_liquid = true
	if fire_layer_check:
		is_liquid = true
		adjust_health(5)
	if lava_layer_check:
		is_liquid = true
		adjust_health(20)
	return is_liquid
	
func player_died() -> void:
	is_dead = true
	Engine.time_scale = 0.7
	sprite.play("death")
	if sprite.animation_finished:
		await get_tree().create_timer(1.5).timeout
		get_tree().reload_current_scene()
		is_dead = false
			
func _physics_process(delta: float) -> void:
	if is_dead:
		var game_gravity = get_gravity_modifer("death")
		handle_death_movement(game_gravity, delta)
		move_and_slide()
		return
	var liquid_type = liquid_check()
	
	match liquid_type:
		false:
			var game_gravity = get_gravity_modifer("land")
			SPEED = LAND_SPEED
			handle_jump_on_floor(game_gravity, delta)
		_:
			var game_gravity = get_gravity_modifer("swim")
			SPEED = SWIM_SPEED
			handle_liquid_swim(game_gravity, delta)
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
