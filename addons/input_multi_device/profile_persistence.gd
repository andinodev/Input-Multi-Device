class_name InputMultiDevicePersistence
extends RefCounted
## Helper estático para manejar la persistencia en disco de los perfiles de InputMultiDevice.

## Guarda el diccionario de perfiles en disco.
## Formato esperado de profile_dict: { "ProfileName": { "action_name": InputEvent, ... }, ... }
static func save_to_disk(profile_dict: Dictionary, file_path: String = "user://input_profiles.cfg") -> void:
	var config = ConfigFile.new()
	
	for profile_name in profile_dict:
		var actions_dict = profile_dict[profile_name]
		
		for action_name in actions_dict:
			var event = actions_dict[action_name]
			# Godot serializa nativamente los InputEvent dentro de un ConfigFile
			config.set_value(profile_name, action_name, event)
			
	var err = config.save(file_path)
	if err != OK:
		push_error("InputMultiDevice: Fallo al guardar perfiles de botones. Error: ", err)

## Carga y retorna los perfiles de botones desde el disco.
## Retorna un diccionario vacío {} si el archivo no existe o hay error.
static func load_from_disk(file_path: String = "user://input_profiles.cfg") -> Dictionary:
	var config = ConfigFile.new()
	var result_dict = {}
	
	var err = config.load(file_path)
	if err != OK:
		return result_dict
		
	for section in config.get_sections():
		var profile_name = section
		result_dict[profile_name] = {}
		
		for action_name in config.get_section_keys(section):
			var event = config.get_value(section, action_name)
			if event is InputEvent:
				result_dict[profile_name][action_name] = event
				
	return result_dict
