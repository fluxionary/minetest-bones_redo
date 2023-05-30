local lists_to_bones = bones.settings.lists_to_bones:split()

bones.api.register_inventory_handler("player_inventory_lists", {
	is_empty = function(player)
		local inv = player:get_inventory()

		for _, listname in ipairs(lists_to_bones) do
			if not inv:is_empty(listname) then
				return false
			end
		end

		return true
	end,
	collect_stacks = function(player)
		local stacks = {}
		local inv = player:get_inventory()
		for _, listname in ipairs(lists_to_bones) do
			local list = inv:get_list(listname) or {}

			for _, item in ipairs(list) do
				if not item:is_empty() then
					stacks[#stacks + 1] = item
				end
			end
		end
		return stacks
	end,
	clear_inventory = function(player)
		local inv = player:get_inventory()

		for _, listname in ipairs(lists_to_bones) do
			inv:set_list(listname, {})
		end
	end,
})
