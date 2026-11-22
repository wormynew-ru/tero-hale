extends Control

const CELL_SIZE: Vector2 = Vector2(174.0, 108.0)
const NODE_SIZE: Vector2 = Vector2(150.0, 66.0)
const GRAPH_PADDING: Vector2 = Vector2(24.0, 24.0)

@onready var available_sp_label: Label = %AvailableSPLabel
@onready var graph_scroll: ScrollContainer = $RootVBox/GraphScroll
@onready var graph_canvas: Control = %GraphCanvas
@onready var lines_layer: Control = %LinesLayer
@onready var nodes_layer: Control = %NodesLayer

@onready var selected_title_label: Label = %SelectedTitleLabel
@onready var selected_status_label: Label = %SelectedStatusLabel
@onready var selected_bonus_label: Label = %SelectedBonusLabel
@onready var selected_desc_label: Label = %SelectedDescLabel
@onready var learn_button: Button = %LearnButton

var _selected_skill_id: String = ""
var _node_buttons: Dictionary = {}
var _root_center: Vector2 = Vector2.ZERO


func _ready() -> void:
	GameManager.skills_changed.connect(_refresh_tree)
	GameManager.difficulty_changed.connect(_refresh_tree)
	GameManager.stats_changed.connect(_refresh_header_and_details)
	learn_button.pressed.connect(_on_learn_pressed)

	if not GameManager.skill_nodes.is_empty():
		_selected_skill_id = GameManager.skill_nodes[0].id

	_rebuild_graph()
	_refresh_header_and_details()
	call_deferred("_center_on_root")


func _rebuild_graph() -> void:
	for child: Node in lines_layer.get_children():
		child.queue_free()
	for child: Node in nodes_layer.get_children():
		child.queue_free()
	_node_buttons.clear()

	var max_extent: Vector2 = Vector2(540.0, 340.0)
	var centers_by_id: Dictionary = {}

	for skill: SkillNodeData in GameManager.skill_nodes:
		var pos: Vector2 = GRAPH_PADDING + skill.grid_position * CELL_SIZE
		var center: Vector2 = pos + NODE_SIZE * 0.5
		centers_by_id[skill.id] = center
		if skill.id == "hero_foundation" or skill.prerequisites.is_empty():
			_root_center = center
		max_extent.x = maxf(max_extent.x, pos.x + NODE_SIZE.x + GRAPH_PADDING.x)
		max_extent.y = maxf(max_extent.y, pos.y + NODE_SIZE.y + GRAPH_PADDING.y)

	graph_canvas.custom_minimum_size = max_extent

	for skill: SkillNodeData in GameManager.skill_nodes:
		if not centers_by_id.has(skill.id):
			continue
		var child_center: Vector2 = centers_by_id[skill.id] as Vector2
		for prereq_id: String in skill.prerequisites:
			if not centers_by_id.has(prereq_id):
				continue
			var parent_center: Vector2 = centers_by_id[prereq_id] as Vector2
			var line: Line2D = Line2D.new()
			line.width = 4.0
			line.antialiased = true
			line.points = PackedVector2Array([parent_center, child_center])
			line.default_color = _get_connection_color(prereq_id, skill.id)
			lines_layer.add_child(line)

	for skill: SkillNodeData in GameManager.skill_nodes:
		var btn: Button = Button.new()
		btn.position = GRAPH_PADDING + skill.grid_position * CELL_SIZE
		btn.size = NODE_SIZE
		btn.custom_minimum_size = NODE_SIZE
		btn.clip_text = false
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var lock_prefix: String = "🔒 " if (skill.requires_alchemy and not GameManager.is_alchemy_unlocked()) else ""
		btn.text = "%s%s %s\n(%d ОН)" % [lock_prefix, skill.icon_emoji, skill.title, skill.cost_skill_points]
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func() -> void: _select_skill(skill.id))
		_apply_node_style(btn, skill.id)
		nodes_layer.add_child(btn)
		_node_buttons[skill.id] = btn


func _center_on_root() -> void:
	if graph_scroll == null or _root_center == Vector2.ZERO:
		return
	var view_size: Vector2 = graph_scroll.size
	graph_scroll.scroll_horizontal = maxi(0, roundi(_root_center.x - view_size.x * 0.5))
	graph_scroll.scroll_vertical = maxi(0, roundi(_root_center.y - view_size.y * 0.5))


func _refresh_tree() -> void:
	_rebuild_graph()
	_refresh_header_and_details()


