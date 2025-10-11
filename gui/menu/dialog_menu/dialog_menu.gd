extends MenuControl
## Uses a DialogTree to display dialog and dialog options on the screen. Handles text formatting
## And text/textbox scrolling

const RED_TAG = "Them"
const BLUE_TAG = "You"
const RED_FORMATTED = "[font_size=13][color=dark_salmon]%s[/color][/font_size]\n[indent]%s[/indent]\n"
const BLUE_FORMATTED = "[font_size=13][color=light_steel_blue]%s[/color][/font_size]\n[indent]%s[/indent]\n"

const MAX_DIALOG_OPTIONS = 5

const DIALOG_RESPONSE_DELAY_SEC = 0.2
const BOX_AUTO_SCROLL_DURATION_SEC = 0.1
const TEXT_SCROLL_CHARS_PER_SEC = 50.0
## Multiplied by TEXT_SCROLL_CHARS_PER_SEC for input text scrolling
const INPUT_TEXT_SCROLL_FACTOR = 2.5

var _dialog: DialogTree
var _dialog_buttons: Array[Button]
## visible_characters does not count \t but get_parsed_text().length() does, so count total tabs
var _tab_padding := 0

@onready var _dialog_box: RichTextLabel = %DialogBox
@onready var _option_template: Button = %DialogOptionTemplate
@onready var _scroll_container: ScrollContainer = %ScrollContainer


func _ready() -> void:
    super._ready()

    for i in range(MAX_DIALOG_OPTIONS):
        var dialog_button: Button = _option_template.duplicate()
        dialog_button.hide()
        dialog_button.pressed.connect(_update_dialog.bind(dialog_button))
        _option_template.get_parent().add_child(dialog_button)
        _dialog_buttons.append(dialog_button)

    _option_template.queue_free()


func _scroll_text(start_offset: int, target_length: int, scroll_factor := 1.0) -> void:
    _dialog_box.visible_characters += start_offset
    var tween := create_tween()
    tween.tween_property(
        _dialog_box,
        "visible_characters",
        target_length,
        (target_length - _dialog_box.visible_characters) / (TEXT_SCROLL_CHARS_PER_SEC * scroll_factor)
    )
    await tween.finished


func _update_dialog(source_button: Button) -> void:
    var option_text := source_button.text if source_button else ""

    for dialog_button in _dialog_buttons:
        dialog_button.hide()

    # Read in new dialog to text box and trigger box and text scrolling
    var text_length_after_input: int
    if not option_text.is_empty():
        _dialog_box.append_text(BLUE_FORMATTED % [BLUE_TAG, option_text])
        _tab_padding += 1
        text_length_after_input = _dialog_box.get_parsed_text().length()
        _dialog.select_dialog_option(option_text)

    _dialog_box.append_text(RED_FORMATTED % [RED_TAG, _dialog.get_dialog()])
    _tab_padding += 1

    await get_tree().process_frame  # Scroll container size isn't updated until next frame
    var v_scroll_bar := _scroll_container.get_v_scroll_bar()
    var scroll_tween: Tween
    if v_scroll_bar.max_value > _scroll_container.size.y:
        scroll_tween = create_tween()
        scroll_tween.tween_property(
            _scroll_container,
            "scroll_vertical",
            v_scroll_bar.max_value - v_scroll_bar.page,
            BOX_AUTO_SCROLL_DURATION_SEC
        )

    if not option_text.is_empty():
        await _scroll_text(BLUE_TAG.length(), text_length_after_input - _tab_padding, INPUT_TEXT_SCROLL_FACTOR)
        await get_tree().create_timer(DIALOG_RESPONSE_DELAY_SEC).timeout

    if scroll_tween and scroll_tween.is_running():
        await scroll_tween.finished

    await _scroll_text(RED_TAG.length(), _dialog_box.get_parsed_text().length() - _tab_padding)

    # Set buttons to new dialog options
    var dialog_options := _dialog.get_dialog_options()
    var i := 0
    for dialog_option in dialog_options:
        var dialog_button := _dialog_buttons[i]

        dialog_button.show()
        dialog_button.text = dialog_option

        var selected := dialog_options[dialog_option]
        dialog_button.theme_type_variation = "DialogButtonSelected" if selected else "DialogButton"

        i += 1

    for j in range(i, MAX_DIALOG_OPTIONS):
        var dialog_button := _dialog_buttons[i]
        dialog_button.text = ""
        dialog_button.hide()


func set_dialog(dialog: DialogTree) -> void:
    _dialog = dialog
    _dialog_box.text = ""
    _dialog_box.visible_characters = 0
    _tab_padding = 0
    _update_dialog(null)
