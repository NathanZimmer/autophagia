extends Node

const BUTTON_HOVER = preload("uid://ccx0vhpymiblf")
const BUTTON_PRESSED = preload("uid://wj5dlxr0ka2")

const FAN = preload("uid://c8kkv2n0omdc6")
const BUZZ = preload("uid://fweeb5olpuly")

var _playback: AudioStreamPlaybackPolyphonic


func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    var player := AudioStreamPlayer.new()
    player.bus = &"Menus"
    add_child(player)

    var stream := AudioStreamPolyphonic.new()
    stream.polyphony = 32
    player.stream = stream
    player.play()
    _playback = player.get_stream_playback()
    get_tree().node_added.connect(_on_node_added)


func _ready() -> void:
    for bus in AudioServer.bus_count:
        AudioServer.set_bus_volume_db(
            bus, linear_to_db(Overrides.load_audio(AudioServer.get_bus_name(bus)) / 100.0)
        )

    _play_white_noise()


func _on_node_added(node: Node) -> void:
    if node is BaseButton:
        node.mouse_entered.connect(_play_hover)
        node.pressed.connect(play_pressed)


func _play_white_noise() -> void:
    var player := AudioStreamPlayer.new()
    player.bus = &"Ambient"
    add_child(player)
    var stream := AudioStreamPolyphonic.new()
    stream.polyphony = 32
    player.stream = stream
    player.play()
    var playback := player.get_stream_playback()
    playback.play_stream(BUZZ, 0, -20, 1.5)
    playback.play_stream(FAN, 0, 0, 1.3)


func _play_hover() -> void:
    _playback.play_stream(BUTTON_HOVER, 0, 3, randf_range(1.0, 1.0))


func play_pressed() -> void:
    _playback.play_stream(BUTTON_PRESSED, 0, 10, randf_range(1., 1.1))
