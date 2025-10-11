class_name MessageHandler extends Node
## Takes in global messages and emits signals for local nodes

signal dialog_recieved


## Just prints the message
func send_message(message: Variant) -> void:
    print(message)


func send_dialog(dialog: DialogTree) -> void:
    dialog_recieved.emit(dialog)
