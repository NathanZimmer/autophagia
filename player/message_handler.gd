class_name MessageHandler extends Node
## Handle routing for messages from outside of this node hierarchy

signal dialog_recieved
signal note_received


## Just prints the message
func send_message(message: Variant) -> void:
    print(message)


func send_dialog(dialog: DialogTree) -> void:
    dialog_recieved.emit(dialog)


func send_note(note: Journal.Title) -> void:
    note_received.emit(note)
