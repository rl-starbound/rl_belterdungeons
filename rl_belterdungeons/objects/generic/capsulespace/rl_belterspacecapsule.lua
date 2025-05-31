require "/scripts/util.lua"

function init()
  -- This script will dynamically set the smashDropPool of the capsule
  -- to a pool with level equal to the system threat level.

  -- It takes several ticks before the world's system threat level is
  -- set. The microdungeons that place these begin populating as soon as
  -- the player beams into the world, so early instances may get the
  -- wrong threat level. Wait a short period before setting the treasure
  -- pool for microdungeon-generated instances.
  storage.skipTimer = storage.skipTimer or config.getParameter("skipTimer", 0)
end

function update(dt)
  if storage.skipTimer > 0 then
    storage.skipTimer = storage.skipTimer - dt
    return
  end

  if not storage.treasurePool then
    local level = util.clamp(math.max(
      world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
    ), 2, 6)

    storage.treasurePool = string.format("rlBelterDungeonsCapsuleSpace%d", level)
    object.setConfigParameter("smashDropPool", storage.treasurePool)
  end
  script.setUpdateDelta(0)
end
