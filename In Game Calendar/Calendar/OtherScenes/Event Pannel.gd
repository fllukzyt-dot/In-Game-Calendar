extends Control

signal clicked(id : int)

var id : int = -1

func update(name_ : String, id_ : int):
	$".".text = name_
	id = id_

func _on_pressed() -> void:
	clicked.emit(id)
