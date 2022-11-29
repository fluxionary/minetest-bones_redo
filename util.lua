local log = bones.log

local util = {}

local lists_to_bones = bones.settings.lists_to_bones:split()
local staff_priv = bones.settings.staff_priv

function util.drop(itemstack, dropper, pos)
	if itemstack:is_empty() then
		return
	end

	minetest.item_drop(itemstack, dropper, pos)

	log("action", "%s dropped %s at %s", dropper:get_player_name(), itemstack:to_string(), minetest.pos_to_string(pos))
end

function util.get_armor_inv(player_name)
	local armor_inv = minetest.get_inventory({ type = "detached", name = player_name .. "_armor" })
	if armor_inv then
		return armor_inv
	end

	local player = minetest.get_player_by_name(player_name)
	if player then
		return player:get_inventory()
	end
end

function util.has_armor(player_name)
	local armor_inv = util.get_armor_inv(player_name)
	if not armor_inv or armor_inv:is_empty("armor") then
		return false
	end
	return true
end

function util.can_see(pos1, pos2)
	pos1 = vector.add(pos1, 0.001)
	-- Can we see from pos1 to pos2 ?
	local ray = minetest.raycast(pos1, pos2, false, false)
	local element = ray:next()
	while element do
		if element.type == "node" and minetest.get_node(element.under).name ~= "air" then
			return false
		end
		element = ray:next()
	end
	return true
end

function util.are_inventories_empty(player)
	if not minetest.is_player(player) then
		return true
	end

	local player_inv = player:get_inventory()
	local player_name = player:get_player_name()

	for _, list_name in ipairs(lists_to_bones) do
		local inv
		if list_name == "armor" then
			inv = util.get_armor_inv(player_name)
		else
			inv = player_inv
		end

		if not inv:is_empty(list_name) then
			return false
		end
	end

	return true
end

function util.send_to_staff(text)
	local message = minetest.colorize("#98ff98", "[STAFF] " .. text)
	for _, player in ipairs(minetest.get_connected_players()) do
		if minetest.is_player(player) and minetest.check_player_privs(player, staff_priv) then
			local name = player:get_player_name()
			minetest.chat_send_player(name, message)
		end
	end
end

bones.util = util
