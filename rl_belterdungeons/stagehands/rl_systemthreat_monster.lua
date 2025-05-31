require "/scripts/util.lua"

function init()
  -- This stagehand allows the creation of monsters that have threat
  -- level equal to the star system threat level, which may be higher
  -- than the world threat level.

  -- `monster` must be set to the monster type name to be spawned.
  self.monster = config.getParameter("monster")

  -- `parameters` is a JSON map of overriding parameters to be passed to
  -- the monster creation function. If "level" is provided, it will be
  -- ignored in favor of the system threat level. If "persistent" is set
  -- to `false`, the monster will not be persisted to storage, and will
  -- cease to exist during chunk unload; the default is to persist. It
  -- is highly recommended to provide "aggressive", a boolean, because
  -- without it, monsters spawned using this stagehand will be either
  -- passive or aggressive at random.
  self.parameters = config.getParameter("parameters", {})

  self.parameters.level = math.max(
    world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
  )

  if self.parameters.persistent == nil then
    self.parameters.persistent = true
  end
end

function update(dt)
  world.spawnMonster(self.monster, entity.position(), self.parameters)

  stagehand.die()
end
