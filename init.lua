-- bones/init.lua

-- Minetest 0.4 mod: bones
-- See README.txt for licensing and other information.

local mod_start_time = core.get_us_time()
core.log("action", "[MOD] bones loading")

-- Load support for MT game translation.
local S = minetest.get_translator("bones")

bones = {}

local enable_bones = true

local function is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
	if owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass") then
		return true
	end
	return false
end

local bones_formspec =
	"size[8,10.5]" ..
	"list[current_name;main;0,0.3;8,6;]" ..
	"list[current_player;main;0,6.45;8,1;]" ..
	"list[current_player;main;0,7.58;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,6.45)

local share_bones_time = tonumber(minetest.settings:get("share_bones_time")) or 1200
local share_bones_time_early = tonumber(minetest.settings:get("share_bones_time_early")) or share_bones_time / 4

minetest.register_node("bones:bones", {
	description = S("Bones"),
	tiles = {
		"bones_top.png^[transform2",
		"bones_bottom.png",
		"bones_side.png",
		"bones_side.png",
		"bones_rear.png",
		"bones_front.png"
	},
	paramtype2 = "facedir",
	groups = {dig_immediate = 2},
	sounds = default.node_sound_gravel_defaults(),

	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()
		local name = ""
		if player then
			name = player:get_player_name()
		end
		return is_owner(pos, name) and inv:is_empty("main")
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if is_owner(pos, player:get_player_name()) then
			return count
		end
		return 0
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if is_owner(pos, player:get_player_name()) then
			return stack:get_count()
		end
		return 0
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		core.log("action", "[Bones] " .. player:get_player_name() ..
			" takes " .. stack:to_string() .. 
			" from bones at " .. core.pos_to_string(pos))
		if meta:get_inventory():is_empty("main") then
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name = "bones:bones"}) then
				inv:add_item("main", {name = "bones:bones"})
			else
				minetest.add_item(pos, "bones:bones")
			end
			minetest.remove_node(pos)
		end
	end,

	on_punch = function(pos, node, player)
		if not is_owner(pos, player:get_player_name()) then
			return
		end
		
		if minetest.get_meta(pos):get_string("infotext") == "" then
			return
		end

		local inv = minetest.get_meta(pos):get_inventory()
		local player_inv = player:get_inventory()
		local has_space = true

		for i = 1, inv:get_size("main") do
			local stk = inv:get_stack("main", i)
			if player_inv:room_for_item("main", stk) then
				inv:set_stack("main", i, nil)
				local stk_name = stk:get_name()
				if stk_name ~= "" then
					core.log("action", "[Bones] " .. player:get_player_name() ..
						" takes " .. stk:to_string() ..
						" from bones at " .. core.pos_to_string(pos))
				end
				player_inv:add_item("main", stk)
			else
				has_space = false
				break
			end
		end

		-- remove bones if player emptied them
		if has_space then
			if player_inv:room_for_item("main", {name = "bones:bones"}) then
				player_inv:add_item("main", {name = "bones:bones"})
			else
				minetest.add_item(pos,"bones:bones")
			end
			minetest.remove_node(pos)
		end
	end,

	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local time = meta:get_int("time") + elapsed
		if time >= share_bones_time then
			meta:set_string("infotext", S("@1's old bones", meta:get_string("owner")))
			meta:set_string("owner", "")
		else
			meta:set_int("time", time)
			return true
		end
	end,
	on_blast = function(pos)
		core.log("action", "[Bones] " .. "Bones at " .. core.pos_to_string(pos) .. " blasted.")
	end,
})

local function may_replace(pos, player)
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

	-- don't replace nodes inside protections
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

local drop = function(pos, itemstack)
	local stk_name = itemstack:get_name()
	if stk_name ~= "" then
		core.log("action","[Bones] " .. "Item " .. itemstack:to_string() .. " dropped at pos " .. core.pos_to_string(pos))
	end
	local obj = minetest.add_item(pos, itemstack:take_item(itemstack:get_count()))
	if obj then
		obj:set_velocity({
			x = math.random(-10, 10) / 9,
			y = 5,
			z = math.random(-10, 10) / 9,
		})
	end
