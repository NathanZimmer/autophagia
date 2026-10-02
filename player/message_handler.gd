class_name MessageHandler extends Node
## Handle propagation of messages from physics interactions (raycasts, Area3D collisions, etc.)

signal dialog_recieved(dialog: DialogTree)
signal note_received(note: Journal.Title)
signal item_received(item: InventoryItem)
signal inventory_received(inventory: Inventory)


## Send message to this handler
func send_message(object: Variant) -> void:

    var signal_to_emit: Signal
    if object is DialogTree:
        signal_to_emit = dialog_recieved
    elif object is Journal.Title:
        signal_to_emit = note_received
    elif object is InventoryItem:
        signal_to_emit = item_received
    elif object is Inventory:
        signal_to_emit = inventory_received
    else:
        push_warning("No response defined for type %s" % Utils.get_type(object))
        return
    signal_to_emit.emit(object)
