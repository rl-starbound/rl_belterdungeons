require "/scripts/util.lua"

function init()
  -- This stagehand allows the creation of NPCs that have threat level
  -- equal to the star system threat level, which may be higher than the
  -- world threat level. It chooses the species of the NPC based on the
  -- world seed, so all gang members in a world are the same species.

  -- `typeName` must be set to the desired NPC type name.
  self.typeName = config.getParameter("typeName", "gangmember")

  -- `parameters` is a JSON map of overriding parameters to be passed to
  -- the NPC creation function. Its semantics are as in the base game.
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

  -- Add in gang parameters
  self.parameters.scriptConfig = self.parameters.scriptConfig or {}
  self.parameters.scriptConfig.gang = world.getProperty("rl_gangConfig") or {
    name = "Chaotic Crime Collective",
    hat = "bandithat1",
    majorColor = 1,
    capstoneColor = 2,
    species = {
      "apex", "avian", "floran", "glitch", "human", "hylotl", "novakid"
    }
  }
  self.species = self.parameters.scriptConfig.gang.species
  self.parameters.scriptConfig.gang.species = nil

  if type(self.species) == "table" then
    math.randomseed(self.seed)
    self.species = util.randomChoice(self.species)
    math.randomseed(util.seedTime())
  end
end

function update(dt)
  world.spawnNpc(entity.position(), self.species, self.typeName,
    self.level, self.seed, self.parameters
  )

  stagehand.die()
end
