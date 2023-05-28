if not bones.has.i3 then
	return
end

for _, handler in ipairs(bones.settings.disable_inventory_handlers:split()) do
	if handler:trim() == "i3_bags" then
		return
	end
end

i3.settings.drop_bag_on_die = false

assert(
	type(i3.settings.keep_bag_on_die) ~= "nil",
	[[
	Your version of i3 is not compatible with bones_redo.
]]
)

i3.settings.keep_bag_on_die = true
i3.settings.drop_bag_on_die = false

local function get_detached_inv(name, player_name)
	return minetest.get_inventory({
		type = "detached",
		name = string.format("i3_%s_%s", name, player_name),
	})
end

local function get_bag(player_name)
	local data = i3.data[player_name]

	if not data then
		return
	end

	local bag = get_detached_inv("bag", player_name)
	local content = get_detached_inv("bag_content", player_name)

	return data, bag, content
end

bones.api.register_handler("i3_bags", {
	is_empty = function(player)
		local player_name = player:get_player_name()
		local data, bag, _ = get_bag(player_name)
		if not data then
			return
		end
		if bag then
			return bag:is_empty("main")
		else
			return false
		end
	end,
	collect_items = function(player)
		local stacks = {}
		local player_name = player:get_player_name()
		local _, bag, _ = get_bag(player_name)
		if bag then
			local list = bag:get_list("main")

			for _, item in ipairs(list) do
				if not item:is_empty() then
					stacks[#stacks] = item
				end
			end
		end
		return stacks
	end,
	empty_inventories = function(player)
		local player_name = player:get_player_name()
		local data, bag, content = get_bag(player_name)
		if not data then
			return
		end
		data.bag = nil
		if bag then
			bag:set_list("main", {})
		end
		if content then
			content:set_list("main", {})
		end
	end,
	post_action = function(player)
		i3.set_fs(player)
	end,
})
