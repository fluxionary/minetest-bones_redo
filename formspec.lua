
bones.formspec = {
	node_spec = [[
		size[8,10.5]
		list[context;main;0,0.3;8,6;]
		list[current_player;main;0,6.45;8,4;]
		listring[context;main]
		listring[current_player;main]
	]] .. (bones.resources.fs_style.inv or ""),

	build_entity_formspec = function(self, clicker)
		if not self._detached_inv_name then
			return
		end

		local our_list = ("detached:%s"):format(minetest.formspec_escape(self._detached_inv_name))

		return ([[
			size[8,10.5]
			list[%s;main;0,0.3;8,6;]
			list[current_player;main;0,6.45;8,4;]
			listring[%s;main]
			listring[current_player;main]
		]] .. (bones.resources.fs_style.inv or "")):format(our_list, our_list)
	end,
}
