local resources = {
	sounds = {},
	fs_style = {},
}

if bones.has.default then
	resources.fs_style.inv = default.get_hotbar_bg(0, 6.45)
	resources.sounds.bones = default.node_sound_gravel_defaults()
end

bones.resources = resources
