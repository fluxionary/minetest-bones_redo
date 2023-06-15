* `bones.enable_bones = true`

  set to `false` to temporarily disable bones. players will keep their inventories.

* `bones.api.is_owner(pos, name)`

  returns true if a player owns bones at that position.

* `bones.api.may_replace(pos, player)`

  returns true if a bones mode may replace the node at the given position

* `bones.api.find_place_for_bones(player, death_pos, radius)`

  searches for a suitable position for a bones node. returns nil if none is found.

* `bones.api.collect_stacks_for_bones(player)`

  removes items from a player's inventories for placement in bones.

* `bones.api.place_bones_node(player, bones_pos)`

  places a bones node for a player

* `bones.api.place_bones_entity(player, death_pos)`

  places a bones entity for a player

* `bones.api.drop_inventory(player, death_pos)`

  drops a player's inventory on the ground

* `bones.api.get_death_pos(player)`

  gets the location of the player's death. tries to find a location on the ground below the player.

* `bones.api.record_death(player_name, pos, mode)`

  logs the player's death

* `bones.api.is_timed_out(player)`

  if true, the player will not be given a bones node when collecting their own bones.
  players can always collect the contents of their bones, but by default, they will only get a
  bones node once an hour. this is to keep players from farming their bones for bonemeal.

* `bones.api.get_last_death_pos(player_name)`

  gets the last position a player died, or nil

* `bones.api.get_mode_for_player(player_name, death_pos)`

  gets the mode to use for a player's death. override this to e.g. allow players below a certain level
  to keep their stuff.
