extends Node

# https://www.bfxr.net/?sfx=Bfxr~Blip~0.06~0~0~0~0.14878757531799164~0~0~0~0~0~0.21~0.1~0~1~0~0~0.25~0~0~0~0~0~0~0~0~0~0~0~0.16~0.33~0.27~2
const BUTTON_HOVER = preload("uid://boyqhw3odygub")
const BUTTON_PRESSED = preload("uid://wj5dlxr0ka2")

var playback: AudioStreamPlaybackPolyphonic


func _enter_tree() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    var player := AudioStreamPlayer.new()
    add_child(player)

    var stream := AudioStreamPolyphonic.new()
    stream.polyphony = 32
    player.stream = stream
    player.play()
    # Get the polyphonic playback stream to play sounds
    playback = player.get_stream_playback()

    get_tree().node_added.connect(_on_node_added)


func _on_node_added(node:Node) -> void:
    if node is Button and not node is TextureButton:
        node.mouse_entered.connect(_play_hover)
        node.pressed.connect(_play_pressed)


func _play_hover() -> void:
    playback.play_stream(BUTTON_HOVER, 0, -30, randf_range(1.6, 1.6))


func _play_pressed() -> void:
    playback.play_stream(BUTTON_PRESSED, 0, -10, randf_range(1., 1.1))