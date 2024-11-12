extends Node

@onready var parent : Node2D = get_parent()

@export_category("General")

@export var is_pushable : bool
@export var is_freezable : bool
@export var is_heatable : bool
@export var is_dryable : bool
@export var is_electrifiable : bool

############################################# GENERAL ############################################

############################################# PUSHABLE #############################################

@export_category("Pushable")

############################################ FLAMMABLE ############################################

@export_category("Heatable")

############################################ FREEZABLE ############################################

@export_category("Freezable")

############################################ DRYABLE ############################################

@export_category("Dryable")

############################################ ELECTRIFIABLE ############################################

@export_category("Electrifiable")
