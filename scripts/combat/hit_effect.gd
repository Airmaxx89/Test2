extends CPUParticles3D
class_name HitEffect
## Kurzer Treffer-Partikeleffekt (CPUParticles3D -> mobil guenstiger als GPUParticles).
## Poolbar: emittiert einmalig und gibt sich danach an den Pool zurueck.

func _on_pool_acquire() -> void:
	visible = true
	set_process(true)
	restart()
	emitting = true
	# Nach Lebensdauer zurueck in den Pool.
	_schedule_release()

func _schedule_release() -> void:
	await get_tree().create_timer(lifetime + 0.1).timeout
	if is_instance_valid(self):
		PoolManager.release(self)

func _on_pool_release() -> void:
	emitting = false
	set_process(false)
