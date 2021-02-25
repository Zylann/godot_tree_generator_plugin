
# Base amount to spawn
var along_base_amount := 10
# How many to add per space unit
var along_amount_per_unit := 0.0
# From where to start spawning along the parent
var along_begin_ratio := 0.0
# From where to stop spawning along the parent
var along_end_ratio := 1.0
# Spawn randomness along parent
var along_jitter := 0.0
# Skip chance
var skip_probability := 0.0

# At how many angles to spawn around the parent
var around_amount := 3
# Randomness of the angle at which to spawn around the parent
var around_jitter := 0.75
# Angular offset from which the spawn angles are chosen
var around_offset := 0.0

# Vertical angle at which to orientate relative to the parent
var vertical_angle := PI / 3.0
# Randomness added to the angle
var vertical_angle_jitter := 0.0

# If greater than zero, the tip of the parent will be used
# to spawn as many as specified
#var end_amount := 0

