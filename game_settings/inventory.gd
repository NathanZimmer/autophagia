class_name Inventory extends Node
## TODO


class Note:
    var texture: Texture2D
    var is_image: bool
    var discovered: bool


    func _init(
        texture: Texture2D = PlaceholderTexture2D.new(),
        is_image := false,
        discovered := false
    ) -> void:
        self.texture = texture
        self.is_image = is_image
        self.discovered = discovered


signal note_discovered

# Using an ENUM for naming to enfoce pre-determined order
enum Title {
    TEST_NOTE,
    TEST_NOTE_2
}
var _notes: Dictionary[Title, Note] = {
    Title.TEST_NOTE: Note.new(preload("uid://bsb4kif4f8y6r")),
    Title.TEST_NOTE_2: Note.new(preload("uid://bsb4kif4f8y6r"))
}

@onready var _message_handler: MessageHandler = %MessageHandler


func _ready() -> void:
    if _message_handler:
        _message_handler.note_received.connect(_discover_note)


func _discover_note(title: Title) -> void:
    var note := _notes[title]
    note.discovered = true
    note_discovered.emit(title)


func get_note_texture(title: Title) -> Texture2D:
    return _notes[title].texture


func get_discovered_notes() -> Dictionary[Title, Note]:
    var discovered_notes: Dictionary[Title, Note]
    for title in _notes:
        var note := _notes[title]
        if note.discovered:
            discovered_notes[title] = note

    return discovered_notes


static func get_title_string(note_title: Title) -> String:
    match(note_title):
        Title.TEST_NOTE:
            return "Test Note"
        _:
            return "TODO"
