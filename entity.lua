local S = bones.S

local api = bones.api
local formspec = bones.formspec
local util = bones.util

local serialize_invlist = util.serialize_invlist
local deserialize_invlist = util.deserialize_invlist

local function is_owner(self, name)
	local owner = self._owner

	return self._old or owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass")
end

minetest.register_entity("bones:bones", {
	initial_properties = {
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		selectionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		physical = true,
		pointable = true,
		visual = "cube",
		textures = {
			"bones_top.png^[transform2",
			"bones_bottom.png",
			"bones_side.png",
			"bones_side.png",
			"bones_rear.png",
			"bones_front.png"
		},
		nametag = S("Bones"),
		infotext = S("Bones"),
	},

	get_staticdata = function(self)
		return minetest.write_json({
			becomes_old = self._becomes_old,
			owner = self._owner,
			old = self._old,
			serialized_inv = serialize_invlist(self._inv, "main")
		})
	end,

	on_activate = function(self, staticdata, dtime_s)
		local pos = self.object:get_pos()
		local data = minetest.parse_json(staticdata)

		self.object:set_armor_groups({immortal = 1})

		self._becomes_old = data.becomes_old
		self._owner = data.owner
		self._old = data.old

		-- it's technically possible for multiple player bones to get dropped in the same place... add a unique #
		self._detached_inv_name = ("bones%s"):format(minetest.get_us_time())
		self._inv = minetest.create_detached_inventory(self._detached_inv_name, {
			allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
				return 0
			end,

			allow_put = function(inv, listname, index, stack, player)
				return 0
			end,

			allow_take = function(inv, listname, index, stack, player)
				if is_owner(self, player:get_player_name()) then
					return stack:get_count()
				end
				return 0
			end,

			on_take = function(inv, listname, index, stack, player)
				bones.log("action", "%s takes %s from bones entity @ %s",
					player:get_player_name(), stack:to_string(), minetest.pos_to_string(pos))

				if inv:is_empty("main") then
					if not api.is_timed_out(player) then
						local player_inv = player:get_inventory()
						local remainder = player_inv:add_item("main", {name = "bones:bones"})

						if not remainder:is_empty() then
							minetest.add_item(pos, remainder)
						end
					end

					self.object:remove()
				end
			end,
		}, self._owner)

		deserialize_invlist(data.serialized_inv, self._inv, "main")

		local props = self.object:get_properties()

		if self._old then
			props.infotext = S("@1's bones", self._owner)
			props.nametag = S("@1's bones", self._owner)

		else
			props.infotext = S("@1's fresh bones", self._owner)
			props.nametag = S("@1's fresh bones", self._owner)
		end

		self.object:set_properties(props)
	end,

	on_deactivate = function(self, removal)
		local pos = self.object:get_pos()
		local inv = self._inv

		if removal and inv and not inv:is_empty("main") then
			bones.log("warning",
				"unloading entity w/ non-empty inventory. dropping nodes, which will probably disappear.")
			for _, stack in ipairs(inv:get_list("main")) do
				if not stack:is_empty() then
					bones.log("warning", "dropping %s @ %s", stack:to_string(), minetest.pos_to_string(pos))
					local obj = minetest.add_item(pos, stack)
					local ent = obj:get_luaentity()
					ent.dropped_by = self._owner
				end
			end
		end

		minetest.remove_detached_inventory(self._detached_inv_name)
		self._detached_inv_name = nil
		self._inv = nil
	end,

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
		local pos = self.object:get_pos()

		if not is_owner(self, puncher:get_player_name()) then
			return
		end

		local bones_inv = self._inv
		local player_inv = puncher:get_inventory()

		for i = 1, bones_inv:get_size("main") do
			local stack = bones_inv:get_stack("main", i)
			local before = ItemStack(stack)
			local remainder = player_inv:add_item("main", stack)
			bones_inv:set_stack("main", i, remainder)

			local taken = before:take_item(remainder:get_count())
			if not taken:is_empty() then
				minetest.log("action", "%s takes %s from bones @ %s",
					puncher:get_player_name(), stack:to_string(), minetest.pos_to_string(pos))
			end
		end

		-- remove bones if player emptied them
		if bones_inv:is_empty("main") then
			if not api.is_timed_out(puncher) then
				local remainder = player_inv:add_item("main", {name = "bones:bones"})

				if not remainder:is_empty() then
					minetest.add_item(pos, remainder)
				end
			end

			self.object:remove()
		end

	end,

	on_rightclick = function(self, clicker)
		if not minetest.is_player(clicker) then
			return
		end

		local player_name = clicker:get_player_name()

		minetest.show_formspec(
			player_name,
			("bones:%s"):format(self._detached_inv_name),
			formspec.build_entity_formspec(self, clicker)
		)
	end,

	on_step = function(self, dtime, moveresult)
		if not self._old and minetest.get_us_time() >= self._becomes_old then
			self._old = true
		end
	end,

	on_blast = function(self, damage, blaster)
		local pos = self.object:get_pos()
		local owner = self._owner
		bones.log("action", "%s's bones entity at %s blasted, nothing dropped.", owner, minetest.pos_to_string(pos))
	end,
})
