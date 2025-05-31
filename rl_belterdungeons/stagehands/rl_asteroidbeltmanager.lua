require "/interface/cockpit/cockpitutil.lua"
require "/scripts/rl_dynamicstatuseffects.lua"
require "/scripts/util.lua"

function init()
  local tryUniqueId = config.getParameter("tryUniqueId")
  if entity.uniqueId() ~= tryUniqueId then
    if world.findUniqueEntity(tryUniqueId):result() == nil then
      stagehand.setUniqueId(tryUniqueId)
    else
      script.setUpdateDelta(0)
      stagehand.die()
      return
    end
  end

  local worldId = config.getParameter("worldId")
  if not worldIdCoordinate(worldId) then
    sb.logWarn("rl_asteroidbeltmanager: non-celestial world; terminating")
    script.setUpdateDelta(0)
    stagehand.die()
    return
  end

  if world.type() ~= "asteroids" then
    sb.logWarn("rl_asteroidbeltmanager: non-asteroids world; terminating")
    script.setUpdateDelta(0)
    stagehand.die()
    return
  end

  local threatLevel = math.max(
    world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
  )

  self.state = world.getProperty("rl_asteroidbeltmanager_state")
  if self.state then
    if isCompleted() then script.setUpdateDelta(0) end
  else
    local worldSize = world.size()
    local worldSizeStr = string.format("%sx%s", worldSize[1], worldSize[2])
    local worldConfig = config.getParameter("worldConfigs")[worldSizeStr]
    if not worldConfig or
       type(worldConfig.dungeonCountRange) ~= "table" or
       type(worldConfig.yRanges) ~= "table"
    then
      sb.logWarn("rl_asteroidbeltmanager: " ..
        "missing or invalid world config for asteroid belt size: %s",
        worldSizeStr
      )
      script.setUpdateDelta(0)
      stagehand.die()
      return
    end

    local dungeonCoords = {}
    local dungeonCountRange = worldConfig.dungeonCountRange
    local dungeonTypes = {}
    local seed = util.hashString(worldId)
    local yRanges = worldConfig.yRanges

    math.randomseed(seed)

    local dungeonCount = math.random(
      dungeonCountRange[1], dungeonCountRange[2]
    )
    local origDungeonsPool = config.getParameter("dungeons", {})
    local origDungeonsPoolSize = util.tableSize(origDungeonsPool)
    local dungeons = buildDungeonsPool(origDungeonsPool, threatLevel)

    if #yRanges < 1 then dungeonCount = 0 end

    for i = 0, dungeonCount - 1 do
      if #dungeons.pool == 0 then
        dungeonCount = i
        break
      end

      table.insert(dungeonCoords, {
        getRandomXCoord(worldSize[1], dungeonCount, i), getRandomYCoord(yRanges)
      })
      table.insert(dungeonTypes, weightedRandomPop(dungeons, seed))
    end

    math.randomseed(util.seedTime())

    -- Do not add dynamic status effects if No Belter Dungeons is installed.
    local useDynamicStatusEffects = origDungeonsPoolSize > 0

    local effects = {}
    if useDynamicStatusEffects then
      effects = getEnvironmentStatusEffects(threatLevel)
    end

    self.state = {
      dungeonCount = dungeonCount,
      dungeonCoords = dungeonCoords,
      dungeonTypes = dungeonTypes,
      dungeonsGenerated = 0,
      dynamicStatusEffects = {
        global = effects,
        globalPending = #effects > 0
      },
      nextDungeonId = 100,
      parentEntityId = config.getParameter("parentEntityId"),
      seed = seed
    }
    world.setProperty("rl_asteroidbeltmanager_state", self.state)
  end

  -- Given the scenario that a player character was in a world, and the
  -- player quit the game and deleted the world's file, and then started
  -- the game and loaded their character, causing the core engine to
  -- rebuild the world as the player loads, a race condition exists in
  -- which the core engine might erroneously report the player as not
  -- existing in the world for the first update. In this case, setting
  -- the environment status effects immediately would result in the
  -- player's Lua context not being notified of the update, and the
  -- player would not be affected by the status effects. Therefore, wait
  -- at least 0.25 seconds before setting the status effects.
  self.dynamicStatusEffectsTimer = 0.25
end

function update(dt)
  local dynamicStatusEffects = self.state.dynamicStatusEffects or {}
  if dynamicStatusEffects.globalPending then
    self.dynamicStatusEffectsTimer = self.dynamicStatusEffectsTimer - dt
    if self.dynamicStatusEffectsTimer <= 0 then
      local manager = getDynamicStatusEffectsManager()
      if manager then
        world.sendEntityMessage(manager, "setEffects",
          nil, "rl_asteroidbeltmanager", dynamicStatusEffects.global
        )
      else
        sb.logError("rl_asteroidbeltmanager: " ..
          "failed to set global status effects"
        )
      end

      dynamicStatusEffects.globalPending = false
      world.setProperty("rl_asteroidbeltmanager_state", self.state)
    end
  end

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

  if self.state.dungeonsGenerated >= self.state.dungeonCount and
     self.state.parentEntityId
  then
    if world.entityExists(self.state.parentEntityId) then
      world.sendEntityMessage(self.state.parentEntityId,
        "rl_asteroidbeltmanager_completed", self.state.dungeonsGenerated
      )
    end
    self.state.parentEntityId = nil
    world.setProperty("rl_asteroidbeltmanager_state", self.state)
  end

  if isCompleted() then script.setUpdateDelta(0) end
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

function isCompleted()
  return (
    self.state.dungeonsGenerated >= self.state.dungeonCount and
    not (self.state.dynamicStatusEffects or {}).globalPending
  )
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

function getEnvironmentStatusEffects(threatLevel)
  local effects = config.getParameter("environnmentStatusEffects", {})
  local effectList = {}
  local highestTier = -1
  for i,v in ipairs(effects) do
    if v[1] <= threatLevel and v[1] > highestTier then
      highestTier = v[1]
      effectList = v[2]
    end
  end
  return effectList
end
