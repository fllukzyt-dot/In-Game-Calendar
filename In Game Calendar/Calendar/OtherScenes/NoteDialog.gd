extends Window

signal note_saved(day_index: int, note: String)

var day_index: int = 0

@onready var note_edit: TextEdit = %NoteEdit

func _ready():
	%SaveButton.pressed.connect(_on_save_pressed)
	%CancelButton.pressed.connect(_on_cancel_pressed)
	%DeleteButton.pressed.connect(_on_delete_pressed)

func setup(p_day_index: int, existing_note: String = ""):
	day_index = p_day_index
	title = "Note - Day %d" % (day_index + 1)
	note_edit.text = existing_note
	
	%DeleteButton.visible = not existing_note.is_empty()

func _on_save_pressed():
	note_saved.emit(day_index, note_edit.text.strip_edges())
	print(note_edit.text.strip_edges())
	queue_free()

func _on_delete_pressed():
	note_saved.emit(day_index, "")
	queue_free()

func _on_cancel_pressed():
	queue_free()

func _on_close_requested() -> void:
	_on_cancel_pressed()
