extends Window

signal milestone_created(title: String, day_index: int, description: String)

var day_index: int = 0

@onready var title_edit: LineEdit = %TitleEdit
@onready var description_edit: TextEdit = %DescriptionEdit

func _ready():
	%CreateButton.pressed.connect(_on_create_pressed)
	%CancelButton.pressed.connect(_on_cancel_pressed)

func setup(p_day_index: int):
	day_index = p_day_index
	title = "Add Milestone - Day %d" % (day_index + 1)

func _on_create_pressed():
	if title_edit.text.strip_edges().is_empty():
		push_warning("Milestone title cannot be empty")
		return
	
	milestone_created.emit(
		title_edit.text.strip_edges(),
		day_index,
		description_edit.text.strip_edges()
	)
	
	queue_free()

func _on_cancel_pressed():
	queue_free()

func _on_close_requested() -> void:
	_on_cancel_pressed()
