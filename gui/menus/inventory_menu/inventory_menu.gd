class_name InventoryMenuControl extends MenuControl
## Handles user interfacing with the Inventory class

signal note_button_pressed

var NoteButton := preload("uid://cca6tcgscdrsi")


func _shortcut_input(event: InputEvent) -> void:
    super._shortcut_input(event)
    if event is InputEventKey and event.is_action_pressed(InputActions.UI.INVENTORY):
        menu_exited.emit()
        accept_event()


func add_note(title: Inventory.Title) -> void:
    var new_button := NoteButton.instantiate()
    new_button.set_label(Inventory.get_title_string(title))
    new_button.pressed.connect(note_button_pressed.emit.bind(title))

    _menu_container.add_child(new_button)
