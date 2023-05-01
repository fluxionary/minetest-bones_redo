if not bones.has["i3"] then
	return
end

if not bones.settings.i3_bag_to_bones then
	return
end

i3.settings.drop_bag_on_die = false

assert(type(i3.settings.keep_bag_on_die) ~= "nil", [[

	Your version of i3 is not compatible with bones_redo.
]])

i3.settings.keep_bag_on_die = true
i3.settings.drop_bag_on_die = false

local function get_detached_inv(name, player_name)
	return core.get_inventory({
		type = "detached",
		name = string.format("i3_%s_%s", name, player_name)
	})
end

local function get_bag(player_name)
	local data = i3.data[player_name]

	if not data then return end

	local bag = get_detached_inv("bag", player_name)
	local content = get_detached_inv("bag_content", player_name)

	return data, bag, content
end

local function is_empty(_, player)
	local player_name = player:get_player_name()

	local data, bag, content = get_bag(player_name)

	if not data then return end

	if bag then
		return bag:is_empty("main")
	else
		return false
	end
end

local function collect_items(_, player, sink)
	local player_name = player:get_player_name()

	local data, bag, content = get_bag(player_name)

	if bag then
		local list = bag:get_list("main")

		for _, item in ipairs(list) do
			sink(item)
		end
	end
end

local function empty_inventories(_, player)
	local player_name = player:get_player_name()

	local data, bag, content = get_bag(player_name)

	if not data then return end

	data.bag = nil

	if bag then
		bag:set_list("main", {})
	end

	if content then
		content:set_list("main", {})
	end
end

local function post_action(_, player)
	i3.set_fs(player)
end

bones.api.register_handler({
	name = "i3",
    is_empty = is_empty,
    collect_items = collect_items,
    empty_inventories = empty_inventories,
	post_action = post_action,
})
