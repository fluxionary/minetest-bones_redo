local log = bones.log

local util = {}

local staff_priv = bones.settings.staff_priv

function util.drop(itemstack, dropper, pos)
	if itemstack:is_empty() then
		return
	end

	minetest.item_drop(itemstack, dropper, pos)

	log("action", "%s dropped %s at %s", dropper:get_player_name(), itemstack:to_string(), minetest.pos_to_string(pos))
end

function util.can_see(pos1, pos2)
	pos1 = vector.add(pos1, 0.001)
	-- Can we see from pos1 to pos2 ?
	local ray = minetest.raycast(pos1, pos2, false, false)
	local element = ray:next()
	while element do
		if element.type == "node" and minetest.get_node(element.under).name ~= "air" then
			return false
		end
		element = ray:next()
	end
	return true
end

function util.send_to_staff(text)
	local message = minetest.colorize("#98ff98", "[STAFF] " .. text)
	for _, player in ipairs(minetest.get_connected_players()) do
		if futil.is_player(player) and minetest.check_player_privs(player, staff_priv) then
			local name = player:get_player_name()
			minetest.chat_send_player(name, message)
		end
	end
end

bones.util = util