end

local player_inventory_lists = { "main", "craft" }
bones.player_inventory_lists = player_inventory_lists
 
local function is_all_empty(player_inv)
	for _, list_name in ipairs(player_inventory_lists) do
		if not player_inv:is_empty(list_name) then
			return false
		end
	end
	return true
end

local function has_armor(player_name)
	local armor_inv = minetest.get_inventory({type="detached", name=player_name.."_armor"})
	if not armor_inv or armor_inv:is_empty("armor") then
		return false
	end
	return true
end

local function can_see(pos1,pos2)
	pos1 = {
		x= pos1.x + 0.001,
		y= pos1.y + 0.001,
		z= pos1.z + 0.001

	}
	-- Can we see from pos1 to pos2 ?
	local ray = minetest.raycast(pos1, pos2, false, false)
	local element = ray:next()
	while element do
		if element.type == "node" and core.get_node(element.under).name ~= "air" then
			return false
		end
		element = ray:next()
	end
	return true
end

local function find_good_pos(death_pos, air_pos_list)
	-- The air_pos_list comes in a list of air positions around the death pos.
	-- The closer to the death pos, the better
	-- but we shall only select it as a valid position, if we can see it.
	local t = {}
	for _,airpos in ipairs(air_pos_list) do
		local dist = vector.distance(death_pos,airpos)
		table.insert(t,{dist = dist, x = airpos.x,y = airpos.y,z = airpos.z})
	end
	table.sort(t, function (k1, k2) return k1.dist < k2.dist end )
	for _,closepos in ipairs(t) do
		if can_see(death_pos,closepos) then
			return {x = closepos.x, y = closepos.y, z = closepos.z}
		end
	end
	return nil
end

