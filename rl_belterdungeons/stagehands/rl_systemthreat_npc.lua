require "/scripts/util.lua"

function init()
  -- This stagehand allows the creation of NPCs that have threat level
  -- equal to the star system threat level, which may be higher than the
  -- world threat level.

  -- `species` must be set to the species to be spawned, or a JSON list
  -- of species from which one will be chosen at random. Care must be
  -- taken to ensure that all elements of the Cartesian product of the
  -- species and type names specify valid NPC types.
  self.species = config.getParameter("species")

  -- `typeName` must be set to the desired NPC type name, or a JSON list
  -- of type names from which one will be chosen at random. Care must be
  -- taken to ensure that all elements of the Cartesian product of the
  -- species and type names specify valid NPC types.
  self.typeName = config.getParameter("typeName")

  -- `parameters` is a JSON map of overriding parameters to be passed to
  -- the NPC creation function. Its semantics are as in the base game.
  -- Care must be taken to ensure that the given parameters are valid
  -- for all elements of the Cartesian product of the species and type
  -- names.
  self.parameters = config.getParameter("parameters", {})

  local worldSeed = world.getProperty("rl_worldSeed") or
                    util.hashString(sb.makeUuid())

  -- `seed` is a value to be used by the generation algorithm. If not
  -- provided, then in the context of celestial worlds, use the world
  -- seed as the basis for the NPC seed. In all other contexts, use a
  -- random seed.
  self.seed = config.getParameter("seed") or util.hashString(
    worldSeed .. util.tableToString(entity.position())
  )

  self.level = math.max(
    world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
  )

  math.randomseed(self.seed)
  if type(self.species) == "table" then
    self.species = util.randomChoice(self.species)
  end
  if type(self.typeName) == "table" then
    self.typeName = util.randomChoice(self.typeName)
  end
  math.randomseed(util.seedTime())
end

function update(dt)
  world.spawnNpc(entity.position(), self.species, self.typeName,
    self.level, self.seed, self.parameters
  )

  stagehand.die()
end
