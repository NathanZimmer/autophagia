class_name DialogTree extends Object
## TODO

var _root: DialogNode
var _node: DialogNode
var _visited_nodes: Array[DialogNode] = []


class DialogNode:
    ## TODO
    var id: String
    var message: String
    var responses: Dictionary[String, DialogNode] = {}


    func _init(id: String, message: String) -> void:
        self.id = id
        self.message = message


func _init(json_path: String) -> void:
    var json_file := FileAccess.open(json_path, FileAccess.READ)
    if json_file == null:
        push_error(error_string(FileAccess.get_open_error()))
        return

    var json := JSON.new()
    json.parse(json_file.get_as_text())
    _parse(json.data)


func _to_string() -> String:
    return JSON.stringify(_get_tree_as_dict(_root, []), "  ", false)


func _get_tree_as_dict(
    node: DialogNode,
    visited_nodes: Array[DialogNode]
) -> Dictionary:
    visited_nodes.append(node)
    var subtree_dict: Dictionary = {}

    for response in node.responses:
        var child_node := node.responses[response]
        if not child_node in visited_nodes:
            subtree_dict[response] = _get_tree_as_dict(child_node, visited_nodes)
        else:
            subtree_dict[response] = child_node.id

    return {node.id: [node.message, subtree_dict]}


func _parse(dialog_tree: Dictionary) -> void:
    # Create all nodes first
    var nodes: Dictionary[String, DialogNode]
    for id: String in dialog_tree:
        var message: String = dialog_tree[id]['message']

        var node := DialogNode.new(id, message)
        nodes[id] = node

    _root = nodes["root"]
    _node = _root

    # Assign responses
    for id in nodes:
        var node := nodes[id]

        var responses: Dictionary[String, DialogNode] = {}
        for response: String in dialog_tree[id]['responses']:
            var child_id: String = dialog_tree[id]['responses'][response]
            responses[response] = nodes[child_id]

        node.responses = responses


func get_dialog() -> String:
    return _node['message']


## Get map of dialog options to whether that option has already been selected
func get_dialog_options() -> Dictionary[String, bool]:
    var responses: Dictionary[String, bool]

    for response: String in _node['responses']:
        var target_node: DialogNode = _node['responses'][response]
        responses[response] = target_node in _visited_nodes

    return responses


func select_dialog_option(dialog: String) -> void:
    _node = _node["responses"][dialog]
