extends Window

signal event_created(title: String, day_index: int, hour: int, minute: int, category: String)
signal event_updated(event: Calendar.CalendarEvent)
signal event_deleted(event: Calendar.CalendarEvent)

var day_index: int = 0
var editing_event: Calendar.CalendarEvent = null

@onready var title_edit: LineEdit = %TitleEdit
@onready var hour_spin: SpinBox = %HourSpin
@onready var minute_spin: SpinBox = %MinuteSpin
@onready var category_option: OptionButton = %CategoryOption
@onready var note_edit: TextEdit = %NoteEdit

func _ready():
	category_option.clear()
	category_option.add_item("General", 0)
	category_option.add_item("Story", 1)
	category_option.add_item("Quest", 2)
	category_option.add_item("Deadline", 3)
	category_option.add_item("Reminder", 4)
	category_option.add_item("Meeting", 5)
	
	%CreateButton.pressed.connect(_on_create_pressed)
	%CancelButton.pressed.connect(_on_cancel_pressed)
	
	%DeleteButton.pressed.connect(_on_delete_pressed)
	%DeleteButton.visible = false

func setup(p_day_index: int):
	day_index = p_day_index
	editing_event = null
	title = "Add Event - Day %d" % (day_index + 1)
	%CreateButton.text = "Create"
	%DeleteButton.visible = false

func setup_edit(event: Calendar.CalendarEvent):
	editing_event = event
	day_index = event.day_index
	title = "Edit Event - Day %d" % (day_index + 1)
	%CreateButton.text = "Save"
	%DeleteButton.visible = true
	
	title_edit.text = event.title
	hour_spin.value = event.hour
	minute_spin.value = event.minute
	note_edit.text = event.note
	
	var categories = ["general", "story", "quest", "deadline", "reminder", "meeting"]
	var cat_index = categories.find(event.category)
	if cat_index != -1:
		category_option.selected = cat_index

func _on_create_pressed():
	if title_edit.text.strip_edges().is_empty():
		push_warning("Event title cannot be empty")
		return
	
	var categories = ["general", "story", "quest", "deadline", "reminder", "meeting"]
	var category = categories[category_option.selected]
	
	if editing_event:
		editing_event.title = title_edit.text.strip_edges()
		editing_event.hour = int(hour_spin.value)
		editing_event.minute = int(minute_spin.value)
		editing_event.category = category
		editing_event.note = note_edit.text
		
		event_updated.emit(editing_event)
	else:
		event_created.emit(
			title_edit.text.strip_edges(),
			day_index,
			int(hour_spin.value),
			int(minute_spin.value),
			category
		)
	
	queue_free()

func _on_delete_pressed():
	if editing_event:
		event_deleted.emit(editing_event)
		queue_free()

func _on_cancel_pressed():
	queue_free()

func _on_close_requested() -> void:
	_on_cancel_pressed()
