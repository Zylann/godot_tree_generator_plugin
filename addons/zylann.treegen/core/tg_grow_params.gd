
# Base length of the branch in space units
var length := 15.0
# Modulates the length depending on where the branch spawns on the parent.
var length_curve_along_parent : Curve
var length_randomness := 0.0

# Radius at the beginning at the branch
var begin_radius := 1.0
# Radius at the end of the branch
var end_radius := 0.3
# How radius progresses between its begin and end value.
# This is calculated as `pow(offset / length, radius_curve)`
var radius_curve := 1.0
# Modulates the radii depending on where the branch spawns on the parent
var radius_curve_along_parent : Curve

# Distort the path. Acts as modifier.
var noise_period := 16.0
var noise_octaves := 3
var noise_amplitude := 0.0
# Modulates noise amplitude along path.
# This is calculated as `pow(offset / length, noise_curve)`
var noise_curve := 1.0

# User-defined curve for the branch.
# If set, will serve as a base for positional data.
# Modifiers will still apply on top of it.
#var authored_curve : Curve

var end_cap_flat := true

# Modifier to the grow angle to make the branch tend upward.
# Negative values makes branches tend downward.
var seek_sun := 0.0
