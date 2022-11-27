minetest.register_chatcommand("bones_toggle", {
	params = "",
	description = "Chatcommand to toggle between 'keep all inventory' and 'let inv either drop or go to bones'.",
	privs = { staff = true },
	func = function()
		bones.api.toggle_enabled()

		if bones.enabled then
			return true, "Bones will drop or go to a bones block"
		else
			return true, "Bones will stay with the player"
		end
	end,
})
