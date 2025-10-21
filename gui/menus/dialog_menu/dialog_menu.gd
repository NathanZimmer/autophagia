class_name DialogMenuControl extends MenuControl
## Uses a DialogTree to display dialog and dialog options on the screen. Handles text formatting
## And text/textbox scrolling

const RED_TAG = "Them"
const BLUE_TAG = "You"
const RED_FORMATTED = "[font_size=13][color=dark_salmon]%s[/color][/font_size]\n[indent]%s[/indent]\n"
const BLUE_FORMATTED = "[font_size=13][color=light_steel_blue]%s[/color][/font_size]\n[indent]%s[/indent]\n"

# Hard limit of 9 because of hand-coded substring call and dialog option numbering
const MAX_DIALOG_OPTIONS = 9

const DIALOG_RESPONSE_DELAY_SEC = 0.2
const BOX_AUTO_SCROLL_DURATION_SEC = 0.1
const TEXT_SCROLL_CHARS_PER_SEC = 50.0
## Multiplied by TEXT_SCROLL_CHARS_PER_SEC for input text scrolling
const INPUT_TEXT_SCROLL_FACTOR = 2.5

var _dialog: DialogTree
var _dialog_buttons: Array[Button]
## visible_characters does not count \t but get_parsed_text().length() does, so count total tabs
var _tab_padding := 0
var _dialog_scroll_tween: Tween
var _box_scroll_tween: Tween
var _button_container: VBoxContainer

@onready var _dialog_box: RichTextLabel = %DialogBox
@onready var _scroll_container: ScrollContainer = %ScrollContainer


func _ready() -> void:
    super._ready()

    var option_template: Button = get_node("%DialogOptionTemplate")

    _button_container = option_template.get_parent()
    for i in range(MAX_DIALOG_OPTIONS):
        var dialog_button: Button = option_template.duplicate()
        dialog_button.hide()
        dialog_button.pressed.connect(_update_dialog.bind(dialog_button))
        _button_container.add_child(dialog_button)
        _dialog_buttons.append(dialog_button)

    _button_container.remove_child(option_template)
    option_template.queue_free()


func _input(event: InputEvent) -> void:
    super._input(event)

    if event.is_action_pressed(InputActions.UI.CANCEL):
        _clear_dialog()
    if event is InputEventKey and event.is_action_pressed(InputActions.UI.INVENTORY):
        accept_event()


func _scroll_text(start_offset: int, target_length: int, scroll_factor := 1.0) -> void:
    _dialog_box.visible_characters += start_offset
    _dialog_scroll_tween = create_tween()
    var duration := (
        (target_length - _dialog_box.visible_characters)
        / (TEXT_SCROLL_CHARS_PER_SEC * scroll_factor)
    )
    _dialog_scroll_tween.tween_property(_dialog_box, "visible_characters", target_length, duration)
    await _dialog_scroll_tween.finished


func _unhandled_input(event: InputEvent) -> void:
    # Not going to bother with adding 1-9 to input map since rebinding isn't allowed and
    # there is no controller equivilant
    if not event is InputEventKey:
        return
    if not (event.keycode < 47 + MAX_DIALOG_OPTIONS and event.keycode > 47):
        return

    var buttons := _button_container.get_children()
    if not buttons[event.keycode - 49].visible:
        return
    buttons[event.keycode - 49].pressed.emit()
    accept_event()


func _update_dialog(source_button: Button) -> void:
    # substr(3) to remove "n. "
    var option_text := source_button.text.substr(3) if source_button else ""

    for dialog_button in _dialog_buttons:
        dialog_button.hide()
    _back_button.hide()

    # Read in new dialog to text box and trigger box and text scrolling
    var text_length_after_input: int
    if not option_text.is_empty():
        _dialog_box.append_text(BLUE_FORMATTED % [BLUE_TAG, option_text])
        _tab_padding += 1
        text_length_after_input = _dialog_box.get_parsed_text().length()
        _dialog.select_dialog_option(option_text)

    _dialog_box.append_text(RED_FORMATTED % [RED_TAG, _dialog.get_dialog()])
    _tab_padding += 1

    # Scroll container size isn't updated until next frame
    # NOTE: Not sure why this works but get_tree().process_frame doesn't
    await get_tree().create_timer(0).timeout
    var v_scroll_bar := _scroll_container.get_v_scroll_bar()
    if v_scroll_bar.max_value > _scroll_container.size.y:
        _box_scroll_tween = create_tween()
        _box_scroll_tween.tween_property(
            _scroll_container,
            "scroll_vertical",
            v_scroll_bar.max_value - v_scroll_bar.page,
            BOX_AUTO_SCROLL_DURATION_SEC
        )

    if not option_text.is_empty():
        await _scroll_text(
            BLUE_TAG.length(), text_length_after_input - _tab_padding, INPUT_TEXT_SCROLL_FACTOR
        )
        await get_tree().create_timer(DIALOG_RESPONSE_DELAY_SEC).timeout

    if _box_scroll_tween and _box_scroll_tween.is_running():
        await _box_scroll_tween.finished

    await _scroll_text(RED_TAG.length(), _dialog_box.get_parsed_text().length() - _tab_padding)

    # Set buttons to new dialog options
    _button_container.move_child(_back_button, MAX_DIALOG_OPTIONS)
    var dialog_options := _dialog.get_dialog_options()
    var i := 0
    for dialog_option in dialog_options:
        var dialog_button := _dialog_buttons[i]

        dialog_button.show()
        dialog_button.text = "%d. " % (dialog_button.get_index() + 1) + dialog_option

        var selected := dialog_options[dialog_option]
        dialog_button.theme_type_variation = "DialogButtonSelected" if selected else "DialogButton"

        i += 1

    for j in range(i, MAX_DIALOG_OPTIONS):
        var dialog_button := _dialog_buttons[i]
        dialog_button.text = ""
        dialog_button.hide()

    _back_button.text = "%d. EXIT" % (i + 1)
    _button_container.move_child(_back_button, i)
    _back_button.show()


func set_dialog(dialog: DialogTree) -> void:
    _dialog = dialog
    _dialog_box.text = ""
    _dialog_box.visible_characters = 0
    _tab_padding = 0
    _update_dialog(null)


func _clear_dialog() -> void:
    if _dialog_scroll_tween:
        _dialog_scroll_tween.kill()
    if _box_scroll_tween:
        _box_scroll_tween.kill()

    _dialog = null
    _dialog_box.text = ""
    _dialog_box.visible_characters = 0
    _tab_padding = 0
