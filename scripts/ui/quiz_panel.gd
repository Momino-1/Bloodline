extends Control
## Multiple-choice knowledge check. Questions come from a JSON file; options are shuffled.

signal finished(correct: int, total: int)

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var _questions: Array = []
var _order: Array = []
var _right := -1
var _index := 0
var _correct := 0
var _answered := false
var _progress: Label
var _question: Label
var _buttons: Array = []
var _feedback: RichTextLabel
var _next: Button


func _ready() -> void:
	theme = UIKit.make_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	UIKit.dim_background(self, 0.7)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(UIKit.label("KNOWLEDGE CHECK", 14, UIKit.ACCENT))
	_progress = UIKit.label("", 16, UIKit.MUTED)
	col.add_child(_progress)
	_question = UIKit.label("", 24, UIKit.TEXT, true)
	_question.custom_minimum_size = Vector2(740, 0)
	col.add_child(_question)
	for i in 4:
		var b := UIKit.button("", Vector2(740, 50))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_on_answer.bind(i))
		col.add_child(b)
		_buttons.append(b)
	_feedback = RichTextLabel.new()
	_feedback.bbcode_enabled = true
	_feedback.fit_content = true
	_feedback.scroll_active = false
	_feedback.custom_minimum_size = Vector2(740, 0)
	col.add_child(_feedback)
	_next = UIKit.button("Next question")
	_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	_next.pressed.connect(_on_next)
	col.add_child(_next)


func start(path: String) -> void:
	var data = GameState.load_json(path)
	if not (data is Dictionary) or not data.has("questions"):
		push_error("Quiz file invalid: " + path)
		finished.emit(0, 0)
		return
	_questions = data["questions"]
	_index = 0
	_correct = 0
	visible = true
	_show_question()


func _show_question() -> void:
	var q: Dictionary = _questions[_index]
	_answered = false
	_progress.text = "Question %d of %d" % [_index + 1, _questions.size()]
	_question.text = q["question"]
	var opts: Array = q["options"]
	_order = range(opts.size())
	_order.shuffle()
	for i in _buttons.size():
		var b: Button = _buttons[i]
		b.visible = i < opts.size()
		if b.visible:
			b.text = "%s.  %s" % [char(65 + i), opts[_order[i]]]
			b.disabled = false
			b.modulate = Color.WHITE
			if int(_order[i]) == int(q["answer"]):
				_right = i
	_feedback.text = ""
	_next.visible = false
	_buttons[0].grab_focus()


func _on_answer(i: int) -> void:
	if _answered:
		return
	_answered = true
	var q: Dictionary = _questions[_index]
	var ok := i == _right
	if ok:
		_correct += 1
	for b in _buttons:
		b.disabled = true
		b.modulate = Color(1, 1, 1, 0.45)
	(_buttons[_right] as Button).modulate = Color(0.6, 1.0, 0.65)
	if not ok:
		(_buttons[i] as Button).modulate = Color(1.0, 0.55, 0.55)
	var head := "[b][color=#80e68c]Correct![/color][/b]" if ok else "[b][color=#ff7373]Not quite.[/color][/b] The correct answer is %s." % char(65 + _right)
	_feedback.text = "%s\n%s\n\n[b]Biology concept:[/b] %s" % [head, q["explanation"], q["concept"]]
	_next.text = "Next question" if _index < _questions.size() - 1 else "Finish"
	_next.visible = true
	_next.grab_focus()


func _on_next() -> void:
	_index += 1
	if _index >= _questions.size():
		visible = false
		finished.emit(_correct, _questions.size())
	else:
		_show_question()
