local lists_to_bones = bones.settings.lists_to_bones:split()

local function is_empty(_, player)
    local inv = player:get_inventory()

    for _, listname in ipairs(lists_to_bones) do
        if not inv:is_empty(listname) then
            return false
        end
    end

    return true
end

local function collect_items(_, player, sink)
    local inv = player:get_inventory()
    for _, listname in ipairs(lists_to_bones) do
        local list = inv:get_list(listname)

        if list then
            for _, item in ipairs(list) do
                sink(item)
            end
        end
    end
end

local function empty_inventories(_, player)
    local inv = player:get_inventory()

    for _, listname in ipairs(lists_to_bones) do
        inv:set_list(listname, {})
    end
end

bones.api.register_handler({
    name = "default",
    is_empty = is_empty,
    collect_items = collect_items,
    empty_inventories = empty_inventories,
})
