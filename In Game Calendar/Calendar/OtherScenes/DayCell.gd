extends Control
class_name DayCell

@export var day_index: int = 0
@export var calendar: Calendar

@export var event_dialog_scene: PackedScene
@export var milestone_dialog_scene: PackedScene
@export var note_dialog_scene: PackedScene
@export var day_manager_scene: PackedScene

@onready var day_count: Label = %"Day Count"
@onready var day_num: Label = %"Day Num"
@onready var day_text: Label = %"Day Text"
@onready var progress: ProgressBar = %ProgressBar

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_children_ignore()

func _set_children_ignore():
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for subchild in child.get_children():
				if subchild is Control:
					subchild.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not calendar:
		return
	
	if not _is_mouse_over():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			return
		
		if event.pressed:
			get_viewport().set_input_as_handled()
			
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_show_menu()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if event.double_click:
					_open_day_manager()

func _open_day_manager():
	var manager = day_manager_scene.instantiate()
	get_tree().root.add_child(manager)
	manager.setup(day_index, calendar)
	manager.popup_centered()
	
	manager.events_updated.connect(func():
		update_cell()
	)


func _is_mouse_over() -> bool:
	var mouse_pos = get_global_mouse_position()
	var rect = get_global_rect()
	return rect.has_point(mouse_pos)

func _show_menu():
	var menu = PopupMenu.new()
	get_tree().root.add_child(menu)
	
	menu.add_item("➕ Add Event", 0)
	menu.add_item("🏆 Add Milestone", 1)
	menu.add_separator()
	
	var events = calendar.get_events_for_day(day_index)
	if events.size() > 0:
		menu.add_item("✓ Toggle Complete", 2)
		menu.add_separator()
	
	if calendar.is_bookmarked(day_index):
		menu.add_item("⭐ Remove Bookmark", 3)
	else:
		menu.add_item("⭐ Add Bookmark", 3)
	
	if calendar.has_daily_note(day_index):
		menu.add_item("📝 Edit Note", 4)
		menu.add_item("🗑️ Delete Note", 5)
	else:
		menu.add_item("📝 Add Note", 4)
	
	menu.position = get_global_mouse_position()
	menu.popup()
	
	menu.id_pressed.connect(func(id):
		match id:
			0: _add_event()
			1: _add_milestone()
			2: _toggle_complete()
			3:
				if calendar.is_bookmarked(day_index):
					calendar.remove_bookmark(day_index)
				else:
					calendar.add_bookmark(day_index)
				calendar.save_calendar()
				update_cell()
			4: _add_note()
			5:
				calendar.set_daily_note(day_index, "")
				calendar.save_calendar()
				update_cell()
		menu.queue_free()
	)
	
	menu.close_requested.connect(func(): menu.queue_free())


func _add_event():
	if not event_dialog_scene:
		push_error("Event dialog scene not assigned!")
		return
	
	var dialog = event_dialog_scene.instantiate()
	get_tree().root.add_child(dialog)
	dialog.setup(day_index)
	dialog.popup_centered()
	
	dialog.event_created.connect(func(title, day, hour, minute, category):
		var event = calendar.add_event(title, day, hour, minute, category)
		calendar.save_calendar()
		update_cell()
	)

func _add_milestone():
	if not milestone_dialog_scene:
		push_error("Milestone dialog scene not assigned!")
		return
	
	var dialog = milestone_dialog_scene.instantiate()
	get_tree().root.add_child(dialog)
	dialog.setup(day_index)
	dialog.popup_centered()
	
	dialog.milestone_created.connect(func(title, day, description):
		var milestone = calendar.add_milestone(title, day, description)
		calendar.save_calendar()
		update_cell()
	)

func _add_note():
	if not note_dialog_scene:
		push_error("Note dialog scene not assigned!")
		return
	
	var dialog = note_dialog_scene.instantiate()
	get_tree().root.add_child(dialog)
	var existing_note = calendar.get_daily_note(day_index)
	dialog.setup(day_index, existing_note)
	dialog.popup_centered()
	
	dialog.note_saved.connect(func(day, note):
		calendar.set_daily_note(day, note)
		update_cell()
	)

func _toggle_complete():
	var events = calendar.get_events_for_day(day_index)
	if events.size() > 0:
		events[0].completed = not events[0].completed
		calendar.save_calendar()
		update_cell()

