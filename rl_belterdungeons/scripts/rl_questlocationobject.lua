require "/scripts/quest/participant.lua"
require "/scripts/quest/location.lua"
require "/scripts/spawnPoint.lua"

require "/objects/spawner/colonydeed/timer.lua"
require "/scripts/poly.lua"

local previous_die = die
local previous_init = init
local previous_uninit = uninit
local previous_update = update

-- Converts a bounding box into a rectangle of world points, i.e., the
-- top and right edges are excluded from the rectangle.
local function boundBox2worldPoints(r)
  assert((r[3] >= r[1] + 1) and (r[4] >= r[2] + 1))
  return {r[1], r[2], r[3] - 1, r[4] - 1}
end

-- Converts a rectangle of world points into a bounding box, i.e., the
-- top and right edges are included in the rectangle.
local function worldPoints2boundBox(r)
  return {r[1], r[2], r[3] + 1, r[4] + 1}
end

local min_dimensions = {4, 5}

-- rectangle must be a bounding box
local function regionSizeCheck(rectangle)
  local size = rect.size(rectangle)
  return size[1] >= min_dimensions[1] and size[2] >= min_dimensions[2]
end

local function makeSpace1D(position, size)
  return position[2] * size[1] + position[1]
end

local function rect2listIterator(rectangle, size)
  local i = 0
  local maxI = size[1] * size[2]
  local ll = rect.ll(rectangle)
  return function ()
      if i >= maxI then return nil end
      x = i % size[1]
      y = math.floor(i / size[1])
      i = i + 1
      return {ll[1] + x, ll[2] + y}
    end
end

local function calculateObjectGeometry(spaces, spaceHash)
  local position = entity.position()
  local worldSize = world.size()
  local geometry = { spaceHash = spaceHash }
  local worldPointsBox = rect.translate(poly.boundBox(spaces), position)
  geometry.boundBox = worldPoints2boundBox(worldPointsBox)
  if self.rl_qlo_region_expandable then
    local spaceMap = {}
    for _,space in ipairs(spaces) do
      local pos = vec2.add(space, position)
      spaceMap[makeSpace1D(pos, worldSize)] = true
    end
    geometry.negativeSpaces = {}
    for space in rect2listIterator(worldPointsBox, rect.size(geometry.boundBox)) do
      if not spaceMap[makeSpace1D(space, worldSize)] then
        table.insert(geometry.negativeSpaces, space)
      end
    end
  end
  geometry.region = shallowCopy(geometry.boundBox)
  sb.logInfo("rl_questlocationobject: calculateObjectGeometry: %s geometry = %s", object.name(), sb.printJson(geometry))
  return geometry
end

local function getObjectGeometry()
  local spaces = object.spaces()
  local spaceHash = util.hashString(sb.printJson(object.spaces()))
  if not storage.rl_qlo_geometry or
     spaceHash ~= storage.rl_qlo_geometry.spaceHash
  then
    -- If assets are updated between game sessions, it is possible that
    -- the geometry of a placed object could have changed. Check if the
    -- spaces have been changed and recalculate if they have. This will
    -- also reset any geometry expansion.
    storage.rl_qlo_geometry = calculateObjectGeometry(spaces, spaceHash)
  end
end

local function disableQuestLocation()
  if self.rl_qlo_quest then
    sb.logInfo("rl_questlocationobject: disableQuestLocation: unregistering location %s", entity.uniqueId())
    if self.rl_qlo_location.tags then self.rl_qlo_location:unregister() end
    sb.logInfo("rl_questlocationobject: disableQuestLocation: killing quest participant")
    self.rl_qlo_quest:die()

    self.rl_qlo_location = nil
    self.rl_qlo_locationType = nil
    self.rl_qlo_locationTypeTags = nil
    self.rl_qlo_quest = nil
    self.rl_qlo_timers = nil
    self.rl_qlo_waterLiquidIds = nil

    storage.rl_qlo_breathable = nil
    storage.rl_qlo_gravity = nil
    storage.rl_qlo_tags = nil
  end

  if #config.getParameter('scripts', {}) < 2 then
    -- If this script file is the only script assigned to this object,
    -- then when terminating quest location object behavior, this script
    -- should disable further updates. In the event that the object is
    -- uninit'ed and init'ed again, this will be reset.
    sb.logInfo("rl_questlocationobject: disableQuestLocation: disabling updates")
    script.setUpdateDelta(0)
  else
    sb.logInfo("rl_questlocationobject: disableQuestLocation: not disabling updates")
  end
