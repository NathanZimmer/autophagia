class_name DialogTree extends RefCounted
## Holds dialog and reponses in a tree structure. Reads input from a JSON.
## Format can be found in dialog_template.json.

var _root: DialogNode
var _node: DialogNode
var _visited_nodes: Array[DialogNode] = []


class DialogNode:
    var id: StringName
    var text: String
    var responses: Dictionary[String, DialogNode] = {}

    func _init(id: StringName, text: String) -> void:
        self.id = id
        self.text = text


func _init(json_path: String) -> void:
    var json_file := FileAccess.open(json_path, FileAccess.READ)
    if not json_file:
        push_error(error_string(FileAccess.get_open_error()))
        return

    var json := JSON.new()
    json.parse(json_file.get_as_text())
    _parse(json.data)


func _to_string() -> String:
    if not _root:
        return ""
    return JSON.stringify(_get_tree_as_dict(_root, []), "    ", false)


func _get_tree_as_dict(node: DialogNode, visited_nodes: Array[DialogNode]) -> Dictionary:
    visited_nodes.append(node)
    var subtree_dict: Dictionary = {}

    for response in node.responses:
        var child_node := node.responses[response]
        if not child_node in visited_nodes:
            subtree_dict[response] = _get_tree_as_dict(child_node, visited_nodes)
        else:
            subtree_dict[response] = child_node.id

    return {"node_id": node.id, "text": node.text, "responses": subtree_dict}


func _parse(dialog_tree: Dictionary) -> void:
    # Create all nodes first
    var nodes: Dictionary[StringName, DialogNode]
    for id: StringName in dialog_tree:
        var text: String = dialog_tree[id]["text"]

        var node := DialogNode.new(id, text)
        nodes[id] = node

    # Then assign responses
    for id in nodes:
        var node := nodes[id]

        var responses: Dictionary[String, DialogNode] = {}
        for response: String in dialog_tree[id]["responses"]:
            var child_id: StringName = dialog_tree[id]["responses"][response]
            responses[response] = nodes[child_id]

        node.responses = responses

    _root = nodes["root"]
    _node = _root


func get_dialog() -> String:
    return _node["text"] if _node else ""


## Get map of dialog options to whether that option has already been selected
func get_dialog_options() -> Dictionary[String, bool]:
    var responses: Dictionary[String, bool]

    if not _node:
        return responses

    for response: String in _node["responses"]:
        var target_node: DialogNode = _node["responses"][response]
        responses[response] = target_node in _visited_nodes

    return responses


func select_dialog_option(dialog: String) -> void:
    if not _node:
        return
    _node = _node["responses"][dialog]
    _visited_nodes.append(_node)
