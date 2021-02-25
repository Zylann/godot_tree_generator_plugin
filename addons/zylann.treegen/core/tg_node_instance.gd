
var id := -1

# Where is the node instance along its parent, as a 0 to 1 ratio
var offset_ratio := 0.0

# Transform relative to the parent
var transform := Transform()

# Array of transforms
var path := []

var path_distances := []
var radii := []
var children := []

# Generated mesh
var mesh : ArrayMesh

