extends Control
class_name HCalendar

@export var calendar : Calendar
@export var day_cell_scene : PackedScene
@export var total_days : int = 0

@onready var scroll_container : ScrollContainer = $"VScrollBar/Callendar Container/ScrollContainer"
@onready var row : HBoxContainer = %CalendarRow

func _ready():
	total_days = calendar.duration_days
	build_calendar()
	await get_tree().process_frame
	center_on_today()
	setup_global_progress()

func _process(_delta):
	update_cells()

func build_calendar():
	for child in row.get_children():
		child.queue_free()
	
	for i in total_days:
		var cell = day_cell_scene.instantiate()
		cell.day_index = i
		cell.calendar = calendar
		row.add_child(cell)
		cell.update_cell()

func setup_global_progress():
	%GlobalProgress.max_value = calendar.duration_days

func update_global_progress(color : Color):
	%GlobalProgress.value = calendar.get_current_day_number()
	%GlobalProgress.modulate = color

func update_cells():
	for cell in row.get_children():
		cell.update_cell()

func center_on_today() -> void:
	if calendar == null:
		return
	
	var today_index : int = calendar.get_current_day_index()
	if today_index < 0 or today_index >= row.get_child_count():
		return
	
	var cell : Control = row.get_child(today_index) as Control
	if cell == null:
		return
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var cell_pos_in_row : float = cell.position.x
	var cell_center_in_row : float = cell_pos_in_row + cell.size.x / 2.0
	
	var view_width : float = scroll_container.size.x
	
	var target_scroll : float = cell_center_in_row - view_width / 2.0
	
	var hscrollbar : HScrollBar = scroll_container.get_h_scroll_bar()
	if hscrollbar != null:
		target_scroll = clamp(target_scroll, 0.0, hscrollbar.max_value)
	else:
		target_scroll = max(0.0, target_scroll)
	
	scroll_container.scroll_horizontal = int(target_scroll)
