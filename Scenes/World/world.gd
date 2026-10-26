extends Node2D

var bottle_scene = preload("res://Scenes/WaterBottle/water_bottle.tscn")

@onready var total_flips_landed = 0
@onready var streak = 0

@onready var water_bottle = $WaterBottle2DNode/WaterBottle
@onready var wb_node = $WaterBottle2DNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Input.is_key_pressed(KEY_A):
		if water_bottle:
			water_bottle.angular_velocity += water_bottle.spin_acceleration * delta
			
	elif Input.is_key_pressed(KEY_D):
		if water_bottle:
			water_bottle.angular_velocity += -water_bottle.spin_acceleration * delta
	else:
		if water_bottle:
			water_bottle.angular_velocity *= 0.9999
	


func _on_button_button_down() -> void:
	# 1. Remove/free all existing children inside the container
	
	for child in wb_node.get_children():
		child.queue_free()
		
	respawn_bottle()
	
	print("Water bottle successfully reinstantiated!")

func respawn_bottle() -> void:
	var new_bottle = bottle_scene.instantiate()
	
	# 1. Connect the signal immediately upon instantiation
	new_bottle.bottle_clicked.connect(_on_water_bottle_bottle_clicked)
	new_bottle.flip_landed.connect(_on_water_bottle_flip_landed)
	new_bottle.flip_failed.connect(_on_water_bottle_flip_failed)
	
	water_bottle = new_bottle
	# 2. Add it to the scene tree
	$WaterBottle2DNode.add_child(new_bottle)
	streak = 0
	$UI/Streak3.text = "Streak: " + str(streak)
	
func _on_water_bottle_bottle_clicked(clicked_position: Vector2) -> void:
	pass # Replace with function body.


func _on_water_bottle_flip_landed() -> void:
	water_bottle.angular_velocity *= 0.1
	total_flips_landed += 1
	streak += 1
	
	$UI/Streak3.text = "Streak: " + str(streak)
	$"UI/Flip Count".text = "Total Landed Flips: " + str(total_flips_landed)


func _on_water_bottle_flip_failed() -> void:
	streak = 0
	$UI/Streak3.text = "Streak: " + str(streak)
