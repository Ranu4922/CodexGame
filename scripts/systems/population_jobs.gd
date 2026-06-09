extends RefCounted


static func create_resident(resident_id: int) -> Dictionary:
	return {"id": resident_id, "job": "", "workplace_key": ""}


static func count_job(residents: Array, job_name: String) -> int:
	var count: int = 0
	for resident_value in residents:
		var resident_data: Dictionary = resident_value as Dictionary
		if String(resident_data["job"]) == job_name:
			count += 1
	return count


static func find_next_free_resident_id(residents: Array) -> int:
	for resident_value in residents:
		var resident_data: Dictionary = resident_value as Dictionary
		if String(resident_data["job"]).is_empty():
			return int(resident_data["id"])
	return 0
