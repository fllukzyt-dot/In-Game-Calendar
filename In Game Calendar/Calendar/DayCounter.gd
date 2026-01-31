extends Node
class_name Calendar

@export var start_year : int = 2026
@export var start_month : int = 1
@export var start_day : int = 1
@export var duration_days : int = 100
@export var day_cell_scene : PackedScene
@export var hcalendar : HCalendar

var callendar_up : bool = false

const DAY_SECONDS := 86400
const DAY_NAMES := [
	"Sunday", "Monday", "Tuesday",
	"Wednesday", "Thursday", "Friday", "Saturday"
]
const MONTH_NAMES := [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
]

var start_unix: int


class CalendarEvent:
	var title: String
	var day_index: int
	var hour: int
	var minute: int
	var category: String = "general"
	var completed: bool = false
	var color: Color = Color.WHITE
	var note: String = ""
	
	func _init(p_title: String, p_day_index: int, p_hour: int = 0, p_minute: int = 0):
		title = p_title
		day_index = p_day_index
		hour = p_hour
		minute = p_minute


class Milestone:
	var title: String
	var day_index: int
	var description: String = ""
	var completed: bool = false
	
	func _init(p_title: String, p_day_index: int):
		title = p_title
		day_index = p_day_index


var daily_notes: Dictionary = {}


var events_by_day: Dictionary = {}
var milestones: Array[Milestone] = []
var bookmarks: Array[int] = []
var day_custom_colors: Dictionary = {}


signal day_changed(new_day_index: int, old_day_index: int)
signal event_activated(event: CalendarEvent)
signal milestone_reached(milestone: Milestone)
signal week_completed(week_number: int)

var last_day_index: int = -1

const SAVE_PATH = "user://calendar_save.json"



func add_event(title: String, day_index: int, hour: int = 0, minute: int = 0, category: String = "general") -> CalendarEvent:
	var event = CalendarEvent.new(title, day_index, hour, minute)
	event.category = category
	
	if not events_by_day.has(day_index):
		events_by_day[day_index] = []
	
	events_by_day[day_index].append(event)
	return event

func get_events_for_day(day_index: int) -> Array:
	if events_by_day.has(day_index):
		return events_by_day[day_index]
	return []

func get_events_by_category(category: String) -> Array:
	var result = []
	for day in events_by_day:
		for event in events_by_day[day]:
			if event.category == category:
				result.append(event)
	return result

func get_upcoming_events(from_day: int, count: int = 5) -> Array:
	var result = []
	for i in range(from_day, duration_days):
		var events = get_events_for_day(i)
		for event in events:
			if not event.completed:
				result.append(event)
				if result.size() >= count:
					return result
	return result

func remove_event(event: CalendarEvent) -> void:
	if events_by_day.has(event.day_index):
		events_by_day[event.day_index].erase(event)

func clear_all_events() -> void:
	events_by_day.clear()



func set_day_custom_color(day_index: int, color: Color) -> void:
	if color.a == 0.0:
		day_custom_colors.erase(day_index)
	else:
		day_custom_colors[day_index] = color
	save_calendar()

func get_day_custom_color(day_index: int) -> Color:
	return day_custom_colors.get(day_index, Color.WHITE)

func has_custom_color(day_index: int) -> bool:
	return day_custom_colors.has(day_index)



func add_milestone(title: String, day_index: int, description: String = "") -> Milestone:
	var milestone = Milestone.new(title, day_index)
	milestone.description = description
	milestones.append(milestone)
	return milestone

func get_next_milestone() -> Milestone:
	var current_day = get_current_day_index()
	for milestone in milestones:
		if milestone.day_index >= current_day and not milestone.completed:
			return milestone
	return null

func get_milestones_for_week(week_number: int) -> Array:
	var _start_day = week_number * 7
	var end_day = _start_day + 6
	var result = []
	for milestone in milestones:
		if milestone.day_index >= _start_day and milestone.day_index <= end_day:
			result.append(milestone)
	return result



func set_daily_note(day_index: int, note: String) -> void:
	if note.is_empty():
		daily_notes.erase(str(day_index))
	else:
		daily_notes[str(day_index)] = note
	save_calendar()

func get_daily_note(day_index: int) -> String:
	return daily_notes.get(str(day_index), "")

func has_daily_note(day_index: int) -> bool:
	return daily_notes.has(str(day_index)) and daily_notes[str(day_index)] != ""


func add_bookmark(day_index: int) -> void:
	if not bookmarks.has(day_index):
		bookmarks.append(day_index)
		bookmarks.sort()

func remove_bookmark(day_index: int) -> void:
	bookmarks.erase(day_index)

