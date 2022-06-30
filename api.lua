local api = {}

local S = bones.S
local has = bones.has
local settings = bones.settings
local util = bones.util

local can_see = util.can_see
local drop = util.drop
local get_armor_inv = util.get_armor_inv
local iterate_volume = util.iterate_volume

local lists_to_bones = settings.lists_to_bones
local share_after = settings.share_after
local share_after_protected = settings.share_after_protected or share_after * (3/4)

bones.enable_bones = true

function api.toggle_enabled()
	bones.enable_bones = not bones.enable_bones
end

function api.is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")

	return owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass")
end

function api.may_replace(pos, player)
	local node_name = minetest.get_node(pos).name
	local node_definition = minetest.registered_nodes[node_name]

	-- if the node is unknown, we return false
	if not node_definition then
		return false
	end

	-- allow replacing air
	if node_name == "air" then
		return true
	end

	-- don't replace non-nodes inside protections
	if minetest.is_protected(pos, player:get_player_name()) then
		return false
	end

	-- allow replacing liquids
	if node_definition.liquidtype ~= "none" then
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

function api.find_good_pos(player, death_pos, radius)
	local possible_bones_pos = {}

	for pos in iterate_volume(death_pos, radius) do
		if api.may_replace(pos, player) then
			table.insert(possible_bones_pos, {pos = pos, dist = vector.distance(death_pos, pos)})
		end
	end

	table.sort(possible_bones_pos, function(k1, k2)
		return k1.dist < k2.dist
	end)

	for _, pos in ipairs(possible_bones_pos) do
		if can_see(death_pos, pos.pos) then
			return pos.pos
		end
	end

	return possible_bones_pos[1]
end

-- also clears inventories
local function get_stacks_for_bones(player)
	local player_inv = player:get_inventory()
	local player_name = player:get_player_name()

	local stacks = {}
	for _, list_name in ipairs(lists_to_bones) do
		local inv
		if list_name == "armor" then
			inv = get_armor_inv(player_name)
		else
			inv = player_inv
		end

		for _, stack in ipairs(inv:get_list(list_name)) do
			if not stack:is_empty() then
				table.insert(stacks, stack:to_string())
			end
		end

		inv:set_list(list_name, {})

		if list_name == "armor" then
			if has.armor_3d then
				armor:save_armor_inventory(player)
				armor:set_player_armor(player)
			end
		end
	end

	return stacks
end


function api.place_bones_node(player, bones_pos)
	local player_name = player:get_player_name()

	local stacks_for_bones = get_stacks_for_bones(player)

	minetest.set_node(bones_pos, {
		name = "bones:bones",
		param2 = minetest.dir_to_facedir(player:get_look_dir())}
	)

	local node_meta = minetest.get_meta(bones_pos)
	local node_inv = node_meta:get_inventory()
	node_inv:set_size("main", #stacks_for_bones + 1)

	local pos_string = minetest.pos_to_string(bones_pos)

	for _, stack in ipairs(stacks_for_bones) do
		local remainder = node_inv:add_item("main", stack)
		if remainder:is_empty() then
			bones.log("action", "%s added %s to bones @ %s", player_name, stack:to_string(), pos_string)
		else
			drop(remainder, player, bones_pos)
		end
	end

	node_meta:set_string("formspec", bones.formspec.node_spec)
	node_meta:set_string("owner", player_name)

	if minetest.is_protected(bones_pos, player_name) and share_after_protected > 0 then
		node_meta:set_string("infotext", S("@1's fresh bones", player_name))
		node_meta:set_int("time", 0)
		minetest.get_node_timer(bones_pos):start(share_after_protected)

	elseif share_after > 0 then
		node_meta:set_string("infotext", S("@1's fresh bones", player_name))
		node_meta:set_int("time", 0)
		minetest.get_node_timer(bones_pos):start(share_after)

	else
		node_meta:set_string("infotext", S("@1's bones", player_name))
	end

	return true
end

function api.place_bones_entity(player, death_pos)
	local player_name = player:get_player_name()

	local stacks_for_bones = get_stacks_for_bones(player)
	local serialized_inv = minetest.write_json(stacks_for_bones)

	if not serialized_inv then
		error(("error serializing stacks?"))
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
		serialized_inv = serialized_inv
	}

	local obj = minetest.add_entity(death_pos, "bones:bones", minetest.write_json(data))

	if obj then
		for _, stack in ipairs(stacks_for_bones) do
			bones.log("action", "%s added %s to bones entity @ %s", player_name, stack, minetest.pos_to_string(death_pos))
		end

		return true
	end

	return false
end

function api.drop_inventory(player, death_pos)
	for _, stack in ipairs(get_stacks_for_bones(player)) do
		drop(stack, player, death_pos)
	end

	drop(ItemStack("bones:bones"), player, death_pos)
end

bones.api = api
