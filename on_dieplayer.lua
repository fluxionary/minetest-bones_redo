local api = bones.api
local settings = bones.settings
local util = bones.util

local S = bones.S

local are_inventories_empty = util.are_inventories_empty
local send_to_staff = util.send_to_staff

local bones_mode = settings.mode
local drop_on_failure= settings.drop_on_failure
local player_position_message = settings.position_message
local staff_position_message = settings.staff_position_message
local search_distance = settings.search_distance

local function player_dies(player_name, pos_string, mode)
    local text = player_name .. " dies at " .. pos_string

    if mode == "keep" then
        text = text .. " and keeps their inventory."
    elseif mode == "drop" then
        text = text .. " and drops their inventory."
    elseif mode == "bones" then
        text = text .. " and their inventory goes to bones."
    elseif mode == "none" then
        text = text .. " and doesn't have any inventory to be dropped."
    end

	bones.log("action", text)

	if player_position_message then
		minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
	end

	if staff_position_message then
        send_to_staff(text)
	end
end

minetest.register_on_dieplayer(function(player)
	local player_name = player:get_player_name()
	local death_pos = vector.round(player:get_pos())
	local pos_string = minetest.pos_to_string(death_pos)

	-- return if keep inventory set or in creative mode
	if not bones.enable_bones or bones_mode == "keep" or minetest.is_creative_enabled(player_name) then
		player_dies(player_name, pos_string, "keep")
		return
	end

	if are_inventories_empty(player) then
		player_dies(player_name, pos_string, "none")
		return
	end

	-- check if it's possible to place bones, if not find space near player
	if bones_mode == "bones" then
		local bones_pos = api.find_good_pos(player, death_pos, search_distance)
		local success
		if bones_pos then
			success = api.place_bones_node(player, bones_pos)
		else
			success = api.place_bones_entity(player, death_pos)
		end

		if success then
			player_dies(player_name, pos_string, "bones")
			return
		end
	end

	if drop_on_failure or bones_mode == "drop" then
		api.drop_inventory(player, death_pos)
		player_dies(player_name, pos_string, "drop")
		return
	end

	player_dies(player_name, pos_string, "keep")
end)
