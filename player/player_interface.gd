extends Node
## TODO

@onready var _gui: iGui = %Gui
@onready var _player_body: iPlayerBody = %PlayerBody
@onready var _camera: PlayerCamera = %PlayerCamera
@onready var _inventory: Inventory = %Inventory
@onready var _journal: Journal = %Journal

var _to_repace: Array[PlayerProxy]

func _enter_tree() -> void:
    get_tree().node_added.connect(
        func(node: Node) -> void:
            if node is PlayerProxy:
                _to_repace.append(node)
    )


func _ready() -> void:
    _add_body_to_scene()
    _connect_signals()


func _add_body_to_scene() -> void:
    if _to_repace.size() == 0:
        push_warning("No PlayerProxy node found. Player not added to sceme")
        return
    elif _to_repace.size() > 1:
        push_error("attempting to insert player into scene multiple times")

    var node := _to_repace[-1]
    var transform := node.global_transform
    remove_child(_player_body)
    node.replace_by(_player_body)
    _player_body.global_transform = transform
    node.queue_free()


## Connect signals between `_player_body` and local nodes
func _connect_signals() -> void:
    _player_body.is_on_floor_changed.connect(_gui.set_interact_menus_enabled)
    _player_body.get_raycast_collision_signal().connect(_gui.set_crosshair_texture)

    var handler: MessageHandler = _player_body.find_children("*", "MessageHandler", false).get(0)
    if Utils.verify_component(self, handler):
        handler.dialog_recieved.connect(_gui.open_dialog_menu)
        handler.note_received.connect(_gui.open_note_menu)
        handler.note_received.connect(_journal.discover_note)
        handler.inventory_received.connect(_gui.open_chest)
        handler.item_received.connect(_inventory.add_item)


## TODO
func get_body() -> iPlayerBody:
    return _player_body


## TODO
func retrieve_body() -> void:
    add_child(_player_body)


## TODO
func get_camera() -> PlayerCamera:
    return _camera
