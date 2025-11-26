extends Button

@export_range(1.0, 3.0, 1.0) var save_slot : int 
@export var arrow_texture_nodes : Array[TextureRect]
@export var arrow_textures : Array[Texture2D]
@export var bench_name_label : Label

func init_arrow_textures(save_data : SaveDataResource) -> void:
	for i in range(arrow_texture_nodes.size()):
		if save_data.get_available_arrow(i+1): # Aqui nesse ponto o erro ocorre
			arrow_texture_nodes[i].texture = arrow_textures[i]

func initialize() -> void:
	if SaveManager._load(save_slot):
		var save_data = SaveManager.save_file_data as SaveDataResource
		if save_data == null:
			push_error("save_data é nulo no slot %d!" % save_slot)
			return
		init_arrow_textures(save_data)
		bench_name_label.text = tr("TEXT_BENCH") + str(" ") + str(save_data.get_last_bench_id())
