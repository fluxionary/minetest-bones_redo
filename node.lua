local S = bones.S
local log = bones.log
local api = bones.api

minetest.register_node("bones:bones", {
	description = S("Bones"),
	tiles = {
		"bones_top.png^[transform2",
		"bones_bottom.png",
		"bones_side.png",
		"bones_side.png",
		"bones_rear.png",
		"bones_front.png",
	},
	paramtype2 = "facedir",
	groups = { dig_immediate = 2 },
	is_ground_content = false,
	sounds = bones.resources.sounds.bones,

	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()
		local name = player and player:get_player_name() or ""
		return api.is_owner(pos, name) and inv:is_empty("main")
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if api.is_owner(pos, player:get_player_name()) then
			return stack:get_count()
		end
		return 0
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local player_name = player:get_player_name()
		log("action", "%s takes %s from bones @ %s", player_name, stack:to_string(), minetest.pos_to_string(pos))

		local meta = minetest.get_meta(pos)
		local node_inv = meta:get_inventory()

		if node_inv:is_empty("main") then
			if not (api.is_owner(pos, player_name) and api.is_timed_out(player)) then
				local player_inv = player:get_inventory()
				local remainder = player_inv:add_item("main", { name = "bones:bones" })

				if not remainder:is_empty() then
					minetest.add_item(pos, remainder)
				end
			end

			minetest.remove_node(pos)
		end
	end,

	on_punch = function(pos, node, player)
		local player_name = player:get_player_name()

		if not api.is_owner(pos, player_name) then
			return
		end

		local node_meta = minetest.get_meta(pos)
		local node_inv = node_meta:get_inventory()

		if node_inv:is_empty("main") then
			-- check for a "placed" (not "dropped on death") bones node
			return
		end

		local spos = minetest.pos_to_string(pos)
		local infotext = futil.strip_translation(node_meta:get_string("infotext"))
		local player_inv = player:get_inventory()
		local items_taken = false

		for i = 1, node_inv:get_size("main") do
			local stack = node_inv:get_stack("main", i)
			local remainder = player_inv:add_item("main", stack)

			stack:take_item(remainder:get_count())
			node_inv:set_stack("main", i, remainder)

			if not stack:is_empty() then
				items_taken = true
				log("action", "%s takes %s from %s node @ %s", player_name, stack:to_string(), infotext, spos)
			end
		end

		if items_taken then
			local source = api.get_source(pos)
			if player_name == source then
				bones.chat_send_player(player_name, "you remove items from your bones @@@1", spos)
			elseif source then
				bones.chat_send_player(player_name, "you remove items from @1's bones @@@2", source, spos)
			else
				bones.chat_send_player(player_name, "you remove items from the bones @@@1", spos)
			end
		end

		-- remove bones if player emptied them
		if node_inv:is_empty("main") then
			if not (api.is_owner(pos, player_name) and api.is_timed_out(player)) then
				local remainder = player_inv:add_item("main", { name = "bones:bones" })

				if remainder:is_empty() then
					log("action", "%s gets bones:bones from %s node @ %s", player_name, infotext, spos)
				else
					minetest.add_item(pos, remainder)
					log("action", "bones:bones item dropped @ %s", spos)
				end
			end

			log("action", "removing %s node @ %s", infotext, spos)
			minetest.remove_node(pos)
		end
	end,

	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local time = meta:get_int("time") + elapsed
		local share_after = meta:get_int("share_after")
		if time >= share_after then
			meta:set_string("infotext", S("@1's old bones", meta:get_string("owner")))
			meta:set_string("owner", "")
		else
			meta:set_int("time", time)
			return true
		end
	end,

	on_blast = function(pos, intensity, blaster)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		log("action", "%s's bones at %s blasted, nothing dropped.", owner, minetest.pos_to_string(pos))
	end,
})
