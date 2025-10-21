class_name InventoryMenuControl extends MenuControl
## Handles user interfacing with the Inventory class

signal note_button_pressed

@onready var _template: Button = %NoteButtonTemplate


func _ready() -> void:
    super._ready()
    _template.hide()


func _shortcut_input(event: InputEvent) -> void:
    super._shortcut_input(event)
    if event is InputEventKey and event.is_action_pressed(InputActions.UI.INVENTORY):
        menu_exited.emit()
        accept_event()


func add_note(title: Inventory.Title) -> void:
    var note_button := _template.duplicate()
    note_button.show()
    note_button.text = Inventory.get_title_string(title)
    print(Inventory.get_title_string(title))
    note_button.pressed.connect(note_button_pressed.emit.bind(title))
    var parent := _template.get_parent()
    parent.add_child(note_button)
    parent.move_child(note_button, 0)
