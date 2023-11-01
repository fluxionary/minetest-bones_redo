futil.check_version({ year = 2023, month = 11, day = 1 }) -- is_player

bones = fmod.create()

bones.dofile("util")
bones.dofile("resources")
bones.dofile("formspec")
bones.dofile("api")
bones.dofile("node")
bones.dofile("entity")
bones.dofile("on_dieplayer")
bones.dofile("commands")
bones.dofile("compat", "init")
