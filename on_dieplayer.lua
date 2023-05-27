local log = bones.log
local api = bones.api
local settings = bones.settings

local keep_on_failure = settings.keep_on_failure
local search_distance = settings.search_distance

function api.on_dieplayer(player)
	if not minetest.is_player(player) then
		log("error", "non-player died: %q", dump(player))
		return
	end

	local player_name = player:get_player_name()

	if not player_name or player_name == "" then
		log("error", "player has no name? %q", dump(player))
		return
	end

	if not player:get_pos() then
		log("error", "player has no position? %q", dump(player))
		return
	end

	local death_pos = api.get_death_pos(player)
	local mode = api.get_mode_for_player(player_name, death_pos)

	if mode == "keep" then
		api.record_death(player_name, death_pos, "keep")
		return
	end

	if api.are_inventories_empty(player) then
		api.record_death(player_name, death_pos, "none")
		return
	end

	if mode == "bones" then
		local bones_pos = api.find_place_for_bones(player, death_pos, search_distance)
		local stacks_for_bones = api.collect_stacks_for_bones(player)
		local success

		if bones_pos then
			success = api.place_bones_node(player, bones_pos, stacks_for_bones)
		end

		if not success then
			success = api.place_bones_entity(player, death_pos, stacks_for_bones)
		end

		if success then
			api.record_death(player_name, bones_pos or death_pos, "bones")
			return
		end
	end

	if not keep_on_failure or mode == "drop" then
		api.drop_inventory(player, death_pos)
		api.record_death(player_name, death_pos, "drop")
		return
	end

	api.record_death(player_name, death_pos, "keep")
end

minetest.register_on_dieplayer(function(player)
	return api.on_dieplayer(player)
end)