func _refresh_header_and_details() -> void:
	available_sp_label.text = "Доступно очков: %d" % GameManager.skill_points

	for skill_id: String in _node_buttons.keys():
		var btn: Button = _node_buttons[skill_id] as Button
		if btn != null:
			_apply_node_style(btn, skill_id)

	var skill: SkillNodeData = GameManager.get_skill_by_id(_selected_skill_id)
	if skill == null:
		selected_title_label.text = "Выберите навык"
		selected_status_label.text = ""
		selected_bonus_label.text = ""
		selected_desc_label.text = "Нажмите на любой узел на графе, чтобы увидеть характеристики и стоимость изучения."
		learn_button.disabled = true
		learn_button.text = "Изучить"
		return

	selected_title_label.text = "%s %s" % [skill.icon_emoji, skill.title]
	selected_bonus_label.text = "Бонус: %s" % skill.get_bonus_summary()
	selected_desc_label.text = skill.description

	var is_unlocked: bool = GameManager.is_skill_unlocked(skill.id)
	var diff_locked: bool = skill.requires_alchemy and not GameManager.is_alchemy_unlocked()
	var prereqs_met: bool = GameManager.are_prerequisites_met(skill.id)
	var can_learn: bool = GameManager.can_unlock_skill(skill.id)

	if is_unlocked:
		selected_status_label.text = "Статус: Изучено"
		selected_status_label.modulate = Color(0.35, 0.9, 0.55, 1.0)
		learn_button.disabled = true
		learn_button.text = "Изучено"
	elif diff_locked:
		selected_status_label.text = "Статус: 🔒 Требуется Сл.%d (Убежище: Сад и Зелья)" % GameManager.ALCHEMY_UNLOCK_DIFFICULTY
		selected_status_label.modulate = Color(0.95, 0.58, 0.42, 1.0)
		learn_button.disabled = true
		learn_button.text = "🔒 Сл.%d" % GameManager.ALCHEMY_UNLOCK_DIFFICULTY
	elif can_learn:
		selected_status_label.text = "Статус: Доступно (%d очк.)" % skill.cost_skill_points
		selected_status_label.modulate = Color(0.38, 0.78, 0.98, 1.0)
		learn_button.disabled = false
		learn_button.text = "Изучить (%d ОН)" % skill.cost_skill_points
	elif not prereqs_met:
		var missing_names: Array[String] = []
		for req_id: String in skill.prerequisites:
			if not GameManager.is_skill_unlocked(req_id):
				var req_skill: SkillNodeData = GameManager.get_skill_by_id(req_id)
				missing_names.append(req_skill.title if req_skill != null else req_id)
		selected_status_label.text = "Требуется: %s" % ", ".join(missing_names)
		selected_status_label.modulate = Color(0.65, 0.7, 0.78, 1.0)
		learn_button.disabled = true
		learn_button.text = "Закрыто"
	else:
		selected_status_label.text = "Недостаточно очков навыков (нужно %d)" % skill.cost_skill_points
		selected_status_label.modulate = Color(0.95, 0.75, 0.35, 1.0)
		learn_button.disabled = true
		learn_button.text = "Нужно %d ОН" % skill.cost_skill_points


func _select_skill(skill_id: String) -> void:
	_selected_skill_id = skill_id
	_refresh_header_and_details()


func _on_learn_pressed() -> void:
	if _selected_skill_id.is_empty():
		return
	GameManager.unlock_skill(_selected_skill_id)


func _get_connection_color(parent_id: String, child_id: String) -> Color:
	if GameManager.is_skill_unlocked(parent_id) and GameManager.is_skill_unlocked(child_id):
		return Color(0.29, 0.87, 0.50, 0.95)
	if GameManager.is_skill_unlocked(parent_id):
		return Color(0.22, 0.74, 0.97, 0.85)
	return Color(0.28, 0.33, 0.41, 0.75)


func _apply_node_style(btn: Button, skill_id: String) -> void:
	var skill: SkillNodeData = GameManager.get_skill_by_id(skill_id)
	var is_unlocked: bool = GameManager.is_skill_unlocked(skill_id)
	var diff_locked: bool = skill != null and skill.requires_alchemy and not GameManager.is_alchemy_unlocked()
	var is_available: bool = GameManager.can_unlock_skill(skill_id)
	var prereqs_met: bool = GameManager.are_prerequisites_met(skill_id)
	var is_selected: bool = skill_id == _selected_skill_id

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 3 if is_selected else 2
	style.border_width_top = 3 if is_selected else 2
	style.border_width_right = 3 if is_selected else 2
	style.border_width_bottom = 3 if is_selected else 2

	if is_unlocked:
		style.bg_color = Color(0.08, 0.32, 0.18, 1.0)
		style.border_color = Color(0.45, 0.96, 0.62, 1.0) if is_selected else Color(0.29, 0.87, 0.50, 1.0)
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif diff_locked:
		style.bg_color = Color(0.14, 0.11, 0.13, 1.0)
		style.border_color = Color(0.85, 0.48, 0.42, 1.0) if is_selected else Color(0.48, 0.28, 0.28, 1.0)
		btn.modulate = Color(0.68, 0.68, 0.72, 1.0)
	elif is_available:
		style.bg_color = Color(0.07, 0.26, 0.42, 1.0)
		style.border_color = Color(0.98, 0.82, 0.32, 1.0) if is_selected else Color(0.22, 0.74, 0.97, 1.0)
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif prereqs_met:
		style.bg_color = Color(0.14, 0.19, 0.27, 1.0)
		style.border_color = Color(0.95, 0.75, 0.35, 1.0) if is_selected else Color(0.45, 0.55, 0.68, 1.0)
		btn.modulate = Color(0.92, 0.92, 0.95, 1.0)
	else:
		style.bg_color = Color(0.11, 0.13, 0.18, 1.0)
		style.border_color = Color(0.65, 0.72, 0.82, 1.0) if is_selected else Color(0.28, 0.33, 0.41, 1.0)
		btn.modulate = Color(0.75, 0.78, 0.85, 1.0)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
