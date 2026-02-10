extends Area2D

@export var upgrade_index : int 
@export var increase_amount : int = 100

func _ready() -> void:
	print("COMI COCO", SaveManager.save_file_data.get("MoneyUpgrades"))
	if SaveManager.save_file_data.get_money_upgrade(upgrade_index):
		queue_free()
		
func _on_player_entered(player: Node2D) -> void:
	AudioManager.play_song("PickUp")
	print(SaveManager.save_file_data.get_max_money(), increase_amount, SaveManager.save_file_data.get_max_money() + increase_amount)
	SaveManager.save_file_data.set_max_money(SaveManager.save_file_data.get_max_money() + increase_amount)
	SaveManager.save_file_data.set_money_upgrade(upgrade_index)
	print(SaveManager.save_file_data.get_max_money(), increase_amount, SaveManager.save_file_data.get_max_money() + increase_amount)

	queue_free()
