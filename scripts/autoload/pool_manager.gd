extends Node
## Generisches Object-Pooling (Autoload).
## Projektile und andere haeufig erzeugte Nodes werden recycelt statt
## staendig instanziiert/freigegeben -> weniger Allocations & GC-Spikes.
##
## Nutzung:
##   var p = PoolManager.acquire("res://scenes/combat/projectile.tscn")
##   ... p.setup(...) ...
##   # spaeter:  PoolManager.release(p)
##
## Objekte im Pool sollten optional die Methoden _on_pool_acquire()/_on_pool_release()
## implementieren, um ihren Zustand zurueckzusetzen.

var _pools: Dictionary = {}          # scene_path -> Array[Node]
var _scene_cache: Dictionary = {}    # scene_path -> PackedScene
var _container: Node                  # Elternknoten fuer inaktive Objekte

func _ready() -> void:
	_container = Node.new()
	_container.name = "PooledInactive"
	add_child(_container)

func _get_scene(path: String) -> PackedScene:
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path]

## Warmup: erzeugt vorab N Instanzen, um Laufzeit-Spikes zu vermeiden.
func prewarm(scene_path: String, count: int) -> void:
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	for i in count:
		var inst := _get_scene(scene_path).instantiate()
		_deactivate(inst)
		_pools[scene_path].append(inst)

## Holt ein Objekt aus dem Pool (oder erzeugt eines, wenn leer).
func acquire(scene_path: String) -> Node:
	var pool: Array = _pools.get(scene_path, [])
	var obj: Node
	if pool.size() > 0:
		obj = pool.pop_back()
	else:
		obj = _get_scene(scene_path).instantiate()
	# Merken, aus welchem Pool das Objekt stammt.
	obj.set_meta("pool_path", scene_path)
	if obj.get_parent() == _container:
		_container.remove_child(obj)
	if obj.has_method("_on_pool_acquire"):
		obj._on_pool_acquire()
	return obj

## Gibt ein Objekt an den Pool zurueck (statt queue_free()).
func release(obj: Node) -> void:
	if not is_instance_valid(obj):
		return
	var path: String = obj.get_meta("pool_path", "")
	if obj.has_method("_on_pool_release"):
		obj._on_pool_release()
	var parent := obj.get_parent()
	if parent:
		parent.remove_child(obj)
	_deactivate(obj)
	if path.is_empty():
		obj.queue_free()
		return
	if not _pools.has(path):
		_pools[path] = []
	_pools[path].append(obj)

func _deactivate(obj: Node) -> void:
	_container.add_child(obj)
	if obj is Node3D:
		obj.visible = false
	obj.set_process(false)
	obj.set_physics_process(false)
