extends Window

signal events_updated()

@export var event_scene: PackedScene
@export var event_dialog_scene: PackedScene

@onready var event_box: VBoxContainer = %"Event Box"
@onready var note_edit: TextEdit = %"Note Edit"
@onready var milestone_title_edit: LineEdit = %"Milestone Title"
@onready var milestone_desc_edit: TextEdit = %"Milestone Description"
@onready var bookmark_button: Button = %"Bookmark Button"
@onready var color_picker: ColorPickerButton = %"Custom Color"
@onready var reset_color_button: Button = %ResetColor
@onready var clear_day_button: Button = %ResetDay

var day_index: int = 0
var calendar: Calendar
var events: Array = []

func _ready():
	if note_edit:
		note_edit.text_changed.connect(_on_note_changed)
	
	if milestone_title_edit:
		milestone_title_edit.text_changed.connect(_on_milestone_changed)
	
	if milestone_desc_edit:
		milestone_desc_edit.text_changed.connect(_on_milestone_changed)
	
	if color_picker:
		color_picker.color_changed.connect(_on_color_changed)
	
	if reset_color_button:
		reset_color_button.pressed.connect(_on_reset_color_pressed)
	
	if clear_day_button:
		clear_day_button.pressed.connect(_on_clear_day_pressed)
	
	%AddEventButton.pressed.connect(_on_add_event)

func setup(p_day_index: int, p_calendar: Calendar):
	day_index = p_day_index
	calendar = p_calendar
	
	# Mettre à jour le titre
	var day_start_unix = calendar.get_day_start_unix(day_index)
	var d = Time.get_datetime_dict_from_unix_time(day_start_unix)
	title = "Day %d - %s %s %d" % [
		day_index + 1,
		calendar.DAY_NAMES[d.weekday],
		calendar.MONTH_NAMES[d.month - 1],
		d.day
	]
	
	refresh()

func refresh():
	events = calendar.get_events_for_day(day_index)
	make_events()
	
	if note_edit:
		note_edit.text = calendar.get_daily_note(day_index)
	
	var milestone = _get_milestone_for_day()
	if milestone:
		if milestone_title_edit:
			milestone_title_edit.text = milestone.title
		if milestone_desc_edit:
			milestone_desc_edit.text = milestone.description
	else:
		if milestone_title_edit:
			milestone_title_edit.text = ""
		if milestone_desc_edit:
			milestone_desc_edit.text = ""
	
	if color_picker:
		if color_picker.color_changed.is_connected(_on_color_changed):
			color_picker.color_changed.disconnect(_on_color_changed)
		
		if calendar.has_custom_color(day_index):
			color_picker.color = calendar.get_day_custom_color(day_index)
		else:
			var cell_color = _get_default_cell_color()
			color_picker.color = cell_color
		
		color_picker.color_changed.connect(_on_color_changed)
	
	update_bookmark_button()
	update_clear_button()

func update_clear_button():
	if not clear_day_button:
		return
	
	var has_data = (
		events.size() > 0 or
		calendar.has_daily_note(day_index) or
		_get_milestone_for_day() != null or
		calendar.is_bookmarked(day_index) or
		calendar.has_custom_color(day_index)
	)
	
	clear_day_button.disabled = not has_data

func _get_default_cell_color() -> Color:
	var state = calendar.get_day_state(day_index)
	var has_events = calendar.get_events_for_day(day_index).size() > 0
	var is_bookmarked = calendar.is_bookmarked(day_index)
	var milestone = _get_milestone_for_day()
	
	if state == -1:
		if milestone:
			return Color(1.0, 0.5, 0.8)
		elif is_bookmarked:
			return Color(1.0, 0.9, 0.3)
		elif has_events:
			return Color(0.9, 0.7, 1.0)
		else:
			return Color(0.8, 0.8, 0.8)
	elif state == 0:  # Aujourd'hui
		if milestone:
			return Color(1.0, 0.3, 0.5)
		elif is_bookmarked:
			return Color(1.0, 0.8, 0.0)
		elif has_events:
			return Color(1.0, 0.8, 0.4)
		else:
			return Color(1.0, 1.0, 0.6)
	else:  # Passé
		if milestone and milestone.completed:
			return Color(0.3, 0.9, 0.5)
		elif milestone:
			return Color(0.9, 0.3, 0.3)
		elif is_bookmarked:
			return Color(0.5, 0.8, 1.0)
		elif has_events:
			return Color(0.4, 0.8, 1.0)
		else:
			return Color(0.6, 1.0, 0.6)

func update_bookmark_button():
	if not bookmark_button:
		return
	
	if calendar.is_bookmarked(day_index):
		bookmark_button.text = "⁕ Bookmarked"
		bookmark_button.modulate = Color(1.0, 0.9, 0.3)
	else:
		bookmark_button.text = " ⁕ Bookmark"
		bookmark_button.modulate = Color(1.0, 1.0, 1.0)

