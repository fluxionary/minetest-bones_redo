local private_state = ...
local mod_storage = private_state.mod_storage

local f = string.format

local log = bones.log
local S = bones.S
local settings = bones.settings
local util = bones.util

local can_see = util.can_see
local drop = util.drop
local send_to_staff = util.send_to_staff

local iterate_volume = futil.iterate_volume
local is_inside_world_bounds = futil.is_inside_world_bounds

local share_after = settings.share_after
local share_after_protected = settings.share_after_protected or share_after * 3 / 4
local player_position_message = settings.position_message
local staff_position_message = settings.staff_position_message
local ground_search_distance = settings.ground_search_distance
local bone_node_timeout = settings.bone_node_timeout
local bones_mode = settings.mode
local mode_protected = settings.mode_protected

local disabled_handlers = {}
for _, handler in ipairs(bones.settings.disable_inventory_handlers:split()) do
	disabled_handlers[handler:trim()] = true
end

local y1 = vector.new(0, 1, 0)

bones.enable_bones = true

local function last_death_key(player_name)
	return f("%s's last death", player_name)
end

local api = {}

function api.toggle_enabled()
	bones.enable_bones = not bones.enable_bones
end

bones.inventory_handlers = {}

function api.register_inventory_handler(name, def)
	if not disabled_handlers[name] then
		bones.inventory_handlers[name] = def
	end
end

function api.are_inventories_empty(player)
	if not futil.is_player(player) then
		return true
	end

	for _, def in pairs(bones.inventory_handlers) do
		if def.is_empty and not def.is_empty(player) then
			return false
		end
	end

	return true
end

function api.collect_stacks_for_bones(player)
	local stacks = {}

	for _, def in pairs(bones.inventory_handlers) do
		if def.collect_stacks then
			table.insert_all(stacks, def.collect_stacks(player))
		end
	end

	return stacks
end

function api.clear_inventories_in_bones(player)
	for _, def in pairs(bones.inventory_handlers) do
		if def.clear_inventory then
			def.clear_inventory(player)
		end
	end
end

function api.post_action(player)
	for _, def in pairs(bones.inventory_handlers) do
		if def.post_action then
			def.post_action(player)
		end
	end
end

--[[
"source" is the player who dropped the bones. tracked separately, because "owner" is removed when bones age.
]]
function api.get_source(pos)
	local meta = minetest.get_meta(pos)
	local source = meta:get("source") or meta:get("owner")
	if source then
		return source
	end
	-- hax
	local infotext = meta:get("infotext")
	if infotext then
		infotext = futil.strip_translation(infotext)
		source = infotext:match("^(.*)'s ")
		return source
	end
end

function api.get_owner(pos)
	return minetest.get_meta(pos):get("owner")
end

function api.is_owner(pos, name)
	local player = minetest.get_player_by_name(name)

	if not player or player:get_hp() == 0 then
		return false
	end

	local owner = api.get_owner(pos)

	return (not owner) or owner == name or minetest.check_player_privs(name, "protection_bypass")
end

function api.may_replace(pos, player)
	if not is_inside_world_bounds(pos) then
		return false
	end

	local node_name = minetest.get_node(pos).name
	local node_definition = minetest.registered_nodes[node_name]

	-- if the node is unknown, we return false
	if not node_definition or node_name == "ignore" then
		return false
	end

	-- allow replacing air and flowing liquid
	if node_name == "air" or node_definition.liquidtype == "flowing" then
		return true
	end

	-- don't replace most nodes inside protections
	if minetest.is_protected(pos, player:get_player_name()) then
		return false
	end

	-- allow replacing unprotected sources
	if node_definition.liquidtype == "source" then
		return true
	end

	-- don't replace filled chests and other nodes that don't allow it
	local can_dig_func = node_definition.can_dig
	if can_dig_func and not can_dig_func(pos, player) then
		return false
	end

	-- default to each nodes buildable_to; if a placed block would replace it, why shouldn't bones?
	-- flowers being squished by bones are more realistical than a squished stone, too
	return node_definition.buildable_to
end

function api.find_place_for_bones(player, death_pos, radius)
	local possible_bones_pos = {}

	for pos in iterate_volume(death_pos, radius) do
		if api.may_replace(pos, player) then
			local pos_below = vector.subtract(pos, y1)
			table.insert(possible_bones_pos, {
				pos = pos,
				dist = vector.distance(death_pos, pos),
				-- if we can place the bones lower, then we prefer to do that
				can_place_below = api.may_replace(pos_below, player),
			})
		end
	end

	if #possible_bones_pos == 0 then
		return
	end

	table.sort(possible_bones_pos, function(k1, k2)
		if k1.can_place_below and not k2.can_place_below then
			return false
		elseif not k1.can_place_below and k2.can_place_below then
			return true
		end

		return k1.dist < k2.dist
	end)

	for _, pos in ipairs(possible_bones_pos) do
		if can_see(death_pos, pos.pos) then
			return pos.pos
		end
	end

	local possible_pos = possible_bones_pos[1]
	if possible_pos then
		return possible_pos.pos
	end
