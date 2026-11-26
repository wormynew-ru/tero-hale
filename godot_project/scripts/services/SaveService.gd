class_name SaveService
extends Node

const SAVE_PATH: String = "user://save.tres"
const SAVE_BACKUP_PATH: String = "user://save.bak.tres"
const SAVE_TEMP_PATH: String = "user://save.tmp.tres"
const SAVE_SCHEMA_VERSION: int = 1
const AUTOSAVE_INTERVAL: float = 480.0
const SAVE_THROTTLE_INTERVAL: float = 120.0

var _gm: Node = null
var _autosave_timer: float = 0.0
var _save_throttle_timer: float = 0.0
var _save_pending: bool = false
var _save_thread: Thread = null
var _save_in_progress: bool = false
var _save_queued_after_worker: bool = false


func setup(host: Node) -> void:
	_gm = host


func process_tick(delta: float) -> void:
	if _save_throttle_timer > 0.0:
		_save_throttle_timer = maxf(0.0, _save_throttle_timer - delta)
		if _save_throttle_timer <= 0.0 and _save_pending:
			save_game(false)

	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		_save_throttle_timer = 0.0
		save_game(false)


func remove_save_files() -> void:
	for path: String in [SAVE_PATH, SAVE_BACKUP_PATH, SAVE_TEMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func wait_for_save_thread() -> void:
	if _save_thread != null and _save_thread.is_started():
		_save_thread.wait_to_finish()
	_save_thread = null
	_save_in_progress = false


func _write_save_data_to_disk(save_data: SaveData) -> bool:
	if save_data == null:
		return false
	var err: Error = ResourceSaver.save(save_data, SAVE_TEMP_PATH)
	if err != OK or not FileAccess.file_exists(SAVE_TEMP_PATH):
		return false
	var tmp_file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.READ)
	if tmp_file == null:
		return false
	var tmp_len: int = tmp_file.get_length()
	tmp_file.close()
	if tmp_len <= 0:
		return false

	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(SAVE_BACKUP_PATH):
			DirAccess.remove_absolute(SAVE_BACKUP_PATH)
		DirAccess.rename_absolute(SAVE_PATH, SAVE_BACKUP_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var rename_err: Error = DirAccess.rename_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	return rename_err == OK


func _save_worker_entry(save_data: SaveData) -> void:
	var ok: bool = _write_save_data_to_disk(save_data)
	call_deferred("_on_async_save_finished", ok)


func _on_async_save_finished(ok: bool) -> void:
	wait_for_save_thread()
	if ok and _gm != null:
		_gm.save_status_changed.emit("Прогресс сохранён")
	if _save_queued_after_worker:
		_save_queued_after_worker = false
		save_game(false)


func save_game(force_immediate: bool = false) -> void:
	if _gm == null:
		return
	if force_immediate:
		wait_for_save_thread()
		_save_pending = false
		_save_queued_after_worker = false
		_save_throttle_timer = SAVE_THROTTLE_INTERVAL
		var sync_data: SaveData = SaveSerializer.build_save_data(_gm)
		if _write_save_data_to_disk(sync_data):
			_gm.save_status_changed.emit("Прогресс сохранён")
		return

	if _save_throttle_timer > 0.0:
		_save_pending = true
		return
	if _save_in_progress:
		_save_queued_after_worker = true
		return

	_save_pending = false
	_save_throttle_timer = SAVE_THROTTLE_INTERVAL
	var async_data: SaveData = SaveSerializer.build_save_data(_gm)
	_save_thread = Thread.new()
	var start_err: Error = _save_thread.start(Callable(self, "_save_worker_entry").bind(async_data))
	if start_err == OK:
		_save_in_progress = true
	else:
		_save_thread = null
		if _write_save_data_to_disk(async_data):
			_gm.save_status_changed.emit("Прогресс сохранён")


func load_game() -> bool:
	if _gm == null:
		return false
	wait_for_save_thread()
	var save_data: SaveData = null
	var loaded_from_backup: bool = false
	for candidate_path: String in [SAVE_PATH, SAVE_BACKUP_PATH, SAVE_TEMP_PATH]:
		if not ResourceLoader.exists(candidate_path):
			continue
		var loaded: SaveData = ResourceLoader.load(candidate_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
		if loaded != null:
			save_data = loaded
			loaded_from_backup = candidate_path != SAVE_PATH
			break
	if save_data == null:
		return false

	SaveSerializer.apply_save_data(_gm, save_data)
	if loaded_from_backup:
		save_game(true)
	return true


func export_save_to_text() -> String:
	var save_data: SaveData = SaveSerializer.build_save_data(_gm)
	var payload: Dictionary = {
		"format": "HERO_TALE_SAVE_TXT",
		"save_version": SAVE_SCHEMA_VERSION,
		"exported_at": Time.get_datetime_string_from_system(),
		"summary": {
			"level": _gm.level,
			"difficulty": _gm.difficulty_level,
			"max_difficulty": _gm.max_unlocked_difficulty,
			"dark_points": _gm.dark_points,
			"dark_shop_coins": _gm.dark_shop_coins,
			"class_id": _gm.selected_class_id,
			"reflector_kill_hp_stacks": _gm.reflector_kill_hp_stacks,
		},
		"data": SaveDictCodec.save_data_to_dict(save_data),
	}
	return JSON.stringify(payload, "\t")


func export_save_to_txt_file(file_path: String) -> Dictionary:
	if file_path.is_empty():
		return {"success": false, "message": "Путь для сохранения не выбран."}
	var content: String = export_save_to_text()
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var err_code: Error = FileAccess.get_open_error()
		return {"success": false, "message": "Не удалось создать файл (код %d)." % err_code}
	file.store_string(content)
	file.flush()
	file.close()
	_gm.save_status_changed.emit("Экспортировано в .txt")
	return {"success": true, "message": "✅ Сохранение экспортировано: %s" % file_path}


func import_save_from_text(raw_text: String) -> Dictionary:
	wait_for_save_thread()
	var trimmed: String = raw_text.strip_edges()
	if trimmed.is_empty():
		return {"success": false, "message": "Файл или текст сохранения пуст."}
	var parsed: Variant = JSON.parse_string(trimmed)
	if not (parsed is Dictionary):
		return {"success": false, "message": "Неверный формат .txt сохранения (ожидался JSON)."}
	var root: Dictionary = parsed as Dictionary
	if str(root.get("format", "")) != "HERO_TALE_SAVE_TXT" or not (root.get("data") is Dictionary):
		return {"success": false, "message": "Этот .txt файл не является сохранением Hero Tale Idle RPG."}
	var data_dict: Dictionary = root["data"] as Dictionary
	var save_data: SaveData = SaveDictCodec.dict_to_save_data(data_dict, _gm.DEFAULT_AFK_MAX_FPS)
	SaveSerializer.apply_save_data(_gm, save_data)
	_gm.ensure_curses_for_difficulty(_gm.difficulty_level)
	_gm._invalidate_progression_caches()
	save_game(true)
	_gm.game_reset.emit()
	_gm._emit_all_refresh_signals()
	_gm.save_status_changed.emit("Импортировано из .txt")
	return {
		"success": true,
		"message": "✅ Прогресс загружен: Ур.%d | Сл.%d (макс. %d) | 🌑 %d" % [
			_gm.level,
			_gm.difficulty_level,
			_gm.max_unlocked_difficulty,
			_gm.dark_points,
		],
	}


func import_save_from_txt_file(file_path: String) -> Dictionary:
	if file_path.is_empty():
		return {"success": false, "message": "Файл для импорта не выбран."}
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var err_code: Error = FileAccess.get_open_error()
		return {"success": false, "message": "Не удалось прочитать файл (код %d)." % err_code}
	var content: String = file.get_as_text()
	file.close()
	return import_save_from_text(content)