func _on_bookmark_pressed():
	if calendar.is_bookmarked(day_index):
		calendar.remove_bookmark(day_index)
	else:
		calendar.add_bookmark(day_index)
	
	calendar.save_calendar()
	update_bookmark_button()
	events_updated.emit()

func _on_color_changed(color: Color):
	calendar.set_day_custom_color(day_index, color)
	events_updated.emit()

func _on_reset_color_pressed():
	calendar.day_custom_colors.erase(day_index)
	calendar.save_calendar()
	
	if color_picker:
		if color_picker.color_changed.is_connected(_on_color_changed):
			color_picker.color_changed.disconnect(_on_color_changed)
		
		color_picker.color = Color(0.0, 0.0, 0.0, 0.0)
		
		color_picker.color_changed.connect(_on_color_changed)
	
	if reset_color_button:
		reset_color_button.disabled = true
	
	update_clear_button()
	events_updated.emit()

func _on_clear_day_pressed():
	var confirm = ConfirmationDialog.new()
	get_tree().root.add_child(confirm)
	confirm.dialog_text = "Clear ALL data for Day %d?\n\nThis will remove:\n• All events\n• Note\n• Milestone\n• Bookmark\n• Custom color" % (day_index + 1)
	confirm.ok_button_text = "Clear All"
	confirm.cancel_button_text = "Cancel"
	confirm.popup_centered()
	
	confirm.confirmed.connect(func():
		_clear_day_data()
		confirm.queue_free()
	)
	
	confirm.canceled.connect(func():
		confirm.queue_free()
	)

func _clear_day_data():
	var events_to_remove = calendar.get_events_for_day(day_index).duplicate()
	for event in events_to_remove:
		calendar.remove_event(event)
	
	calendar.set_daily_note(day_index, "")
	
	var milestone = _get_milestone_for_day()
	if milestone:
		calendar.milestones.erase(milestone)
	
	if calendar.is_bookmarked(day_index):
		calendar.remove_bookmark(day_index)
	
	calendar.day_custom_colors.erase(day_index)
	
	calendar.save_calendar()
	refresh()
	events_updated.emit()
	
	print("Day %d cleared successfully!" % (day_index + 1))

func make_events():
	for child in event_box.get_children():
		child.queue_free()
	
	if events.size() > 0:
		for i in range(events.size()):
			var e = events[i]
			var check = "X" if e.completed else "O"
			var icon = _get_category_icon(e.category)
			var scene = event_scene.instantiate()
			
			var text = "%s %s %s →" % [check, icon, e.title]
			
			scene.update(text, i)
			event_box.add_child(scene)
			scene.connect("clicked", event_clicked)

func _get_milestone_for_day() -> Calendar.Milestone:
	for m in calendar.milestones:
		if m.day_index == day_index:
			return m
	return null

func event_clicked(event_index: int):
	if event_index < 0 or event_index >= events.size():
		return
	
	var event = events[event_index]
	_edit_event(event)

func _edit_event(event: Calendar.CalendarEvent):
	if not event_dialog_scene:
		push_error("Event dialog scene not assigned!")
		return
	
	var dialog = event_dialog_scene.instantiate()
	get_tree().root.add_child(dialog)
	dialog.setup_edit(event)
	dialog.popup_centered()
	
	dialog.event_updated.connect(func(updated_event):
		save_and_refresh()
	)
	
	dialog.event_deleted.connect(func(deleted_event):
		calendar.remove_event(deleted_event)
		save_and_refresh()
	)

func _on_add_event():
	if not event_dialog_scene:
		push_error("Event dialog scene not assigned!")
		return
	
	var dialog = event_dialog_scene.instantiate()
	get_tree().root.add_child(dialog)
	dialog.setup(day_index)
	dialog.popup_centered()
	
	dialog.event_created.connect(func(title_, day, hour, minute, category):
		calendar.add_event(title_, day, hour, minute, category)
		save_and_refresh()
	)

func _on_note_changed():
	var note_text = note_edit.text.strip_edges()
	calendar.set_daily_note(day_index, note_text)
	events_updated.emit()

func _on_milestone_changed(new_text: String = ""):
	var title_ = milestone_title_edit.text.strip_edges()
	var desc = milestone_desc_edit.text.strip_edges()
	
	var existing_milestone = _get_milestone_for_day()
	
	if title_.is_empty():
		if existing_milestone:
			calendar.milestones.erase(existing_milestone)
			calendar.save_calendar()
	else:
		if existing_milestone:
			existing_milestone.title = title_
			existing_milestone.description = desc
		else:
			calendar.add_milestone(title_, day_index, desc)
		calendar.save_calendar()
	
	events_updated.emit()

func save_and_refresh():
	calendar.save_calendar()
	refresh()
	events_updated.emit()

func _get_category_icon(cat: String) -> String:
	match cat:
		"story": return "|📖"
		"quest": return "|⚔️"
		"deadline": return "|⏰"
		"reminder": return "|🔔"
		"meeting": return "|👥"
		_: return "|"

func _on_cancel_pressed():
	queue_free()

func _on_close_requested() -> void:
	_on_cancel_pressed()
