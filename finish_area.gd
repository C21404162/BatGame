extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		GameManager.stop_speedrun()
		print("Speedrun stopped")
		#sound effects maybe