minetest.register_on_dieplayer(function(player)

	local bones_mode = minetest.settings:get("bones_mode") or "bones"
	if bones_mode ~= "bones" and bones_mode ~= "drop" and bones_mode ~= "keep" then
		bones_mode = "bones"
	end

	local bones_position_message = minetest.settings:get_bool("bones_position_message") == true
	local staff_position_message = minetest.settings:get_bool("staff_position_message") == true
	local player_name = player:get_player_name()
	local pos = vector.round(player:get_pos())
	local pos_string = minetest.pos_to_string(pos)

	-- We don't drop bones at all
	if enable_bones == false then 
		if staff_position_message and yl_commons and yl_commons.player_dies then
			yl_commons.player_dies(player_name,pos_string,"keep")
		end
		return
	end

	-- return if keep inventory set or in creative mode
	if bones_mode == "keep" or minetest.is_creative_enabled(player_name) then
		minetest.log("action", "[Bones] " .. player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		if staff_position_message and yl_commons and yl_commons.player_dies then
			yl_commons.player_dies(player_name,pos_string,"keep")
		end
		return
	end

	local player_inv = player:get_inventory()
	if is_all_empty(player_inv) and not has_armor(player_name) then
		minetest.log("action", "[Bones] " .. player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		if staff_position_message and yl_commons and yl_commons.player_dies then
			yl_commons.player_dies(player_name,pos_string,"none")
		end
		return
	end

	-- check if it's possible to place bones, if not find space near player
	if bones_mode == "bones" and not may_replace(pos, player) then
		local distance = 3
		local pos1 ={x=pos.x-distance,y=pos.y-distance,z=pos.z-distance}
		local pos2 ={x=pos.x+distance,y=pos.y+distance,z=pos.z+distance}
		local air_pos_list = minetest.find_nodes_in_area(pos1, pos2, {"air"}, true)
		if not air_pos_list or not air_pos_list.air then
			bones_mode = "drop"
		else
			local good_pos = find_good_pos(pos, air_pos_list.air)
			
			if good_pos and not minetest.is_protected(good_pos, player_name) then
				pos = good_pos
			else
				bones_mode = "drop"
			end
		end
	end

	if bones_mode == "drop" then
		for _, list_name in ipairs(player_inventory_lists) do
			for i = 1, player_inv:get_size(list_name) do
				drop(pos, player_inv:get_stack(list_name, i))
			end
			player_inv:set_list(list_name, {})
		end
		if has_armor(player_name) then
			local armor_inv = minetest.get_inventory({type="detached", name=player_name.."_armor"})
			for i = 1, armor_inv:get_size("armor") do
				drop(pos, armor_inv:get_stack("armor", i))
			end
			armor_inv:set_list("armor", {})
			armor:save_armor_inventory(player)
			armor:set_player_armor(player)
		end
		drop(pos, ItemStack("bones:bones"))
		minetest.log("action", "[Bones] " .. player_name .. " dies at " .. pos_string ..
			". Inventory dropped")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2, and dropped their inventory.", player_name, pos_string))
		end
		if staff_position_message and yl_commons and yl_commons.player_dies then
			yl_commons.player_dies(player_name,pos_string,"drop")
		end
		return
	end

	local param2 = minetest.dir_to_facedir(player:get_look_dir())
	minetest.set_node(pos, {name = "bones:bones", param2 = param2})

	minetest.log("action", "[Bones] " .. player_name .. " dies at " .. pos_string ..
		". Bones placed")
	if bones_position_message then
		minetest.chat_send_player(player_name, S("@1 died at @2, and bones were placed.", player_name, pos_string))
	end
	if staff_position_message and yl_commons and yl_commons.player_dies then
		yl_commons.player_dies(player_name,pos_string,"bones")
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("main", 8 * 6)

	-- main and crafting grid
	for _, list_name in ipairs(player_inventory_lists) do
		for i = 1, player_inv:get_size(list_name) do
			local stack = player_inv:get_stack(list_name, i)
			if inv:room_for_item("main", stack) then
				local stk_name = stack:get_name()
				if stk_name ~= "" then
					core.log("action","[Bones] " .. "Item " .. stack:to_string() .. " added to bones at pos " .. core.pos_to_string(pos))
				end
				inv:add_item("main", stack)
			else -- no space left
				drop(pos, stack)
			end
		end
		player_inv:set_list(list_name, {})
	end

	-- armor
	local armor_list_name = player_name.."_armor"
	local armor_inv = minetest.get_inventory({type="detached", name=armor_list_name})
	for i = 1, armor_inv:get_size("armor") do
		local stack = armor_inv:get_stack("armor", i)
		if inv:room_for_item("main", stack) then
			local stk_name = stack:get_name()
			if stk_name ~= "" then
				core.log("action","[Bones] " .. "Armor " .. stack:to_string() .. " added to bones at pos " .. core.pos_to_string(pos))
			end
			inv:add_item("main", stack)
		else -- no space left
			drop(pos, stack)
		end
	end
	armor_inv:set_list("armor", {})
	armor:save_armor_inventory(player)
	armor:set_player_armor(player)

	meta:set_string("formspec", bones_formspec)
	meta:set_string("owner", player_name)

	if share_bones_time ~= 0 then
		meta:set_string("infotext", S("@1's fresh bones", player_name))

		if share_bones_time_early == 0 or not minetest.is_protected(pos, player_name) then
			meta:set_int("time", 0)
		else
			meta:set_int("time", (share_bones_time - share_bones_time_early))
		end

		minetest.get_node_timer(pos):start(10)
	else
		meta:set_string("infotext", S("@1's bones", player_name))
	end
end)

-- Chatcommand to toggle between "keep all inventory" and "let inv either drop or go to bones".

local chatcommand_cmd = "bones_toggle"
local chatcommand_definition = {
    params = "", -- Short parameter description
    description = "Chatcommand to toggle between 'keep all inventory' and 'let inv either drop or go to bones'.", -- Full description
    privs = {staff = true}, -- Require the "privs" privilege to run
    func = function(name, param)

		if enable_bones == false or enable_bones == nil then
			enable_bones = true
			return true, "Bones will drop or go to a bones block"
		else
			enable_bones = false
			return true, "Bones will stay with the player"
		end
		return false, "Something went wrong"
    end
}

minetest.register_chatcommand(chatcommand_cmd, chatcommand_definition)

local mod_end_time = (core.get_us_time() - mod_start_time) / 1000000
core.log("action", "[MOD] bones loaded in [" .. mod_end_time .. "s]")
