-- Identical to the base game version, except adds a `threatLevel`
-- argument, which allows the caller to specify a threat level. If nil,
-- the behvavior is identical to the base game.
function addTreasure(treasurePool, threatLevel)
  threatLevel = threatLevel or world.threatLevel()
  sb.logInfo("rl_dynamic_questlocation: addTreasure: threat level = %s", threatLevel)
  local objectTypes = config.getParameter("treasureChests", {"treasurechest"})
  local treasure = root.createTreasure(treasurePool, threatLevel)
  local chest = findChestWithSpace(objectTypes, treasure)
  if chest then
    for _,item in pairs(treasure) do
      local overflow = world.containerAddItems(chest, item)
      if overflow then
        world.spawnItem(overflow.name, world.entityPosition(chest), overflow.count, overflow.parameters)
      end
    end
    return true
  end

  local position = findSpaceInRect(self.region, {-1, 0, 1, 2})
  if not position then return false end
  local objectType = objectTypes[math.random(#objectTypes)]
  return world.placeObject(objectType, position, nil, {
      treasurePools = {treasurePool}
    })
end
