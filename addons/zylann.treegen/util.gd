tool

# Goes up all parents until a node of the given class is found
static func get_node_in_parents(node: Node, klass) -> Node:
	while node != null:
		node = node.get_parent()
		if node != null and node is klass:
			return node
	return null

