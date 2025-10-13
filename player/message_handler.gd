class_name MessageHandler extends Node
## Takes in global messages and emits signals for local nodes

signal dialog_recieved
signal note_received


## Just prints the message
func send_message(message: Variant) -> void:
    print(message)


func send_dialog(dialog: DialogTree) -> void:
    dialog_recieved.emit(dialog)


func send_note(note: Texture2D) -> void:
    note_received.emit(note)
