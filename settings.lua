local s = minetest.settings

bones.settings = {
	share_after = tonumber(s:get("bones.share_after")) or 1200,
	share_after_protected = tonumber(s:get("bones.share_after")),

	mode = s:get("bones.mode") or "bones",
	drop_on_failure = s:get_bool("bones.drop_on_failure", false),

	position_message = s:get_bool("bones.position_message", false),
	staff_position_message = s:get_bool("bones.staff_position_message", false),

	search_distance = tonumber(s:get("bones.search_distance")) or 3,

	lists_to_bones = string.split(s:get("bones.lists_to_bones") or "main,craft,armor"),
}
