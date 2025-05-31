require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  -- This stagehand spawns a group of monsters that have threat level
  -- equal to the star system threat level, which may be higher than the
  -- world threat level. This stagehand assumes it is an 11x11 square
  -- centered over the position at which the monsters should be spawned.
  -- It should be placed in a large open area so that the monsters have
  -- room to maneuver.

  -- `monsterGroup` must be set to the prefix of the monster group to be
  -- spawned. The default value is "smallgroup".
  local dungeonPrefix = config.getParameter("monsterGroup", "smallgroup")

  self.position = entity.position()

  local worldSeed = world.getProperty("rl_worldSeed") or
                    util.hashString(sb.makeUuid())

  -- `seed` is a value to be used by the generation algorithm. If not
  -- provided, then in the context of celestial worlds, use the world
  -- seed as the basis. In all other contexts, use a random seed.
  self.seed = config.getParameter("seed") or util.hashString(
    string.format("%s:%s", worldSeed, sb.printJson(self.position))
  )

  self.threatLevel = math.max(
    world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
  )

  local groups = config.getParameter("monsterGroups")
  local group = groups[dungeonPrefix]
  if not group then
    sb.logWarn("rl_systemthreat_monstergroup: monsterGroup not found: %s",
      dungeonPrefix
    )
    group = {}
  end

  self.monsterGroup = {}
  local highest = -1
  for _,v in ipairs(group) do
    if v[1] > highest and v[1] <= self.threatLevel then
      highest = v[1]
      self.monsterGroup = v[2]
    end
  end
end

function update(dt)
  local group = {}
  if #self.monsterGroup > 0 then
    math.randomseed(self.seed)
    group = util.randomChoice(self.monsterGroup)
    math.randomseed(util.seedTime())
  end

  for _,v in ipairs(group) do
    local position = vec2.add(self.position, v[1])
    local parameters = v[3] or {}
    parameters.level = self.threatLevel
    if parameters.aggressive == nil then parameters.aggressive = true end
    if parameters.persistent == nil then parameters.persistent = true end
    if parameters.seed == nil then
      parameters.seed = util.hashString(
        string.format("%s:%s", self.seed, sb.printJson(position))
      )
    end
    world.spawnMonster(v[2], position, parameters)
  end

  stagehand.die()
end
