tool

var _instance_rid = null


func _init():
	_instance_rid = VisualServer.instance_create()


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		VisualServer.free_rid(_instance_rid)


func set_world(w):
	VisualServer.instance_set_scenario(_instance_rid, w.get_scenario() if w != null else RID())


func set_transform(t):
	VisualServer.instance_set_transform(_instance_rid, t)


func set_material_override(material):
	VisualServer.instance_geometry_set_material_override( \
		_instance_rid, material.get_rid() if material != null else RID())


func set_visible(visible):
	VisualServer.instance_set_visible(_instance_rid, visible)


func set_mesh(mesh):
	print("Set mesh ", mesh)
	VisualServer.instance_set_base(_instance_rid, mesh.get_rid() if mesh != null else RID())
