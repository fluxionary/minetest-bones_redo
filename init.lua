futil.check_version({ year = 2022, month = 10, day = 24 })

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
