extends RefCounted
## Shared look & feel: a dark, clinical "scientific simulation" theme.

const TEXT := Color(0.93, 0.90, 0.92)
const MUTED := Color(0.70, 0.64, 0.68)
const ACCENT := Color(0.50, 0.85, 1.0)
const GOOD := Color(0.50, 0.90, 0.58)
const BAD := Color(1.0, 0.45, 0.45)


static func panel_style(bg := Color(0.07, 0.025, 0.045, 0.94), border := Color(0.62, 0.12, 0.18, 0.9)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.set_content_margin_all(22)
	return s


static func button_style(bg: Color, border := Color(0.55, 0.12, 0.18, 0.9)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	return s


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("normal", "Button", button_style(Color(0.15, 0.05, 0.08, 0.95)))
	t.set_stylebox("hover", "Button", button_style(Color(0.30, 0.08, 0.13, 0.98), ACCENT))
	t.set_stylebox("pressed", "Button", button_style(Color(0.42, 0.10, 0.16), ACCENT))
	t.set_stylebox("disabled", "Button", button_style(Color(0.10, 0.06, 0.07, 0.85), Color(0.3, 0.2, 0.22)))
	t.set_stylebox("focus", "Button", button_style(Color(0.2, 0.06, 0.1, 0.0), ACCENT))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.45, 0.47))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 18)
	t.set_font_size("bold_font_size", "RichTextLabel", 18)
	var lp := panel_style(Color(0.05, 0.02, 0.03, 0.9), Color(0.35, 0.1, 0.14))
	lp.set_content_margin_all(6)
	t.set_stylebox("panel", "ItemList", lp)
	var sel := StyleBoxFlat.new()
	sel.bg_color = Color(0.35, 0.09, 0.14)
	sel.set_corner_radius_all(4)
	t.set_stylebox("selected", "ItemList", sel)
	t.set_stylebox("selected_focus", "ItemList", sel)
	t.set_color("font_color", "ItemList", TEXT)
	t.set_color("font_selected_color", "ItemList", Color.WHITE)
	return t


static func label(text: String, size := 18, color := TEXT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, min_size := Vector2(200, 44)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	return b


static func dim_background(parent: Control, alpha := 0.6) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
