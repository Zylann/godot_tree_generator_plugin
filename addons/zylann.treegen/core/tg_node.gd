
const TG_SpawnParams = preload("./tg_spawn_params.gd")
const TG_GrowParams = preload("./tg_grow_params.gd")

const TYPE_BRANCH = 0
const TYPE_LEAF = 1

var id := -1
var type := TYPE_BRANCH
var local_seed := 0
var spawn_params : TG_SpawnParams
var grow_params : TG_GrowParams
# Mesh to spawn in leaf mode
var mesh : Mesh
var children = []

