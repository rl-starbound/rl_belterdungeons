require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"

function init()
  -- This stagehand allows the generation of ore that are appropriate
  -- for the star system threat level, which may be higher than the
  -- world threat level. Note, this stagehand cannot apply changes to
  -- tiles that are protected.

  -- This stagehand must generate blocks if none exist, which requires
  -- a biome. Getting biome information from the Lua API is impossible,
  -- so limit this stagehand to only known-supported world types.
  local worldType = world.type()
  local biome = config.getParameter("supportedWorldTypes", {})[worldType]
  if not biome then
    sb.logError("rl_systemthreat_oregenerator: " ..
      "unsupported world type: %s", worldType
    )
    script.setUpdateDelta(0)
    stagehand.die()
    return
  else
    biome = root.assetJson(biome)
  end
  self.mainBlock = biome.mainBlock
  if not self.mainBlock then
    sb.logError("rl_systemthreat_oregenerator: biome has no mainBlock")
    script.setUpdateDelta(0)
    stagehand.die()
    return
  end

  self.area = config.getParameter("broadcastArea", {0, 0, 1, 1})

  -- Optional parameter `identifier` sets a name associated with the
  -- stagehand. It is only used for debugging.
  local identifier = config.getParameter("identifier")

  -- Optional parameter `layer` adds ores only to the specified layer.
  -- Must be one of "background" or "foreground". If not specified, the
  -- default is to apply ores to both layers independently.
  self.layer = config.getParameter("layer")
  if self.layer and
     self.layer ~= "background" and self.layer ~= "foreground"
  then
    sb.logWarn("rl_systemthreat_oregenerator: " ..
      "ignoring invalid layer name: %s", self.layer
    )
    self.layer = nil
  end

  -- Optional parameter `seedPositionOffset` allows multiple ore
  -- generator stagehands to produce the same ore. Choose one stagehand
  -- as the primary generator, and then set the offset of each linked
  -- stagehand to match the center point of the primary. If not set,
  -- the generator chooses the ore it produces independently.
  local seedPositionOffset = config.getParameter("seedPositionOffset", {0, 0})

  -- In the context of celestial worlds, use the world seed as the basis
  -- for the NPC seed. In all other contexts, use a random seed.
  local worldSeed = world.getProperty("rl_worldSeed") or
                    util.hashString(sb.makeUuid())

  self.position = entity.position()
  local seedPosition = sb.printJson(vec2.add(self.position, seedPositionOffset))
  --if identifier then
  --  sb.logInfo("rl_systemthreat_oregenerator: name = %s, seed position = %s",
  --    identifier, seedPosition
  --  )
  --end
  self.seed = util.hashString(string.format("%s:%s", worldSeed, seedPosition))

  -- Enable generation of higher-tier ores only if Mech Compatibility
  -- Loader is installed, i.e., if mechs can suffer damage from dynamic
  -- environment hazards. Otherwise, cap ore tier at 3.
  local enableGeneration = contains(
    root.assetJson("/player.config").deploymentConfig.scripts,
    "/scripts/deployment/player_mechcompatcore.lua"
  )
  local threatLevel = math.max(
    world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
  )
  if not enableGeneration then threatLevel = math.min(threatLevel, 3) end

  self.ore = util.weightedRandom(getOreDistribution(threatLevel), self.seed)

  self.probability = config.getParameter("oreProbability", 0.5)
end

function update(dt)
  local ll = vec2.add(self.position, {self.area[1], self.area[2]})
  local ur = vec2.add(self.position, {self.area[3], self.area[4]})
  if ll[2] < 0 or ur[2] > world.size()[2] then
    sb.logError("rl_systemthreat_oregenerator: " ..
      "region out of bounds: %s", sb.printJson(region)
    )
    stagehand.die()
    return
  end
  local region = {ll[1], ll[2], ur[1], ur[2]}

  for _,tile in ipairs(getTilesInRegion(region)) do
    local seedStr = string.format("%s:%s:%s", self.seed, tile[1], tile[2])
    if not self.layer or self.layer == "background" then
      if not world.material(tile, "background") then
        world.placeMaterial(tile, "background", self.mainBlock)
      end
      local seed = util.hashString(string.format("%s:%s", seedStr, "background"))
      math.randomseed(seed)
      if math.random() < self.probability then
        world.placeMod(tile, "background", self.ore)
      end
    end
    if not self.layer or self.layer == "foreground" then
      if not world.material(tile, "foreground") then
        world.placeMaterial(tile, "foreground", self.mainBlock)
      end
      local seed = util.hashString(string.format("%s:%s", seedStr, "foreground"))
      math.randomseed(seed)
      if math.random() < self.probability then
        world.placeMod(tile, "foreground", self.ore)
      end
    end
    math.randomseed(util.seedTime())
  end

  stagehand.die()
end

function getOreDistribution(threatLevel)
  local max = -1
  local ores = nil
  for _,v in ipairs(config.getParameter("oreDistributions")) do
    if v[1] <= threatLevel and v[1] > max then
      max = v[1]
      ores = v[2]
    end
  end
  return ores
end

function getTilesInRegion(region)
  local ll = rect.ll(region)
  local size = rect.size(region)
  local out = {}
  for j = 0, size[2] - 1 do for i = 0, size[1] - 1 do
    table.insert(out, {world.xwrap(ll[1] + i), ll[2] + j})
  end end
  return out
end
