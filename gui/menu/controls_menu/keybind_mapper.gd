extends VBoxContainer
## Duplicates the label-button pair once per keypair in _configurable_actions.
## Deletes the orginal template node when done.

## Emitted when an `InputEvent` is received with that input as its value
signal input_received

## Map of String to assign to `Label.text` and input action to update on
## button press
@export var _configurable_actions: Dictionary[String, String] = {
    "Forward": InputActions.Player.FORWARD,
    "Back": InputActions.Player.BACK,
    "Left": InputActions.Player.LEFT,
    "Right": InputActions.Player.RIGHT,
    "Jump": InputActions.Player.UP,
    "Interact": InputActions.Player.INTERACT,
    "Toggle fullscreen": InputActions.UI.FULLSCREEN,
}
## Map of String to assign to `Label.text` and input action for input that cannot be updated
@export
var _readonly_actions: Dictionary[String, String] = {"Close Menu/Cancel": InputActions.UI.CANCEL}
## Text to display on the button when it is waiting for input
@export var _button_waiting_text := "[press a key, esc to quit]"

@onready var _template_container := %TemplateContainer


func _ready() -> void:
    for action_label: String in _configurable_actions.keys():
        var action: String = _configurable_actions[action_label]

        # Assuming that there is only one event per input action
        var event := InputMap.action_get_events(action)[0]

        var new_container := _template_container.duplicate()
        add_child(new_container)

        var label: Label = new_container.get_child(0)
        label.text = action_label + " "
        var button: Button = new_container.get_child(1)
        button.text = event.as_text().replace("(Physical)", "")

        button.pressed.connect(_rebind_input_action.bind(button, action))

    for action_label: String in _readonly_actions.keys():
        var action: String = _readonly_actions[action_label]

        # Allow readonly to have multiple events bc the player can't reassign them
        var events := InputMap.action_get_events(action)

        var new_container := _template_container.duplicate()
        add_child(new_container)

        var label: Label = new_container.get_child(0)
        label.text = action_label + " "
        var button: Button = new_container.get_child(1)

        var event_strings: Array[String] = []
        for event: InputEvent in events:
            event_strings.append(event.as_text().replace("(Physical)", ""))
        button.text = ", ".join(event_strings)
        button.disabled = true
        button.tooltip_text = "Not editable"

    _template_container.queue_free()


func _input(event: InputEvent) -> void:
    input_received.emit(event)


## Capture all input until rebind is either cancelled or a valid InputEvent is triggered [br]
## ## Parameters [br]
## `button`: button that was pressed [br]
## `action`: input action to update [br]
func _rebind_input_action(button: Button, action: String) -> void:
    button.text = _button_waiting_text
    var waiting_for_input := true

    while waiting_for_input:
        var event: InputEvent = await input_received
        # Explicitly eat all input while waiting for a keypress
        accept_event()

        if event.is_action_pressed(InputActions.UI.CANCEL):
            var original_event := InputMap.action_get_events(action)[0]
            button.text = original_event.as_text().replace("(Physical)", "")
            break

        if event.is_released():
            continue
        if not (event is InputEventKey or event is InputEventMouseButton):
            continue

        button.text = event.as_text().replace("(Physical)", "")
        Settings.player_settings.set_input(action, event)
        ResourceSaver.save(Settings.player_settings)
        break
