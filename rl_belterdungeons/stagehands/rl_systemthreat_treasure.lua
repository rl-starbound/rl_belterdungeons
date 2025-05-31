require "/scripts/rect.lua"
require "/scripts/util.lua"

function init()
  -- This stagehand allows the population of a container with treasure
  -- at threat level equal to the star system threat level, which may be
  -- higher than the world threat level.

  self.region = rect.translate(
    config.getParameter("broadcastArea"), entity.position()
  )
  -- Bias the region slightly to the bottom left to reduce the chance of
  -- intersecting containers other than the target. Most containers use
  -- the bottom left or bottom center point as their origin position.
  -- This heuristic is not perfect, and dungeon designers must be aware
  -- of the origin positions of the target container and other nearby
  -- containers when configuring this stagehand.
  self.region[3] = self.region[3] - 0.03125
  self.region[4] = self.region[4] - 0.03125
  self.centroid = rect.center(self.region)

  -- `treasurePools` must be a JSON list of the treasure pool names to
  -- be spawned.
  self.treasurePools = config.getParameter("treasurePools")

  local worldSeed = world.getProperty("rl_worldSeed") or
                    util.hashString(sb.makeUuid())

  -- In the context of celestial worlds, use the world seed as the basis
  -- for the item seeds. In all other contexts, use a random seed.
  self.seed = util.hashString(worldSeed .. util.tableToString(self.region))

  self.level = math.max(
    world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
  )
end

function update(dt)
  local containers = world.objectQuery(
    rect.ll(self.region), rect.ur(self.region),
    {boundMode = "position" , order = "nearest"}
  )
  containers = util.filter(containers, function(entityId)
      return world.containerSize(entityId) ~= nil
    end)
  if #containers == 0 then
    sb.logWarn("rl_systemthreat_treasure: update: no container found at %s",
      self.region
    )
    stagehand.die()
    return
  end
  local container = containers[1]

  local numSpawned = 0
  for _, v in ipairs(self.treasurePools) do
    local spawned = world.spawnTreasure(
      self.centroid, v, self.level, self.seed
    )
    if spawned ~= nil then
      numSpawned = numSpawned + #spawned
    end
  end

  -- According to the documentation, we should get the entity IDs
  -- directly from the return value of world.spawnTreasure, but in
  -- practice, that function only returns a list of 0s, so we need to
  -- query for item drops within the region and assume that all such
  -- drops were those we spawned, and that all drops we spawned are
  -- still in the region.
  local treasureItems = world.itemDropQuery(
    rect.ll(self.region), rect.ur(self.region)
  )
  if #treasureItems ~= numSpawned then
    sb.logWarn("rl_systemthreat_treasure: update: " ..
      "spawned item count (%s) does not match queried item count (%s)",
      numSpawned, #treasureItems
    )
  end

  for _, v in ipairs(treasureItems) do
    local itemDrop = world.takeItemDrop(v)
    if itemDrop ~= nil then
      -- First, try to stack the item with similar items.
      itemDrop = world.containerStackItems(container, itemDrop)
      if itemDrop ~= nil then
        -- Next, add the item to an empty container slot.
        itemDrop = world.containerAddItems(container, itemDrop)
        if itemDrop ~= nil then
          -- If we get here, the item has been removed from the world,
          -- but was not able to be put into the container, so it has
          -- been lost.
          sb.logWarn("rl_systemthreat_treasure: update: lost item %s",
            itemDrop
          )
        end
      end
    end
  end
  stagehand.die()
end
