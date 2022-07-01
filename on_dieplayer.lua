local api = bones.api
local settings = bones.settings
local util = bones.util

local are_inventories_empty = util.are_inventories_empty

local bones_mode = settings.mode
local drop_on_failure= settings.drop_on_failure
local search_distance = settings.search_distance

function api.on_dieplayer(player)
	local player_name = player:get_player_name()
	local death_pos = api.get_death_pos(player)

	if not bones.enable_bones or bones_mode == "keep" or minetest.is_creative_enabled(player_name) then
		api.record_death(player_name, death_pos, "keep")
		return
	end

	if are_inventories_empty(player) then
		api.record_death(player_name, death_pos, "none")
		return
	end

	if bones_mode == "bones" then
		local bones_pos = api.find_place_for_bones(player, death_pos, search_distance)
		local success
		if bones_pos then
			success = api.place_bones_node(player, bones_pos)
		else
			success = api.place_bones_entity(player, death_pos)
		end

		if success then
			api.record_death(player_name, bones_pos or death_pos, "bones")
			return
		end
	end

	if drop_on_failure or bones_mode == "drop" then
		api.drop_inventory(player, death_pos)
		api.record_death(player_name, death_pos, "drop")
		return
	end

	api.record_death(player_name, death_pos, "keep")
end

minetest.register_on_dieplayer(function(player)
	return api.on_dieplayer(player)
end)
