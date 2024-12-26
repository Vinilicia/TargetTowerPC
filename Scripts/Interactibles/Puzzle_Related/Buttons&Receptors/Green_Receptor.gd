extends Node2D

func on_button_pressed():
	get_parent().button_was_pressed()

func on_button_unpressed():
	get_parent().button_was_unpressed()
