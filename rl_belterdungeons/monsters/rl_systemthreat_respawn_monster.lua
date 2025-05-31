-- This script is meant to replace the scripts in the `scripts` list in
-- monster parameter overrides. It MUST NOT be added in the `scripts`
-- list in a monstertype file, or an infinite loop will result.
--
-- This script is only guaranteed to be compatible with monsters using
-- the base game `/monsters/monster.lua` script. Monsters using custom
-- scripting may require additional work to respawn themselves properly
-- at system threat level.

function update(dt)
  local threatLevel = math.max(
    world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
  )

  local uniqueId = entity.uniqueId()
  if uniqueId then
    -- This script is intended for use only as an override parameter in
    -- spawntypes, which should never have unique IDs, so this should
    -- never happen, but record it if it does.
    sb.logWarn("rl_systemthreat_respawn_monster: replacing monster with unique ID: %s", uniqueId)
  end

  local overrides = monster.uniqueParameters()
  overrides.level = threatLevel
  overrides.seed = monster.seed()

  -- This script was (OR SHOULD HAVE BEEN) added via overrides, so
  -- remove the script overrides to prevent an infinite loop.
  overrides.scripts = nil

  -- Spawn an identical monster at the system threat level.
  world.spawnMonster(monster.type(), entity.position(), overrides)

  monster.setDeathParticleBurst()
  monster.setDeathSound()
  self.deathBehavior = nil
  monster.setDropPool()
  storage.extraDrops = nil

  -- Kill this (the original) instance of the monster.
  status.setResource("health", 0)
end
