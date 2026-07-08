extends Node
## Bridge between NPCs (created inside World, spawned late) and the
## Dialogue UI (created inside HUD/Main independently of the world).

signal npc_interacted(npc_id: String, npc_name: String)


func trigger(npc_id: String, npc_name: String) -> void:
	npc_interacted.emit(npc_id, npc_name)
