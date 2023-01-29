if not bones.has["3d_armor"] then
	return
end

local old_get_inventory = bones.api.get_inventory

function bones.api.get_inventory(player, list_name)
	if list_name == "armor" then
		local _, inv = armor:get_valid_player(player, "[bones]")
		return inv
	else
		return old_get_inventory(player, list_name)
	end
end

local old_clear_inventories_in_bones = bones.api.clear_inventories_in_bones

function bones.api.clear_inventories_in_bones(player)
	old_clear_inventories_in_bones(player)
	armor:save_armor_inventory(player)
	armor:set_player_armor(player)
end
