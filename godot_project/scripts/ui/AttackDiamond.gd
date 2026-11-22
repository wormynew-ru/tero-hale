extends Control

@export var fill_color: Color = Color(0.24, 0.66, 0.96, 0.95)
@export var ready_color: Color = Color(0.98, 0.82, 0.3, 1.0)
@export var bg_color: Color = Color(0.09, 0.11, 0.14, 0.92)
@export var border_color: Color = Color(0.84, 0.8, 0.72, 0.95)

var progress: float = 0.0
var _bg_pts: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _tri_pts: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _pent_pts: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _border_pts: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])


func set_progress(value: float) -> void:
	var clamped: float = clampf(value, 0.0, 1.0)
	if is_equal_approx(progress, clamped):
		return
	progress = clamped
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.44
	if radius <= 2.0:
		return

	var top: Vector2 = Vector2(center.x, center.y - radius)
	var right: Vector2 = Vector2(center.x + radius, center.y)
	var bottom: Vector2 = Vector2(center.x, center.y + radius)
	var left: Vector2 = Vector2(center.x - radius, center.y)

	_bg_pts[0] = top
	_bg_pts[1] = right
	_bg_pts[2] = bottom
	_bg_pts[3] = left
	draw_colored_polygon(_bg_pts, bg_color)

	if progress > 0.001:
		var active_color: Color = ready_color if progress >= 0.98 else fill_color
		var y_cut: float = lerpf(bottom.y, top.y, progress)
		if progress < 0.5:
			var half_w: float = radius * (progress / 0.5)
			_tri_pts[0] = bottom
			_tri_pts[1] = Vector2(center.x - half_w, y_cut)
			_tri_pts[2] = Vector2(center.x + half_w, y_cut)
			draw_colored_polygon(_tri_pts, active_color)
		elif progress < 1.0:
			var half_w: float = radius * ((1.0 - progress) / 0.5)
			_pent_pts[0] = bottom
			_pent_pts[1] = left
			_pent_pts[2] = Vector2(center.x - half_w, y_cut)
			_pent_pts[3] = Vector2(center.x + half_w, y_cut)
			_pent_pts[4] = right
			draw_colored_polygon(_pent_pts, active_color)
		else:
			draw_colored_polygon(_bg_pts, active_color)

	_border_pts[0] = top
	_border_pts[1] = right
	_border_pts[2] = bottom
	_border_pts[3] = left
	_border_pts[4] = top
	draw_polyline(_border_pts, border_color, 2.0, true)