end

function api.place_bones_node(player, bones_pos, stacks_for_bones)
	if not api.may_replace(bones_pos, player) then
		return false
	end

	local player_name = player:get_player_name()

	minetest.set_node(bones_pos, {
		name = "bones:bones",
		param2 = minetest.dir_to_facedir(player:get_look_dir()),
	})

	local node_meta = minetest.get_meta(bones_pos)
	local node_inv = node_meta:get_inventory()
	node_inv:set_size("main", #stacks_for_bones)

	local pos_string = minetest.pos_to_string(bones_pos)

	for _, stack in ipairs(stacks_for_bones) do
		local remainder = node_inv:add_item("main", stack)
		if remainder:is_empty() then
			log("action", "%s added %s to bones @ %s", player_name, stack, pos_string)
		else
			drop(remainder, player, bones_pos)
		end
	end

	node_meta:set_string("formspec", bones.formspec.node_spec)
	node_meta:set_string("owner", player_name)
	node_meta:set_string("source", player_name)

	if minetest.is_protected(bones_pos, player_name) and share_after_protected > 0 then
		node_meta:set_string("infotext", S("@1's fresh bones", player_name))
		node_meta:set_int("share_after", os.time() + share_after_protected)
		minetest.get_node_timer(bones_pos):start(share_after_protected)
	elseif share_after > 0 then
		node_meta:set_string("infotext", S("@1's fresh bones", player_name))
		node_meta:set_int("share_after", os.time() + share_after)
		minetest.get_node_timer(bones_pos):start(share_after)
	else
		node_meta:set_string("infotext", S("@1's bones", player_name))
	end

	api.clear_inventories_in_bones(player)
	api.post_action(player)

	return true
end

function api.place_bones_entity(player, death_pos, stacks_for_bones)
	local player_name = player:get_player_name()
	local serialized_inv = minetest.write_json(stacks_for_bones)

	if not serialized_inv then
		error("error serializing stacks?")
	end

	local becomes_old
	local old = false
	if minetest.is_protected(death_pos, player_name) and share_after_protected > 0 then
		becomes_old = minetest.get_us_time() + (share_after_protected * 1e6)
	elseif share_after > 0 then
		becomes_old = minetest.get_us_time() + (share_after * 1e6)
	else
		old = true
	end

	local data = {
		becomes_old = becomes_old,
		owner = player_name,
		old = old,
		serialized_inv = serialized_inv,
	}

	local obj = minetest.add_entity(death_pos, "bones:bones", minetest.write_json(data))

	if obj then
		for _, stack in ipairs(stacks_for_bones) do
			log("action", "%s added %s to bones entity @ %s", player_name, stack, minetest.pos_to_string(death_pos))
		end

		api.clear_inventories_in_bones(player)
		api.post_action(player)

		return true
	end

	return false
end

function api.drop_inventory(player, death_pos)
	for _, stack in ipairs(api.collect_stacks_for_bones(player)) do
		drop(stack, player, death_pos)
	end

	api.clear_inventories_in_bones(player)

	drop(ItemStack("bones:bones"), player, death_pos)
end

function api.get_death_pos(player)
	local death_pos = vector.round(player:get_pos())
	local pos_below = vector.subtract(death_pos, y1)
	local count = 0
	while true do
		count = count + 1

		if count >= ground_search_distance or not api.may_replace(pos_below, player) then
			return death_pos
		end

		death_pos.y = death_pos.y - 1
		pos_below.y = pos_below.y - 1
	end
end

api.death_cache = {}
api.timeouts_by_name = {}

function api.record_death(player_name, pos, mode)
	local pos_string = minetest.pos_to_string(pos)

	local death_cache = api.death_cache[player_name] or {}
	table.insert(death_cache, { pos, mode })
	api.death_cache[player_name] = death_cache

	mod_storage:set_string(last_death_key(player_name), pos_string)

	if not api.timeouts_by_name[player_name] then
		api.timeouts_by_name[player_name] = (minetest.get_us_time() / 1e6) + bone_node_timeout
	end

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

	log("action", text)

	if player_position_message then
		minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
	end

	if staff_position_message then
		send_to_staff(text)
	end
end

--if a player is timed out, they can't get another bones node from their own bones
function api.is_timed_out(player)
	local player_name = player:get_player_name()
	local timeout = api.timeouts_by_name[player_name]

	if not timeout then
		return false
	end

	local now = minetest.get_us_time() / 1e6

	if now > timeout then
		api.timeouts_by_name[player_name] = nil
		return false
	end

	return true
end

function api.get_last_death_pos(player_name)
	local pos_string = mod_storage:get(last_death_key(player_name))
	if pos_string then
		return minetest.string_to_pos(pos_string)
	end
end

function api.get_mode_for_player(player_name, death_pos)
	if not bones.enable_bones then
		return "keep"
	elseif minetest.is_creative_enabled(player_name) then
		return "keep"
	elseif minetest.is_protected(death_pos, player_name) then
		return mode_protected
	else
		return bones_mode
	end
end

bones.api = api
