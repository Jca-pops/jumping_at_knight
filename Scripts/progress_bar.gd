extends ProgressBar

func _on_player_health_update(current_health: int) -> void:
	if current_health < 0:
		current_health = 0
	self.value = current_health
	
	if  100.0 >= self.value and self.value >= 75.0:
		self.modulate = Color(0,0.69,0.54,1)
	if 74 >= self.value and self.value >= 35:
		self.modulate = Color(1,0.82,0.71,1)
	if 34 >= self.value and self.value >= 0:
		self.modulate = Color(0.83,0,0.7,1)
	
		