end

local function maybeBuildTags()
  local center = rect.center(storage.rl_qlo_geometry.region)
  local region = boundBox2worldPoints(storage.rl_qlo_geometry.region)
  local points = {
    center, rect.ll(region), rect.lr(region), rect.ul(region), rect.ur(region),
    {center[1], region[2]}, {region[1], center[2]}, {center[1], region[4]},
    {region[3], center[2]}
  }
  local breathablePoints = util.filter(points, function(pos)
      -- If a foreground position is blocked (e.g., by the bottom of a
      -- teleporter pad), that position counts as unbreathable, even
      -- though it may be breathable based on the dungeon id. For now,
      -- just ignore that point.
      return not world.pointCollision(pos, {"Block"})
    end)
  local gravityDict = {
    [#points] = "rl_positive_g",
    [0] = "rl_zero_g",
    [(#points+1)*#points] = "rl_negative_g",
  }
  local breathableDict = #breathablePoints > 0 and {
    [#breathablePoints] = "rl_breathable",
    [0] = "rl_vacuum",
    [(#breathablePoints+1)*#breathablePoints] = "rl_liquid",
    [((#breathablePoints+1)*#breathablePoints+1)*#breathablePoints] = "rl_liquid_water",
  } or {}

  local gravity = gravityDict[util.sum(util.map(points, function(pos)
      local g = world.gravity(pos)
      return (g > 0 and 1) or (g == 0 and 0) or #points+1
    end))]

  local breathable = breathableDict[util.sum(util.map(breathablePoints, function(pos)
      if not world.breathable(pos) then
        local liquid = world.liquidAt(pos)
        if liquid and liquid[2] > 0.9 then
          if contains(self.rl_qlo_waterLiquidIds, liquid[1]) then
            return (#breathablePoints+1)*#breathablePoints+1
          end
          return #breathablePoints+1
        end
        return 0
      end
      return 1
    end))]

  if gravity ~= storage.rl_qlo_gravity or
     breathable ~= storage.rl_qlo_breathable or
     not storage.rl_qlo_tags
  then
    local tags = {}
    if gravity then table.insert(tags, gravity) end
    if breathable then table.insert(tags, breathable) end
    for _,v in ipairs(self.rl_qlo_locationTypeTags) do table.insert(tags, v) end

    storage.rl_qlo_gravity = gravity
    storage.rl_qlo_breathable = breathable
    storage.rl_qlo_tags = tags
    return true
  end
end

local function environmentScan()
  if maybeBuildTags() then
    sb.logInfo("rl_questlocationobject: environmentScan: location %s got new tags: %s", entity.uniqueId(), sb.printJson(storage.rl_qlo_tags))
    if self.rl_qlo_location.tags then self.rl_qlo_location:unregister() end
    self.rl_qlo_location.tags = storage.rl_qlo_tags
    if regionSizeCheck(storage.rl_qlo_geometry.region) and
       not self.rl_qlo_quest:hasQuest()
    then
      sb.logInfo("rl_questlocationobject: environmentScan: registering location %s for new tags", entity.uniqueId())
      self.rl_qlo_location:register()
    end
  end
end

local function environmentScanDelay()
  return util.randomInRange(config.getParameter("rl_questLocation.environmentScanFrequency", {1, 2}))
end

-- region must be a bounding box
local function expandRegion()
  local region = shallowCopy(storage.rl_qlo_geometry.boundBox)
  local size = rect.size(region)
  local diff = vec2.sub(min_dimensions, size)
  diff[1] = math.max(0, math.ceil(diff[1]))
  diff[2] = math.max(0, math.ceil(diff[2]))
  -- check for collisions within the bounding box
  for _,position in ipairs(storage.rl_qlo_geometry.negativeSpaces) do
    if world.pointTileCollision(
      position, {"Null", "Block", "Dynamic", "Slippery"}
    ) then
      sb.logInfo("rl_questlocationobject: expandRegion: collision inside object bound box, not expanding")
      return region
    end
  end
  -- search for and expand to floor
  local bottomSearchLimit = 8
  assert(diff[2] < bottomSearchLimit)
  local floorOffset = nil
  for i=0,size[1]-1 do
    local collision = world.lineTileCollisionPoint(
      {region[1] + i, region[2] - 0.01},
      {region[1] + i, region[2] - bottomSearchLimit},
      {"Null", "Block", "Platform", "Dynamic", "Slippery"}
    )
    if collision then
      local mag = world.magnitude({region[1] + i, region[2]}, collision[1])
      if not floorOffset or mag < floorOffset then floorOffset = mag end
    end
  end
  bottomSearchLimit = floorOffset and math.floor(floorOffset) or bottomSearchLimit
  local doorOffset = nil
  for j=1,bottomSearchLimit do
    local collision = nil
    for i=0,size[1]-1 do
      local pos = world.xwrap({region[1] + i, region[2] - j})
      local doors = world.objectQuery(pos, vec2.add(pos, 1),
        {callScript = "doorOccupiesSpace", callScriptArgs = {pos}}
      )
      if #doors > 0 then collision = true; break end
    end
    if collision then doorOffset = j - 1; break end
  end
  if not doorOffset then
    doorOffset = floorOffset and math.floor(floorOffset) or diff[2]
  end
  sb.logInfo("rl_questlocationobject: expandRegion: final bottom offset = %s", doorOffset)
  region[2] = region[2] - doorOffset
  -- expand to left
  sb.logInfo("want to expand %s to the left", diff[1])
  size = rect.size(region)
  for j=1,diff[1] do
    if world.rectTileCollision(
      {region[1] - 1, region[2], region[1], region[4]},
      {"Null", "Block", "Dynamic", "Slippery"}
    ) then
      sb.logInfo("collided tile to left")
      break
    else
      local collision = nil
      for i=0,size[2]-1 do
        local pos = world.xwrap({region[1] - 1, region[2] + i})
        local doors = world.objectQuery(pos, vec2.add(pos, 1),
          {callScript = "doorOccupiesSpace", callScriptArgs = {pos}}
        )
        if #doors > 0 then collision = true; break end
      end
      if collision then
        sb.logInfo("collided door to the left")
        break
      else
        sb.logInfo("expanded 1 to the left")
        region[1] = region[1] - 1
      end
    end
  end
  -- expand to right
  sb.logInfo("want to expand %s to the right", diff[1])
  for j=1,diff[1] do
    if world.rectTileCollision(
      {region[3], region[2], region[3] + 1, region[4]},
      {"Null", "Block", "Dynamic", "Slippery"}
    ) then
      sb.logInfo("collided tile to right")
      break
    else
      local collision = nil
      for i=0,size[2]-1 do
        local pos = world.xwrap({region[3], region[2] + i})
        local doors = world.objectQuery(pos, vec2.add(pos, 1),
          {callScript = "doorOccupiesSpace", callScriptArgs = {pos}}
        )
        if #doors > 0 then collision = true; break end
      end
      if collision then
        sb.logInfo("collided door to the right")
        break
      else
        sb.logInfo("expanded 1 to the right")
        region[3] = region[3] + 1
      end
    end
  end
  -- expand to top
  sb.logInfo("want to expand %s to the top", diff[2])
  size = rect.size(region)
  for j=1,diff[2] do
    if world.rectTileCollision(
      {region[1], region[4], region[3], region[4] + 1},
      {"Null", "Block", "Dynamic", "Slippery"}
    ) then
      sb.logInfo("collided tile to top")
      break
    else
      local collision = nil
      for i=0,size[1]-1 do
        local pos = world.xwrap({region[1] + i, region[4]})
        local doors = world.objectQuery(pos, vec2.add(pos, 1),
          {callScript = "doorOccupiesSpace", callScriptArgs = {pos}}
        )
        if #doors > 0 then collision = true; break end
      end
      if collision then
        sb.logInfo("collided door to the top")
        break
      else
        sb.logInfo("expanded 1 to the top")
        region[4] = region[4] + 1
      end
    end
  end
  return region
end

local function regionScan()
  if not world.regionActive(storage.rl_qlo_geometry.region) then
    util.debugLog("Parts of the questlocation object are unloaded - skipping region check")
    return
  end
  sb.logInfo("scanning for region for object %s", object.name())
  local newRegion = expandRegion()
  if not compare(storage.rl_qlo_geometry.region, newRegion) then
    sb.logInfo("rl_questlocationobject: regionScan: location %s got new region: %s", entity.uniqueId(), sb.printJson(newRegion))
    if self.rl_qlo_location.tags then self.rl_qlo_location:unregister() end
    storage.rl_qlo_geometry.region = newRegion
    self.rl_qlo_location.region = newRegion
    if storage.rl_qlo_tags and
       regionSizeCheck(storage.rl_qlo_geometry.region) and
       not self.rl_qlo_quest:hasQuest()
    then
      sb.logInfo("rl_questlocationobject: regionScan: registering location %s for new region", entity.uniqueId())
      self.rl_qlo_location:register()
    end
  end
end

local function regionScanDelay()
  return util.randomInRange(config.getParameter("rl_questLocation.regionScanFrequency", {5, 15}))
end

function init()
  if previous_init then previous_init() end

  local questLocation = config.getParameter("rl_questLocation")
  if questLocation.disabled and not storage.rl_qlo_tags then
    sb.logInfo("rl_questlocationobject: init: disabled by config")
    disableQuestLocation()
    return
  end

  local qloConfig = root.assetJson("/rl_belterdungeons.config:questlocationObjects")
  local worldAllowed = qloConfig.allowedWorldTypes[world.type()]
  if not worldAllowed and not storage.rl_qlo_tags then
    sb.logInfo("rl_questlocationobject: init: world type '%s' not allowed", world.type())
    disableQuestLocation()
    return
  end

  self.rl_qlo_region_expandable = questLocation.expandable
  getObjectGeometry()

  local sizeAcceptable = regionSizeCheck(storage.rl_qlo_geometry.boundBox)
  if not sizeAcceptable and
     not self.rl_qlo_region_expandable and
     not storage.rl_qlo_tags
  then
    sb.logInfo("rl_questlocationobject: %s region %s is too small to use as a questlocation", object.name(), sb.printJson(storage.rl_qlo_geometry.region))
    disableQuestLocation()
    return
  end

  self.rl_qlo_waterLiquidIds = qloConfig.waterLiquidIds

  if not entity.uniqueId() then
    object.setUniqueId(sb.makeUuid())
  end

  message.setHandler("broadcastRegion", function() return storage.rl_qlo_geometry.region end)

  self.rl_qlo_locationType = questLocation.locationType
  assert(self.rl_qlo_locationType ~= nil)

  -- Initially `/quests/generated/locations.config` will be used to
  -- populate Location.tags with the original tags. These tags may be
  -- replaced with world-specific alternatives. Later, a timer function
  -- will call `maybeBuildTags` to ensure that the actual tags used will
  -- include up-to-date gravity and breathability information.
  local replacementTagSet = {}
  local replacementTagSetName = qloConfig.replacementTagSetByWorldType[world.type()]
  if replacementTagSetName then
    local tagSets = root.assetJson("/quests/generated/rl_questlocationobject_replacement_tags.config")
    replacementTagSet = tagSets[replacementTagSetName] or {}
  end
  self.rl_qlo_location = Location.new(
    entity.uniqueId(), self.rl_qlo_locationType, storage.rl_qlo_geometry.region
  )
  for i,v in ipairs(self.rl_qlo_location.tags) do
    self.rl_qlo_location.tags[i] = replacementTagSet[v] or v
  end
  self.rl_qlo_locationTypeTags = self.rl_qlo_location.tags
  self.rl_qlo_location.tags = storage.rl_qlo_tags

  self.rl_qlo_timers = TimerManager:new()

  local environmentScanTimer = Timer:new("rl_qlo_environmentScanTimer", {
    delay = environmentScanDelay,
    completeCallback = environmentScan,
    loop = true
  })
  if not environmentScanTimer:active() then
    environmentScanTimer:start()
  end
  self.rl_qlo_timers:manage(environmentScanTimer)

  local questOutbox = Outbox.new("questOutbox", ContactList.new("questContacts"))
  self.rl_qlo_quest = QuestParticipant.new("quest", questOutbox)

  -- If it is possible that a QLO was previously added to the world and
  -- registered itself, and then a mod update changed the rules so the
  -- QLO is no longer valid, we must allow init to complete to allow the
  -- object to unregister itself before disabling the QLO behavior.
  if questLocation.disabled or not worldAllowed then
    sb.logInfo("rl_questlocationobject: init: disabling previously enabled QLO")
    disableQuestLocation()
    return
  end
  if not sizeAcceptable then
    if self.rl_qlo_region_expandable then
      sb.logInfo("Activating expandable object")
      local regionScanTimer = Timer:new("rl_qlo_regionScanTimer", {
        delay = regionScanDelay,
        completeCallback = regionScan,
        loop = true
      })
      if not regionScanTimer:active() then
        regionScanTimer:start()
      end
      self.rl_qlo_timers:manage(regionScanTimer)
    else
      sb.logInfo("rl_questlocationobject: %s region %s is too small to use as a questlocation, disabling", object.name(), sb.printJson(storage.rl_qlo_geometry.region))
      disableQuestLocation()
      return
    end
  end

  local originalScriptDelta = config.getParameter('scriptDelta', 1)
  if originalScriptDelta ~= 10 and #config.getParameter('scripts', {}) < 2 then
    -- If this script file is the only script assigned to this object,
    -- then it doesn't need a faster scriptDelta than 10.
    sb.logInfo("rl_questlocationobject: init: setting update delta to 10")
    script.setUpdateDelta(10)
  elseif originalScriptDelta == 0 or originalScriptDelta > 10 then
    -- Quest location objects require the update function to be called
    -- at least once every 10 ticks. If the object definition sets
    -- scriptDelta to 0 or to more than 10, then set it to 10.
    sb.logInfo("rl_questlocationobject: init: setting update delta to 10")
    script.setUpdateDelta(10)
  end
end

function die(smash)
  if self.rl_qlo_quest then
    sb.logInfo("rl_questlocationobject: die: unregistering location %s", entity.uniqueId())
    if self.rl_qlo_location.tags then self.rl_qlo_location:unregister() end
    sb.logInfo("rl_questlocationobject: die: killing quest participant")
    self.rl_qlo_quest:die()
  end

  if previous_die then previous_die(smash) end
end

function uninit()
  if self.rl_qlo_quest then
    sb.logInfo("rl_questlocationobject: uninit: uniniting quest participant")
    self.rl_qlo_quest:uninit()
  end

  if previous_uninit then previous_uninit() end
end

function update(dt)
  if previous_update then previous_update(dt) end

  if storage.rl_qlo_geometry and storage.rl_qlo_geometry.region then
    util.debugRect(storage.rl_qlo_geometry.region, "cyan")
  end

  if self.rl_qlo_quest then
    self.rl_qlo_timers:update(dt)

    if self.rl_qlo_location:isRegistered() and
       (not regionSizeCheck(storage.rl_qlo_geometry.region) or self.rl_qlo_quest:hasQuest())
    then
      sb.logInfo("rl_questlocationobject: update: temporarily unregistering location %s", entity.uniqueId())
      if self.rl_qlo_location.tags then self.rl_qlo_location:unregister() end
    elseif storage.rl_qlo_tags and
           regionSizeCheck(storage.rl_qlo_geometry.region) and
           not self.rl_qlo_location:isRegistered() and
           not self.rl_qlo_quest:hasQuest()
    then
      sb.logInfo("rl_questlocationobject: update: registering location %s", entity.uniqueId())
      self.rl_qlo_location:register()
    end

    self.rl_qlo_quest:update()
  end
end

-- Called by quests to find a location for entities to be beamed into
-- the world.
function findPosition(boundBox)
  return findSpaceInRect(storage.rl_qlo_geometry.region, boundBox)
end

-- Cloned from `/stagehands/questlocation.lua` verbatim.
local function containerHasSpace(entityId, numSlots)
  -- Gives false negatives on mostly-full chests because it doesn't check if
  -- the new items can stack.
  for i = 0, world.containerSize(entityId) - 1 do
    local slot = world.containerItemAt(entityId, i)
    if not slot or slot.count == 0 then
      numSlots = numSlots - 1
      if numSlots <= 0 then
        return true
      end
    end
  end
  return false
end

-- Called by quests to add treasure to a container. This differs from
-- the stagehand implementation in that it only attempts to place the
-- treasure in the quest location object, and only if the object happens
-- to be a container. If the object is not a container, nothing is added
-- to the world.
function addTreasure(treasurePool, threatLevel)
  threatLevel = threatLevel or world.threatLevel()
  sb.logInfo("rl_dynamic_questlocation: addTreasure: threat level = %s", threatLevel)
  local chest = entity.id()
  if not world.containerSize(chest) then
    sb.logInfo("rl_questlocationobject: addTreasure: object not a container")
    return false
  end
  local treasure = root.createTreasure(treasurePool, threatLevel)
  if not containerHasSpace(chest, #treasure) then
    sb.logInfo("rl_questlocationobject: addTreasure: insufficient space in container object")
    return false
  end
  sb.logInfo("rl_questlocationobject: addTreasure: adding treasure to container object")
  for _,item in pairs(treasure) do
    local overflow = world.containerAddItems(chest, item)
    if overflow then
      world.spawnItem(overflow.name, world.entityPosition(chest), overflow.count, overflow.parameters)
    end
  end
  return true
end
