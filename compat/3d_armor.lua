if not bones.has["3d_armor"] then
	return
end

for _, handler in ipairs(bones.settings.disable_inventory_handlers:split()) do
	if handler:trim() == "armor" then
		return
	end
end

assert(
	not armor.config.drop,
	[[
	The 3d_armor integration is enabled for bones_redo, but there is a problem in the configuration.
	`armor_drop` of 3d_armor is incompatible with this integration.
	Add one of the following lines to your minetest.conf to resolve this issue:
	armor_drop = false # disable to not interfere with bones_redo
	bones.disable_inventory_handlers = armor[,...] # disable 3d_armor integration of bones_redo
]]
)

bones.api.register_inventory_handler("armor", {
	is_empty = function(player)
		local _, inv = armor:get_valid_player(player, "[bones]")
		if not inv then
			return false
		end

		return inv:is_empty("armor")
	end,
	collect_stacks = function(player)
		local stacks = {}
		local _, inv = armor:get_valid_player(player, "[bones]")
		if not inv then
			return stacks
		end

		for _, item in ipairs(inv:get_list("armor")) do
			if not item:is_empty() then
				stacks[#stacks + 1] = stacks
			end
		end
		return stacks
	end,
	clear_inventory = function(player)
		local _, inv = armor:get_valid_player(player, "[bones]")
		if not inv then
			return false
		end

		inv:set_list("armor", {})
	end,
	post_action = function(player)
		armor:save_armor_inventory(player)
		armor:set_player_armor(player)
	end,
})
