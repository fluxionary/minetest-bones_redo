if not bones.has["3d_armor"] then
	return
end

if not bones.settings.armor_to_bones then
	return
end

assert(not armor.config.drop, [[

	The 3d_armor integration is enabled for bones_redo, but there is a problem in the configuration.
	`armor_drop` of 3d_armor is incompatible with this integration.
	Add one of the following lines to your minetest.conf to resolve this issue:

	armor_drop = false # disable to not interfere with bones_redo

	bones.armor_to_bones = false # disable 3d_armor integration of bones_redo
]])

local function is_empty(_, player)
	local _, inv = armor:get_valid_player(player, "[bones]")
	if not inv then
		return false
	end

	return inv:is_empty("armor")
end

local function collect_items(_, player, sink)
	local _, inv = armor:get_valid_player(player, "[bones]")
	if not inv then
		return
	end

	local list = inv:get_list("armor")

	for _, item in ipairs(list) do
		sink(item)
	end
end

local function empty_inventories(_, player)
	local _, inv = armor:get_valid_player(player, "[bones]")
	if not inv then
		return false
	end

	inv:set_list("armor", {})
end

local function post_action(_, player)
	armor:save_armor_inventory(player)
	armor:set_player_armor(player)
end

bones.api.register_handler({
	name = "3d_armor",
    is_empty = is_empty,
    collect_items = collect_items,
    empty_inventories = empty_inventories,
	post_action = post_action,
})
