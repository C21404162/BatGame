extends Node3D

@onready var ambience = $ambience
@onready var fade_in = $Fade_interact/fade_in  
@onready var left_hand = $Player/lefthand
@onready var right_hand = $Player/righthand
@onready var speedrun_timer_label = $SpeedrunTimer

var bats_fed: int = 0
@export var bats_required: int = 5
@onready var feeding_area = $FeedingArea  # Add this Area3D to your world scene
@onready var player = $Player  # Reference to your player node

func _process(delta):
	

	if GameManager.speedrun_active:
		GameManager.speedrun_time += delta
		speedrun_timer_label.text = GameManager.get_formatted_time()

func update_speedrun_ui(visible: bool):
	speedrun_timer_label.visible = visible && GameManager.speedrun_mode
	if visible:
		speedrun_timer_label.text = GameManager.get_formatted_time()

func _ready() -> void:
	GameManager.speedrun_finished.connect(_on_speedrun_finished)
	update_speedrun_ui(GameManager.speedrun_mode)
	fade_in.play("fade_in")
	#ambience.play()
	#ambience.volume_db = -20
	speedrun_timer_label.visible = GameManager.speedrun_mode
	if GameManager.speedrun_mode:
		GameManager.start_speedrun()
	#tween.interpolate_property(ambient_sound, "volume_db", -80, 0, 2.0)  # Fade in
	#tween.start()
	feeding_area.body_entered.connect(_on_feeding_area_body_entered)
	
func _on_speedrun_finished(time: float):
	speedrun_timer_label.add_theme_color_override("font_color", Color.GREEN)
	speedrun_timer_label.visible = true
	speedrun_timer_label.text = "Final Time: " + GameManager.get_formatted_time()

func _on_feeding_area_body_entered(body: Node):
	if body.is_in_group("Bat"):
		print("BAT FED")
		print(bats_fed)
		# Check if bat is being carried by player
		feed_bat(body)
		player.release_grabbed_bat(body)  # New helper function we'll add to player

func feed_bat(bat: Node):
	bats_fed += 1
	print("Bats fed: ", bats_fed)
	bat.queue_free()
	
	if bats_fed >= bats_required:
		complete_quest()

func complete_quest():
	print("Quest complete! The character is satisfied.")
	# Add your quest completion logic here
