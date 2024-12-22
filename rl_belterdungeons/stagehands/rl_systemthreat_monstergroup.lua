require "/scripts/util.lua"

local levels = {
  ["3"] = "low",
  ["4"] = "mid",
  ["5"] = "high"
}

function init()
  -- `monsterGroup` must be set to the prefix of the monster group to be
  -- spawned.
  local dungeonPrefix = config.getParameter("monsterGroup")

  -- Default to the minimum spaceThreatLevel in `/celestial.config`.
  local level = math.max(
    world.getProperty("rl_starSystemThreatLevel", 3),
    world.threatLevel()
  )

  self.dungeonName = string.format("%s-%s", dungeonPrefix,
    levels[tostring(util.clamp(math.floor(level), 3, 5))]
  )

  sb.logInfo("rl_systemthreat_monstergroup: init: dungeonName = %s", self.dungeonName)
end

function update(dt)
  local pos = entity.position()
  sb.logInfo("rl_systemthreat_monstergroup: update: placeDungeon %s at %s with dungeonid %s", self.dungeonName, pos, world.dungeonId(pos))
  world.placeDungeon(self.dungeonName, pos, world.dungeonId(pos))

  stagehand.die()
end
