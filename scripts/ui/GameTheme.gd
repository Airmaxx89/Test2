extends Node
class_name GameTheme
## Central, code-driven visual design system for the whole UI: one warm,
## dark "medieval parchment & wood" palette, rounded panels/buttons and
## theme type-variations (HealthBar/ManaBar/XPBar/PrimaryButton/...) so every
## screen looks like one consistent, current UI instead of raw default
## Godot controls.

const BG_PANEL := Color(0.098, 0.086, 0.074, 0.95)
const BG_PANEL_LIGHT := Color(0.155, 0.132, 0.102, 0.97)
const ACCENT := Color(0.80, 0.64, 0.29)
const ACCENT_BRIGHT := Color(0.95, 0.82, 0.48)
const TEXT := Color(0.96, 0.94, 0.89)
const TEXT_MUTED := Color(0.70, 0.65, 0.57)
const BORDER := Color(0.38, 0.30, 0.17, 0.9)
const HP_COLOR := Color(0.80, 0.20, 0.20)
const MANA_COLOR := Color(0.30, 0.52, 0.88)
const XP_COLOR := Color(0.88, 0.72, 0.27)
const BUTTON_BG := Color(0.20, 0.17, 0.13, 0.95)
const BUTTON_HOVER := Color(0.29, 0.24, 0.16, 0.97)
const BUTTON_PRESSED := Color(0.36, 0.28, 0.15, 1.0)
const BUTTON_DISABLED := Color(0.15, 0.14, 0.13, 0.55)


static func _stylebox(bg: Color, radius: int, border_w: int = 0, border_color: Color = BORDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border_color
	s.set_border_width_all(border_w)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


static func panel_style(bg: Color = BG_PANEL, radius: int = 18) -> StyleBoxFlat:
	var s := _stylebox(bg, radius, 2)
	s.shadow_size = 14
	s.shadow_color = Color(0, 0, 0, 0.35)
	return s


static func button_style(bg: Color, radius: int = 14) -> StyleBoxFlat:
	return _stylebox(bg, radius, 1, ACCENT)


static func bar_bg_style(radius: int = 8) -> StyleBoxFlat:
	var s := _stylebox(Color(0.05, 0.045, 0.04, 0.85), radius, 1, BORDER)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s


static func bar_fill_style(color: Color, radius: int = 8) -> StyleBoxFlat:
	var s := _stylebox(color, radius)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s


static func circle_style(bg: Color, border_color: Color = ACCENT, border_w: int = 2) -> StyleBoxFlat:
	var s := _stylebox(bg, 999, border_w, border_color)
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	return s


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 24

	# Button
	theme.set_stylebox("normal", "Button", button_style(BUTTON_BG))
	theme.set_stylebox("hover", "Button", button_style(BUTTON_HOVER))
	theme.set_stylebox("pressed", "Button", button_style(BUTTON_PRESSED))
	theme.set_stylebox("disabled", "Button", button_style(BUTTON_DISABLED))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", ACCENT_BRIGHT)
	theme.set_color("font_pressed_color", "Button", ACCENT_BRIGHT)
	theme.set_color("font_disabled_color", "Button", TEXT_MUTED)
	theme.set_font_size("font_size", "Button", 22)

	# Primary call-to-action button (bigger, brighter border)
	theme.set_type_variation("PrimaryButton", "Button")
	var primary_normal := button_style(Color(0.30, 0.24, 0.13, 0.97), 16)
	primary_normal.border_color = ACCENT_BRIGHT
	primary_normal.set_border_width_all(2)
	theme.set_stylebox("normal", "PrimaryButton", primary_normal)
	var primary_hover := button_style(Color(0.38, 0.30, 0.15, 0.98), 16)
	primary_hover.border_color = ACCENT_BRIGHT
	primary_hover.set_border_width_all(2)
	theme.set_stylebox("hover", "PrimaryButton", primary_hover)
	theme.set_stylebox("pressed", "PrimaryButton", button_style(BUTTON_PRESSED, 16))
	theme.set_stylebox("disabled", "PrimaryButton", button_style(BUTTON_DISABLED, 16))
	theme.set_color("font_color", "PrimaryButton", ACCENT_BRIGHT)
	theme.set_color("font_hover_color", "PrimaryButton", Color(1, 0.95, 0.8))
	theme.set_font_size("font_size", "PrimaryButton", 26)

	# Round touch-action buttons (attack/jump/abilities)
	theme.set_type_variation("ActionButton", "Button")
	theme.set_stylebox("normal", "ActionButton", circle_style(Color(0.16, 0.14, 0.11, 0.75)))
	theme.set_stylebox("hover", "ActionButton", circle_style(Color(0.24, 0.20, 0.14, 0.85)))
	theme.set_stylebox("pressed", "ActionButton", circle_style(BUTTON_PRESSED, ACCENT_BRIGHT, 3))
	theme.set_stylebox("disabled", "ActionButton", circle_style(Color(0.1, 0.09, 0.08, 0.4), BORDER, 1))
	theme.set_color("font_color", "ActionButton", TEXT)
	theme.set_font_size("font_size", "ActionButton", 20)

	# Panel
	theme.set_stylebox("panel", "Panel", panel_style())

	# Label
	theme.set_color("font_color", "Label", TEXT)
	theme.set_font_size("font_size", "Label", 22)

	# ProgressBar (default) + variations
	theme.set_stylebox("background", "ProgressBar", bar_bg_style())
	theme.set_stylebox("fill", "ProgressBar", bar_fill_style(ACCENT))

	theme.set_type_variation("HealthBar", "ProgressBar")
	theme.set_stylebox("background", "HealthBar", bar_bg_style())
	theme.set_stylebox("fill", "HealthBar", bar_fill_style(HP_COLOR))

	theme.set_type_variation("ManaBar", "ProgressBar")
	theme.set_stylebox("background", "ManaBar", bar_bg_style(6))
	theme.set_stylebox("fill", "ManaBar", bar_fill_style(MANA_COLOR, 6))

	theme.set_type_variation("XPBar", "ProgressBar")
	theme.set_stylebox("background", "XPBar", bar_bg_style(5))
	theme.set_stylebox("fill", "XPBar", bar_fill_style(XP_COLOR, 5))

	# ScrollContainer should stay fully transparent (panel already draws bg)
	theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	return theme


## A soft vertical gradient background texture (dark parchment green->brown)
## used behind full-screen menus - no external image assets needed.
static func background_texture(top: Color, bottom: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 4
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	return tex
