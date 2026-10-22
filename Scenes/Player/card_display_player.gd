class_name CardDisplayPlayer extends StaticBody3D

@onready var top_part: MeshInstance3D = $Top_Part

func set_skin(skin: CompressedTexture2D):
	var material = top_part.get_surface_override_material(0) as StandardMaterial3D
	
	if not material:
		var active_mat = top_part.get_active_material(0) as StandardMaterial3D
		if active_mat:
			material = active_mat.duplicate() as StandardMaterial3D
			top_part.set_surface_override_material(0, material)
		else:
			material = StandardMaterial3D.new()
			top_part.set_surface_override_material(0, material)
	
	if material:
		material.albedo_texture = skin