func is_bookmarked(day_index: int) -> bool:
	return bookmarks.has(day_index)

func get_next_bookmark(from_day: int = -1) -> int:
	if from_day == -1:
		from_day = get_current_day_index()
	for bookmark in bookmarks:
		if bookmark > from_day:
			return bookmark
	return -1

func get_previous_bookmark(from_day: int = -1) -> int:
	if from_day == -1:
		from_day = get_current_day_index()
	for i in range(bookmarks.size() - 1, -1, -1):
		if bookmarks[i] < from_day:
			return bookmarks[i]
	return -1



func get_days_remaining() -> int:
	return max(0, duration_days - get_current_day_number())

func get_completion_percentage() -> float:
	return (float(get_current_day_number()) / float(duration_days)) * 100.0

func get_current_week() -> int:
	return int(get_current_day_index() / 7) + 1

func get_days_in_current_week() -> int:
	return (get_current_day_index() % 7) + 1

func get_completed_events_count() -> int:
	var count = 0
	for day in events_by_day:
		for event in events_by_day[day]:
			if event.completed:
				count += 1
	return count

func get_total_events_count() -> int:
	var count = 0
	for day in events_by_day:
		count += events_by_day[day].size()
	return count

func get_completed_milestones_count() -> int:
	var count = 0
	for milestone in milestones:
		if milestone.completed:
			count += 1
	return count



func find_events_by_title(search_text: String) -> Array:
	var result = []
	for day in events_by_day:
		for event in events_by_day[day]:
			if search_text.to_lower() in event.title.to_lower():
				result.append(event)
	return result

func get_days_with_events() -> Array:
	return events_by_day.keys()

func get_days_with_notes() -> Array:
	return daily_notes.keys()



func jump_to_next_event() -> int:
	var current = get_current_day_index()
	for i in range(current + 1, duration_days):
		if events_by_day.has(i):
			return i
	return -1

func jump_to_previous_event() -> int:
	var current = get_current_day_index()
	for i in range(current - 1, -1, -1):
		if events_by_day.has(i):
			return i
	return -1

func jump_to_day(day_index: int) -> void:
	# À implémenter avec ton système de scrolling
	if has_node("$HorizontalCalendar"):
		$HorizontalCalendar.scroll_to_day(day_index)



func save_calendar() -> void:
	var save_data = get_save_data()
	var json_string = JSON.stringify(save_data, "\t")
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Calendar saved successfully")
	else:
		push_error("Failed to save calendar")

func load_calendar() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting fresh")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return false
	
	load_save_data(json.data)
	print("Calendar loaded successfully")
	return true

func get_save_data() -> Dictionary:
	var events_data = []
	for day in events_by_day:
		for event in events_by_day[day]:
			events_data.append({
				"title": event.title,
				"day_index": event.day_index,
				"hour": event.hour,
				"minute": event.minute,
				"category": event.category,
				"completed": event.completed,
				"note": event.note
			})
	
	var milestones_data = []
	for milestone in milestones:
		milestones_data.append({
			"title": milestone.title,
			"day_index": milestone.day_index,
			"description": milestone.description,
			"completed": milestone.completed
		})
	
	var colors_data = {}
	for day in day_custom_colors:
		var color = day_custom_colors[day]
		colors_data[str(day)] = {
			"r": color.r,
			"g": color.g,
			"b": color.b,
			"a": color.a
		}
	
	return {
		"version": 1,
		"events": events_data,
		"milestones": milestones_data,
		"daily_notes": daily_notes,
		"bookmarks": bookmarks,
		"custom_colors": colors_data
	}

func load_save_data(data: Dictionary) -> void:
	clear_all_events()
	milestones.clear()
	daily_notes.clear()
	bookmarks.clear()
	
	if data.has("events"):
		for event_data in data.events:
			var event = CalendarEvent.new(
				event_data.title,
				event_data.day_index,
				event_data.hour,
				event_data.minute
			)
			event.category = event_data.get("category", "general")
			event.completed = event_data.get("completed", false)
			event.note = event_data.get("note", "")
			
			if not events_by_day.has(event.day_index):
				events_by_day[event.day_index] = []
			events_by_day[event.day_index].append(event)
	
	if data.has("milestones"):
		for milestone_data in data.milestones:
			var milestone = Milestone.new(
				milestone_data.title,
				milestone_data.day_index
			)
			milestone.description = milestone_data.get("description", "")
			milestone.completed = milestone_data.get("completed", false)
			milestones.append(milestone)
	
	if data.has("daily_notes"):
		daily_notes = data.daily_notes.duplicate()
	
	if data.has("bookmarks"):
		var bookmarks_data = data.bookmarks
		if bookmarks_data is Array:
			for bookmark in bookmarks_data:
				if bookmark is int or bookmark is float:
					bookmarks.append(int(bookmark))
				else:
					push_warning("Invalid bookmark type: " + str(typeof(bookmark)))
			bookmarks.sort()
		else:
			push_warning("Bookmarks data is not an Array, skipping")
	
	if data.has("custom_colors"):
		day_custom_colors.clear()
		var colors_data = data.custom_colors
		for day_str in colors_data:
			var day_index = int(day_str)
			var c = colors_data[day_str]
			day_custom_colors[day_index] = Color(c.r, c.g, c.b, c.a)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted: %s" % SAVE_PATH)
		
		clear_all_events()
		milestones.clear()
		daily_notes.clear()
		bookmarks.clear()
		
		print("Calendar reset to empty state")
	else:
		print("No save file to delete")



