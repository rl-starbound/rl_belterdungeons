require "/interface/cockpit/cockpitutil.lua"
require "/scripts/util.lua"

function init()
  local tryUniqueId = config.getParameter("tryUniqueId")
  if entity.uniqueId() ~= tryUniqueId then
    if world.findUniqueEntity(tryUniqueId):result() == nil then
      stagehand.setUniqueId(tryUniqueId)
    else
      stagehand.die()
      return
    end
  end

  local worldId = config.getParameter("worldId")
  if not worldIdCoordinate(worldId) then
    sb.logWarn("rl_asteroidbeltmanager: init: non-celestial world; terminating")
    stagehand.die()
    return
  end

  if world.type() ~= "asteroids" then
    sb.logWarn("rl_asteroidbeltmanager: init: non-asteroids world; terminating")
    stagehand.die()
    return
  end

  -- Default to the minimum spaceThreatLevel in `/celestial.config`.
  local threatLevel = math.max(
    world.getProperty("rl_starSystemThreatLevel", 3),
    world.threatLevel()
  )

  self.state = world.getProperty("rl_asteroidbeltmanager_state")
  if self.state then
    if self.state.dungeonsGenerated >= self.state.dungeonCount then
      script.setUpdateDelta(0)
    end
  else
    local worldSize = world.size()
    local worldSizeStr = string.format("%sx%s", worldSize[1], worldSize[2])
    local worldConfig = config.getParameter("worldConfigs")[worldSizeStr]
    if not worldConfig or
       not worldConfig["dungeonCountRange"] or not worldConfig["yRanges"]
    then
      sb.logWarn("rl_asteroidbeltmanager: init: " ..
        "missing or invalid world config for asteroid belt size: %s",
        worldSizeStr
      )
    end

    local dungeonCoords = {}
    local dungeonCountRange = worldConfig["dungeonCountRange"] or {0, 0}
    local dungeonTypes = {}
    local seed = util.hashString(worldId)
    local yRanges = worldConfig["yRanges"]

    math.randomseed(seed)

    local dungeonCount = math.random(
      dungeonCountRange[1], dungeonCountRange[2]
    )
    local dungeons = buildDungeonsPool(
      config.getParameter("dungeons"), threatLevel
    )

    if not yRanges then
      dungeonCount = 0
    end

    for i = 0, dungeonCount - 1 do
      if #(dungeons.pool) == 0 then
        dungeonCount = i
        break
      end

      table.insert(dungeonCoords, {
        getRandomXCoord(worldSize[1], dungeonCount, i), getRandomYCoord(yRanges)
      })
      table.insert(dungeonTypes, weightedRandomPop(dungeons, seed))
    end

    math.randomseed(util.seedTime())

    self.state = {
      dungeonCount = dungeonCount,
      dungeonCoords = dungeonCoords,
      dungeonTypes = dungeonTypes,
      dungeonsGenerated = 0,
      nextDungeonId = 100,
      parentEntityId = config.getParameter("parentEntityId"),
      seed = seed
    }
    world.setProperty("rl_asteroidbeltmanager_state", self.state)
  end
end

function update(dt)
  math.randomseed(self.state.seed)
  while self.state.dungeonsGenerated < self.state.dungeonCount do
    local baseDungeonId = self.state.nextDungeonId
    local dungeonCoords = self.state.dungeonCoords[self.state.dungeonsGenerated + 1]
    local dungeonType = self.state.dungeonTypes[self.state.dungeonsGenerated + 1]

    local metadata = root.dungeonMetadata(dungeonType)
    world.setDungeonBreathable(baseDungeonId, metadata.breathable)
    world.setDungeonGravity(baseDungeonId, metadata.gravity)
    world.setTileProtection(baseDungeonId, metadata.protected)
    if metadata.extraDungeonIds then
      for _, v in ipairs(metadata.extraDungeonIds) do
        self.state.nextDungeonId = self.state.nextDungeonId + 1
        world.setDungeonBreathable(self.state.nextDungeonId, v.breathable or false)
        world.setDungeonGravity(self.state.nextDungeonId, v.gravity or 0)
        world.setTileProtection(self.state.nextDungeonId, v.protected or false)
      end
    end
    sb.logInfo("Placing dungeon %s", dungeonType)
    world.placeDungeon(dungeonType, dungeonCoords, baseDungeonId)

    self.state.dungeonsGenerated = self.state.dungeonsGenerated + 1
    self.state.nextDungeonId = self.state.nextDungeonId + 1
    world.setProperty("rl_asteroidbeltmanager_state", self.state)
  end
  math.randomseed(util.seedTime())

  if self.state.dungeonsGenerated >= self.state.dungeonCount then
    if self.state.parentEntityId and
       world.entityExists(self.state.parentEntityId)
    then
      world.sendEntityMessage(self.state.parentEntityId,
        "rl_asteroidbeltmanager_completed", self.state.dungeonsGenerated
      )
      self.state.parentEntityId = nil
      world.setProperty("rl_asteroidbeltmanager_state", self.state)
    end
    script.setUpdateDelta(0)
  end
end

function buildDungeonsPool(dungeons, threatLevel)
  local retval = { pool = {}, totalWeight = 0 }

  -- The Lua `pairs` function pulls key-value pairs out of tables at
  -- random, so it is not usable to build a seed-based deterministic
  -- pseudo-random draw. So, first get the keys of the table and sort
  -- them, then build and shuffle the list deterministically.
  for _, k in ipairs(util.orderedKeys(dungeons)) do
    v = dungeons[k]
    if threatLevel >= (v.minimumThreatLevel or 0) and
       threatLevel <= (v.maximumThreatLevel or 1000000000)
    then
      local weight = v.weight or 1
      if weight < 0 then weight = 0 end
      table.insert(retval.pool, {weight, k})
      retval.totalWeight = retval.totalWeight + weight
    end
  end
  shuffle(retval.pool)
  return retval
end

function getRandomXCoord(worldWidth, dungeonCount, dungeonIdx)
  if worldWidth < 200 * dungeonCount or dungeonIdx >= dungeonCount then
    sb.logError("rl_asteroidbeltmanager: getRandomXCoord: invalid parameters")
    return nil
  end

  if dungeonIdx == 0 then
    self.firstX = math.random(0, worldWidth - 1)
    return self.firstX
  end

  local offsetMid = math.floor(worldWidth / dungeonCount)
  return world.xwrap(self.firstX + math.random(
    dungeonIdx * offsetMid - math.floor(0.5 * offsetMid) + 100,
    dungeonIdx * offsetMid + math.floor(0.5 * offsetMid) - 100
  ))
end

function getRandomYCoord(ranges)
  local i = math.random(#ranges)
  return math.random(ranges[i][1], ranges[i][2])
end

function weightedRandomPop(dungeons, seed)
  local choice = dungeons.totalWeight * sb.staticRandomDouble(seed)
  for index, pair in ipairs(dungeons.pool) do
    choice = choice - pair[1]
    if choice < 0 then
      table.remove(dungeons.pool, index)
      dungeons.totalWeight = dungeons.totalWeight - pair[1]
      return pair[2]
    end
  end
  return nil
end