func update_cell():
	if not calendar:
		return
	
	var state = calendar.get_day_state(day_index)
	var has_custom_color = calendar.has_custom_color(day_index)
	var has_events = calendar.get_events_for_day(day_index).size() > 0
	var is_bookmarked = calendar.is_bookmarked(day_index)
	var has_note = calendar.has_daily_note(day_index)
	var milestone = _get_milestone_for_day()
	
	if state == -1:
		if milestone:
			modulate = Color(1.0, 0.5, 0.8)
		elif is_bookmarked:
			modulate = Color(1.0, 0.9, 0.3)
		elif has_events:
			modulate = Color(0.9, 0.7, 1.0)
		else:
			modulate = Color(0.8, 0.8, 0.8)
		progress.value = 0
		
	elif state == 0:
		if milestone:
			modulate = Color(1.0, 0.3, 0.5)
		elif is_bookmarked:
			modulate = Color(1.0, 0.8, 0.0)
		elif has_events:
			modulate = Color(1.0, 0.8, 0.4)
		else:
			modulate = Color(1.0, 1.0, 0.6)
		progress.value = calendar.get_day_progress(day_index) * 100.0
		calendar.hcalendar.update_global_progress(modulate)
	
	else:
		if milestone and milestone.completed:
			modulate = Color(0.3, 0.9, 0.5)
		elif milestone:
			modulate = Color(0.9, 0.3, 0.3)
		elif is_bookmarked:
			modulate = Color(0.5, 0.8, 1.0)
		elif has_events:
			modulate = Color(0.4, 0.8, 1.0)
		else:
			modulate = Color(0.6, 1.0, 0.6)
		progress.value = 100
	
	if has_custom_color:
		modulate = calendar.get_day_custom_color(day_index)
	
	var today = (day_index == calendar.get_current_day_index())
	
	var day_count_text : String = "" if today else ""
	day_count_text += str("Day %d" % (day_index + 1))
	day_count_text += "" if today else ""
	
	day_count.text = day_count_text
	
	var day_start_unix = calendar.get_day_start_unix(day_index)
	var d = Time.get_datetime_dict_from_unix_time(day_start_unix)
	day_text.text = calendar.DAY_NAMES[d.weekday]
	day_num.text = "%s %d" % [calendar.MONTH_NAMES[d.month - 1], d.day]
	
	if is_bookmarked:
		day_count.text = "  Day %d" % (day_index + 1)
	
	%Bookmarkded.visible = is_bookmarked
	
	var events = calendar.get_events_for_day(day_index)
	var event_text = ""
	
	if events.size() > 0:
		for i in range(min(2, events.size())):
			var e = events[i]
			var check = "X" if e.completed else "O"
			var icon = _get_category_icon(e.category)
			event_text += str("%s %s %s\n" % [check, icon, e.title])
			
			if e.title.length() > 12:
				event_text = event_text.left(event_text.length() - (e.title.length() - 12)) + "..."
		
		if events.size() > 2:
			event_text += "+%d more\n" % (events.size() - 2)
	
	if milestone:
		var check = " X" if milestone.completed else ""
		event_text += "🏆 %s%s" % [milestone.title, check]
	
	if has_note:
		var note_text = calendar.get_daily_note(day_index)
		
		if note_text.length() > 8:
			note_text = note_text.left(note_text.length() - (note_text.length() - 8)) + ".."
		
		event_text += "\n📝 " + note_text
	
	%Event.text = event_text
	
	var tip = "Day %d - %s %s %d\n" % [day_index + 1, day_text.text, calendar.MONTH_NAMES[d.month - 1], d.day]
	tip += "Week %d\n\n" % (int(day_index / 7) + 1)
	tip += "🖱️ Right-click: Menu\n🖱️ Double-click: Add event\n🖱️ Click: Toggle complete"
	
	if is_bookmarked:
		tip += "\n\n⁕ BOOKMARKED"
	
	if has_note:
		tip += "\n\n📝 Note: " + calendar.get_daily_note(day_index).left(50)
		if calendar.get_daily_note(day_index).length() > 50:
			tip += "..."
	
	#tooltip_text = tip

func _get_milestone_for_day() -> Calendar.Milestone:
	for m in calendar.milestones:
		if m.day_index == day_index:
			return m
	return null

func _get_category_icon(cat: String) -> String:
	match cat:
		"story": return "|📖"
		"quest": return "|⚔️"
		"deadline": return "|⏰"
		"reminder": return "|🔔"
		"meeting": return "|👥"
		_: return "|"