func _ready():
	start_unix = _date_to_unix(start_year, start_month, start_day)
	
	var loaded = load_calendar()
	
	%"Current Day".text = str("Day ", get_current_day_number())
	callendar_up = !callendar_up
	_on_down_arrow_pressed()
	last_day_index = get_current_day_index()
	
	await get_tree().process_frame
	await get_tree().process_frame
	if hcalendar:
		hcalendar.update_cells()

func _process(delta: float) -> void:
	%"Current Day".text = str("Day ", get_current_day_number())
	_check_day_change()
	_check_events()

func _check_day_change() -> void:
	var current_day = get_current_day_index()
	if current_day != last_day_index:
		var old_day = last_day_index
		last_day_index = current_day
		day_changed.emit(current_day, old_day)
		
		if current_day % 7 == 0:
			week_completed.emit(get_current_week())

func _check_events() -> void:
	var current_day = get_current_day_index()
	var events = get_events_for_day(current_day)
	
	for event in events:
		if not event.completed:
			var current_date = get_current_date()
			var event_time_reached = (current_date.hour > event.hour) or \
									 (current_date.hour == event.hour and current_date.minute >= event.minute)
			
			if event_time_reached:
				event_activated.emit(event)

func get_now_unix() -> float:
	return Time.get_unix_time_from_system()

func get_current_date() -> Dictionary:
	return Time.get_datetime_dict_from_system()

func get_current_day_index() -> int:
	var now := get_now_unix()
	if now < start_unix:
		return 0
	return int((now - start_unix) / DAY_SECONDS)

func get_current_day_number() -> int:
	return get_current_day_index() + 1

func get_current_date_string() -> String:
	var d := get_current_date()
	return "%s %d %s %d" % [
		DAY_NAMES[d.weekday],
		d.day,
		MONTH_NAMES[d.month - 1],
		d.year
	]

func get_current_day_string() -> String:
	var d := get_current_date()
	return "%s" % [DAY_NAMES[d.weekday]]

func get_current_day_progress() -> float:
	var now := get_now_unix()
	var day_start := _truncate_to_day(now)
	return clamp(float(now - day_start) / DAY_SECONDS, 0.0, 1.0)

func get_day_start_unix(day_index: int) -> int:
	return start_unix + day_index * DAY_SECONDS

func get_day_state(day_index: int) -> int:
	var now := get_now_unix()
	var day_start := get_day_start_unix(day_index)
	var day_end := day_start + DAY_SECONDS
	if now < day_start:
		return -1
	if now >= day_end:
		return 1
	return 0

func get_day_progress(day_index: int) -> float:
	var state := get_day_state(day_index)
	if state == 1:
		return 1.0
	if state == -1:
		return 0.0
	var now := get_now_unix()
	var day_start := get_day_start_unix(day_index)
	return clamp(float(now - day_start) / DAY_SECONDS, 0.0, 1.0)

func _date_to_unix(y, m, d) -> int:
	return Time.get_unix_time_from_datetime_dict({
		"year": y,
		"month": m,
		"day": d,
		"hour": 0,
		"minute": 0,
		"second": 0
	})

func _truncate_to_day(unix_time: int) -> int:
	var d := Time.get_datetime_dict_from_unix_time(unix_time)
	return _date_to_unix(d.year, d.month, d.day)

func _on_down_arrow_pressed() -> void:
	callendar_up = !callendar_up
	%ArrowLabel.text = "↓" if callendar_up else "↑"
	%CalendarLabel.modulate = Color(1.0, 1.0, 1.0, 1.0 if callendar_up else 0.4)
	%"Callendar Container".visible = callendar_up
	if callendar_up:
		$HorizontalCalendar.center_on_today()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_calendar()

func _on_delete_pressed() -> void:
	delete_save()
