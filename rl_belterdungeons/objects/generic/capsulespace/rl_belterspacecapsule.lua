require "/scripts/util.lua"

function init()
  -- This script will dynamically set the smashDropPool of the capsule
  -- to a pool with level equal to the system threat level.

  -- Default to the minimum spaceThreatLevel in `/celestial.config`.
  if not storage.treasurePool then
    local level = util.clamp(
      math.max(
        world.getProperty("rl_starSystemThreatLevel", 3),
        world.threatLevel()
      ), 3, 6
    )

    storage.treasurePool = string.format("rlBelterDungeonsCapsuleSpace%d", level)
  end
  object.setConfigParameter("smashDropPool", storage.treasurePool)
end
