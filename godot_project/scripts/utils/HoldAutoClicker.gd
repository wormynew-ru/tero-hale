class_name HoldAutoClicker
extends Node

## Обеспечивает автоклик с частотой 50 раз/сек при зажатии кнопки на ПК и телефоне.

const DEFAULT_CLICKS_PER_SECOND: float = 50.0
const DEFAULT_INITIAL_DELAY: float = 0.25
const MAX_CLICKS_PER_FRAME: int = 4

var clicks_per_second: float = DEFAULT_CLICKS_PER_SECOND
var initial_delay: float = DEFAULT_INITIAL_DELAY
var guard_callable: Callable = Callable()

var _button: BaseButton = null
var _holding: bool = false
var _hold_elapsed: float = 0.0
var _repeat_started: bool = false
var _repeat_accum: float = 0.0
var _orig_action_mode: BaseButton.ActionMode = BaseButton.ACTION_MODE_BUTTON_RELEASE
var _modified_action_mode: bool = false


static func attach(
	button: BaseButton,
	cps: float = DEFAULT_CLICKS_PER_SECOND,
	delay: float = DEFAULT_INITIAL_DELAY,
	guard: Callable = Callable()
) -> HoldAutoClicker:
	if button == null:
		return null
	var helper: HoldAutoClicker = HoldAutoClicker.new()
	helper.clicks_per_second = maxf(1.0, cps)
	helper.initial_delay = maxf(0.05, delay)
	helper.guard_callable = guard
	button.add_child(helper)
	helper._bind(button)
	return helper


func _bind(button: BaseButton) -> void:
	_button = button
	process_mode = Node.PROCESS_MODE_ALWAYS
	_orig_action_mode = button.action_mode
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	button.mouse_exited.connect(_on_focus_lost)
	button.visibility_changed.connect(_on_visibility_changed)


func _on_button_down() -> void:
	if _button == null or _button.disabled:
		_stop()
		return
	if not _modified_action_mode:
		_orig_action_mode = _button.action_mode
	_holding = true
	_hold_elapsed = 0.0
	_repeat_started = false
	_repeat_accum = 0.0


func _on_button_up() -> void:
	_stop()
	if _modified_action_mode and _button != null and is_instance_valid(_button):
		call_deferred("_restore_action_mode")


func _on_focus_lost() -> void:
	if _holding and _button != null and is_instance_valid(_button) and not _button.button_pressed:
		_stop()
		if _modified_action_mode:
			call_deferred("_restore_action_mode")


func _on_visibility_changed() -> void:
	if _button == null or not is_instance_valid(_button) or not _button.is_visible_in_tree():
		_stop()
		if _modified_action_mode and _button != null and is_instance_valid(_button):
			_restore_action_mode()


func _restore_action_mode() -> void:
	_modified_action_mode = false
	if _button != null and is_instance_valid(_button):
		_button.action_mode = _orig_action_mode


func _stop() -> void:
	_holding = false
	_hold_elapsed = 0.0
	_repeat_started = false
	_repeat_accum = 0.0


func _can_continue() -> bool:
	if _button == null or not is_instance_valid(_button):
		return false
	if _button.disabled or not _button.is_visible_in_tree() or not _button.button_pressed:
		return false
	if guard_callable.is_valid() and not bool(guard_callable.call()):
		return false
	return true


func _fire_click() -> void:
	if _button != null and is_instance_valid(_button) and not _button.disabled:
		_button.pressed.emit()


func _process(delta: float) -> void:
	if not _holding:
		return
	if not _can_continue():
		_stop()
		if _modified_action_mode:
			call_deferred("_restore_action_mode")
		return

	_hold_elapsed += delta
	if not _repeat_started:
		if _hold_elapsed >= initial_delay:
			_repeat_started = true
			_repeat_accum = 0.0
			if not _modified_action_mode:
				_orig_action_mode = _button.action_mode
				_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
				_modified_action_mode = true
			_fire_click()
		return

	var interval: float = 1.0 / maxf(1.0, clicks_per_second)
	_repeat_accum = minf(_repeat_accum + delta, interval * float(MAX_CLICKS_PER_FRAME))
	var clicks_done: int = 0
	while _repeat_accum >= interval and clicks_done < MAX_CLICKS_PER_FRAME:
		if not _can_continue():
			_stop()
			if _modified_action_mode:
				call_deferred("_restore_action_mode")
			return
		_repeat_accum -= interval
		clicks_done += 1
		_fire_click()
