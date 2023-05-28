if not bones.has.unified_inventory then
	return
end

local function get_bag_inv(player)
	return minetest.get_inventory({
		type = "detached",
		name = player:get_player_name() .. "_bags",
	})
end

local function save_bags_metadata(player, bags_inv)
	local is_empty = true
	local bags = {}
	for i = 1, 4 do
		local bag = "bag" .. i
		if not bags_inv:is_empty(bag) then
			-- Stack limit is 1, otherwise use stack:to_string()
			bags[i] = bags_inv:get_stack(bag, 1):get_name()
			is_empty = false
		end
	end
	local meta = player:get_meta()
	if is_empty then
		meta:set_string("unified_inventory:bags", nil)
	else
		meta:set_string("unified_inventory:bags", minetest.serialize(bags))
	end
end

bones.api.register_inventory_handler("unified_inventory_bags", {
	is_empty = function(player)
		local bag_inv = get_bag_inv(player)
		if not bag_inv then
			return true
		end
		for i = 1, 4 do
			if not bag_inv:is_empty("bag" .. i) then
				return false
			end
		end
		return true
	end,
	collect_stacks = function(player)
		local stacks = {}
		local bag_inv = get_bag_inv(player)
		if not bag_inv then
			return stacks
		end
		local player_inv = player:get_inventory()
		for i = 1, 4 do
			local listname = "bag" .. i
			local bagstack = bag_inv:get_stack(listname, 1)
			if not bagstack:is_empty() then
				stacks[#stacks + 1] = bagstack
				for _, stack in ipairs(player_inv:get_list(listname .. "contents")) do
					if not stack:is_empty() then
						stacks[#stacks + 1] = stack
					end
				end
			end
		end
		return stacks
	end,
	clear_inventory = function(player)
		local bag_inv = get_bag_inv(player)
		if not bag_inv then
			return
		end
		local player_inv = player:get_inventory()
		for i = 1, 4 do
			local listname = "bag" .. i
			local bagstack = bag_inv:get_stack(listname, 1)
			if not bagstack:is_empty() then
				player_inv:set_list(listname .. "contents", {})
				player_inv:set_size(listname .. "contents", 0)
				bag_inv:set_stack(listname, 1, "")
			end
		end
	end,
	post_action = function(player)
		local bag_inv = get_bag_inv(player)
		if not bag_inv then
			return
		end
		save_bags_metadata(player, bag_inv)
	end,
})
