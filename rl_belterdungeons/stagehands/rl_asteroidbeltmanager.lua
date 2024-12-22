require "/interface/cockpit/cockpitutil.lua"
require "/scripts/util.lua"

function init()
  sb.logInfo("rl_asteroidbeltmanager: init: world type = %s", world.type())
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
  sb.logInfo("rl_asteroidbeltmanager: init: star system threat level = %s", threatLevel)

  self.state = world.getProperty("rl_asteroidbeltmanager_state")
  if self.state then
    if self.state.dungeonsGenerated >= self.state.dungeonCount then
      sb.logInfo("rl_asteroidbeltmanager: init: already executed; deactivating")
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
    sb.logInfo("rl_asteroidbeltmanager: init: seed = %s", seed)
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
        sb.logInfo("rl_asteroidbeltmanager: init: truncating dungeonCount to %s", i)
        dungeonCount = i
        break
      end

      table.insert(dungeonCoords, {
        getRandomXCoord(worldSize[1], dungeonCount, i), getRandomYCoord(yRanges)
      })
      table.insert(dungeonTypes, weightedRandomPop(dungeons, seed))
    end
    sb.logInfo("rl_asteroidbeltmanager: init: will generate %s dungeons", dungeonCount)

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
  sb.logInfo("rl_asteroidbeltmanager: init: previously generated %s dungeons", self.state.dungeonsGenerated)
end

function update(dt)
  math.randomseed(self.state.seed)
  while self.state.dungeonsGenerated < self.state.dungeonCount do
    local baseDungeonId = self.state.nextDungeonId
    local dungeonCoords = self.state.dungeonCoords[self.state.dungeonsGenerated + 1]
    local dungeonType = self.state.dungeonTypes[self.state.dungeonsGenerated + 1]
    sb.logInfo("rl_asteroidbeltmanager: update: generating dungeon %s with dungeonId = %s", self.state.dungeonsGenerated, self.state.nextDungeonId)

    local metadata = root.dungeonMetadata(dungeonType)
    sb.logInfo("rl_asteroidbeltmanager: update: loading %s dungeon type with %s anchor parts, %s gravity, %s breathable, %s protected", dungeonType, #metadata.anchor, metadata.gravity, metadata.breathable, metadata.protected)
    world.setDungeonBreathable(baseDungeonId, metadata.breathable)
    world.setDungeonGravity(baseDungeonId, metadata.gravity)
    world.setTileProtection(baseDungeonId, metadata.protected)
    if metadata.extraDungeonIds then
      for _, v in ipairs(metadata.extraDungeonIds) do
        self.state.nextDungeonId = self.state.nextDungeonId + 1
        sb.logInfo("rl_asteroidbeltmanager: update: adding extra dungeon id %s with %s gravity, %s breathable, %s protected", self.state.nextDungeonId, v.gravity or 0, v.breathable or false, v.protected or false)
        world.setDungeonBreathable(self.state.nextDungeonId, v.breathable or false)
        world.setDungeonGravity(self.state.nextDungeonId, v.gravity or 0)
        world.setTileProtection(self.state.nextDungeonId, v.protected or false)
      end
    end
    sb.logInfo("Placing dungeon %s", dungeonType)
    world.placeDungeon(dungeonType, dungeonCoords, baseDungeonId)

    sb.logInfo("rl_asteroidbeltmanager: update: generated dungeon %s", self.state.dungeonsGenerated)
    self.state.dungeonsGenerated = self.state.dungeonsGenerated + 1
    self.state.nextDungeonId = self.state.nextDungeonId + 1
    world.setProperty("rl_asteroidbeltmanager_state", self.state)
  end
  math.randomseed(util.seedTime())

  if self.state.dungeonsGenerated >= self.state.dungeonCount then
    sb.logInfo("rl_asteroidbeltmanager: update: finished executing; deactivating")
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
      sb.logInfo("rl_asteroidbeltmanager: buildDungeonsPool: inserting %s with weight %s", k, weight)
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
  sb.logInfo("rl_asteroidbeltmanager: weightedRandomPop: totalWeight = %s", dungeons.totalWeight)
  sb.logInfo("rl_asteroidbeltmanager: weightedRandomPop: choice = %s", choice)
  for index, pair in ipairs(dungeons.pool) do
    sb.logInfo("rl_asteroidbeltmanager: weightedRandomPop: checking %s with weight %s", pair[2], pair[1])
    choice = choice - pair[1]
    sb.logInfo("rl_asteroidbeltmanager: weightedRandomPop: remaining choice = %s", choice)
    if choice < 0 then
      table.remove(dungeons.pool, index)
      dungeons.totalWeight = dungeons.totalWeight - pair[1]
      return pair[2]
    end
  end
  return nil
end
