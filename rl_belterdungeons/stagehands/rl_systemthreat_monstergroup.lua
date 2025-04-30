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
end

function update(dt)
  local pos = entity.position()
  world.placeDungeon(self.dungeonName, pos, world.dungeonId(pos))

  stagehand.die()
end
