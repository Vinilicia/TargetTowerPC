extends Node2D

@export var horizontal_checker : RayCast2D
@export var vertical_checker : RayCast2D

var polygon : CollisionPolygon2D
var direction : int = 1:
	set(new_value):
		if new_value == 0:
			direction = 1
		else:
			direction = sign(new_value)
		horizontal_checker.target_position.y = abs(horizontal_checker.target_position.y) * -direction

var points_array : Array[Vector2] = []
var right_side : Array[Vector2] = []
var left_side : Array[Vector2] = []
var start_next : int = 0
var num_jumps : int = 0
var original_pos : Vector2

func get_polygon(length : float) -> CollisionPolygon2D:
	original_pos = position
	
	num_jumps = (length / 2) / abs(horizontal_checker.target_position.length())
	
	check()
	return polygon

func optimize_polygon(points: Array[Vector2]) -> Array[Vector2]:
	if points.size() < 3:
		return points

	var optimized: Array[Vector2] = []
	optimized.append(points[0])

	for i in range(1, points.size()):
		var p_prev = optimized[-1]
		var p_curr = points[i]
		
		# 1. Ignorar se o ponto for virtualmente igual ao anterior
		if p_curr.is_equal_approx(p_prev):
			continue
			
		if i < points.size() - 1:
			var p_next = points[i + 1]
			
			# Vetores de direção
			var dir_a = (p_curr - p_prev).normalized()
			var dir_b = (p_next - p_curr).normalized()
			
			# 2. Checar Colinearidade e Backtracking usando o Produto Escalar (Dot Product)
			# O dot_product de dois vetores normalizados resulta em:
			#  1.0 se apontam para o mesmo lado (linha reta)
			# -1.0 se apontam para lados opostos (volta de 180 graus)
			var dot = dir_a.dot(dir_b)
			
			# Se o dot for quase 1 (reta) ou quase -1 (dobra/backtrack)
			if abs(dot) > 0.99:
				# Se for uma dobra (backtrack), o ponto atual é o "pico" inútil
				# Se for uma reta, o ponto atual é apenas um degrau desnecessário
				continue 
		
		optimized.append(p_curr)

	# Checagem final para fechar o polígono sem duplicar o início e o fim
	if optimized.size() > 2 and optimized[0].is_equal_approx(optimized[-1]):
		optimized.remove_at(optimized.size() - 1)
		
	return optimized

func check() -> void:
	var jump_dist : float = abs(horizontal_checker.target_position.length())
	var vertical_offset : float = abs(vertical_checker.target_position.length())

	# 1. Setup inicial baseado no transform global do pai
	global_position = get_parent().to_global(original_pos)
	global_rotation = get_parent().global_rotation
	
	var start_global_transform = global_transform
	
	left_side.clear()
	right_side.clear()

	# Rodamos o processo para as duas direções
	var directions = [-1, 1]
	
	for dir in directions:
		direction = dir
		# Reseta o "fantasma" para a posição inicial antes de cada lado
		global_transform = start_global_transform
		
		var current_surface : Array[Vector2] = []
		var current_offset : Array[Vector2] = []

		for i in range(num_jumps):
			#await get_tree().create_timer(0.2).timeout
			force_update_transform()
			horizontal_checker.force_raycast_update()
			vertical_checker.force_raycast_update()

			if vertical_checker.is_colliding():
				var g_col = vertical_checker.get_collision_point()
				var g_norm = vertical_checker.get_collision_normal()
				var g_off = g_col + (g_norm * vertical_offset)

				# Converte a posição global para o local relativo ao início (ponto zero)
				current_surface.append(start_global_transform.affine_inverse() * g_col)
				current_offset.append(start_global_transform.affine_inverse() * g_off)

				if horizontal_checker.is_colliding():
					global_position = g_col + (g_norm * vertical_offset)
					global_rotation += deg_to_rad(90) * -direction
				else:
					# Reta: move para o lado baseando-se na normal da superfície
					var side_dir = g_norm.rotated(deg_to_rad(90) * direction)
					global_position += side_dir * jump_dist
			else:
				if !current_offset.is_empty():
					current_offset.append(current_offset.back() + horizontal_checker.target_position.rotated(rotation))
				global_rotation += deg_to_rad(90) * direction
				global_position += Vector2(0, -direction * vertical_offset).rotated(global_rotation)

		# Organiza os pontos para formar o contorno sem cruzar linhas
		if direction == -1:
			left_side.append_array(current_surface)
			current_offset.reverse()
			left_side.append_array(current_offset)
		else:
			# Slice(1) evita duplicar o primeiro ponto de offset que já está no left_side
			right_side.append_array(current_offset.slice(1))
			current_surface.reverse()
			right_side.append_array(current_surface)

	# 2. Montagem final do polígono
	var final_points : Array[Vector2] = []
	final_points.append_array(left_side)
	final_points.append_array(right_side)
	final_points = optimize_polygon(final_points)
	
	polygon = CollisionPolygon2D.new()
	polygon.polygon = final_points
