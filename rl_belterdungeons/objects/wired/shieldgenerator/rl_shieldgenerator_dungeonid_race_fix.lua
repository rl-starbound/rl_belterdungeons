-- The vanilla code contained a race condition in which the shield
-- generator could init and get its dungeon ID before the dungeon ID was
-- properly set by the placeDungeon function. This code corrects that by
-- setting the dungeon ID dynamically on each interaction.

local previous_output = output

function output(state)
  self.dungeonId = world.dungeonId(object.position())
  previous_output(state)
end
