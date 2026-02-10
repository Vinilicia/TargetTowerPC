extends Node
class_name Anim_Handler

enum TERRAIN_STATE { Grounded, Airbone }
enum ANIM_STATE { Grounded, Airbone, Hurt, Attack, Dodge}

@onready var anim: AnimationPlayer = $"../../Utilities/Archer/AnimationPlayer"
@onready var v_comp: VelocityComponent = $"../VelocityComponent"

# ------------------------------ MOVEMENT ------------------------------ #
var terrain_state : TERRAIN_STATE = TERRAIN_STATE.Grounded
var state : ANIM_STATE = ANIM_STATE.Grounded

func grounded_entered() -> void:
	pass

var crouching : bool = false

func crouched() -> void:
	crouching = true
	anim.play("Crouch")

func stood() -> void:
	crouching = false

func grounded_process() -> void:
	if crouching:
		return
	if anim.current_animation == "Land":
		return
	if v_comp.get_proper_velocity().x != 0.0:
		if anim.current_animation != "Run" and anim.current_animation != "RunLoop":
			anim.play("Run")
			anim.queue("RunLoop")
	else:
		if anim.current_animation != "Idle":
			anim.play("Idle")

func grounded_to_airbone() -> void:
	if v_comp.get_total_velocity().y < 0:
		anim.play("Jump")
	else:
		anim.play("Apex")
	airbone_entered()

func airbone_entered() -> void:
	if anim.current_animation == "Jump":
		anim.queue("Rise")
	elif anim.current_animation == "Apex":
		anim.queue("Fall")

func airbone_process() -> void:
	if v_comp.get_total_velocity().y >= 0 and anim.current_animation == "Rise":
		anim.play("Apex")
		anim.queue("Fall")
	elif v_comp.get_total_velocity().y < 0 and anim.current_animation == "Fall":
		# PLAY STOMP
		anim.play("Rise")

func airbone_to_grounded() -> void:
	anim.play("Land")
	grounded_entered()

func hurt_entered() -> void:
	anim.clear_queue()
	anim.play("Hurt")
	await anim.animation_finished
	if v_comp.get_proper_velocity(2) != 0:
		state = ANIM_STATE.Airbone
		airbone_entered()
	else:
		state = ANIM_STATE.Grounded
		grounded_entered()

func change_state(new_state : ANIM_STATE) -> void:
	if new_state == state or state == ANIM_STATE.Hurt:
		return
	match state:
		ANIM_STATE.Grounded:
			match new_state:
				ANIM_STATE.Airbone:
					grounded_to_airbone()
				ANIM_STATE.Hurt:
					hurt_entered()
				ANIM_STATE.Attack:
					pass
				ANIM_STATE.Dodge:
					pass
		ANIM_STATE.Airbone:
			match new_state:
				ANIM_STATE.Grounded:
					airbone_to_grounded()
				ANIM_STATE.Hurt:
					hurt_entered()
				ANIM_STATE.Attack:
					pass
				ANIM_STATE.Dodge:
					pass
	state = new_state

func handle_anim() -> void:
	match state:
		ANIM_STATE.Grounded:
			grounded_process()
		ANIM_STATE.Airbone:
			airbone_process()

func _process(_delta: float) -> void:
	handle_anim()

func _on_player_took_damage() -> void:
	change_state(ANIM_STATE.Hurt)
