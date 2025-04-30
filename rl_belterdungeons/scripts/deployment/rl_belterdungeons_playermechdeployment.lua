local previous_init = init
local previous_update = update

function init()
  previous_init()

  self.rl_systemthreatscanner_config = root.assetJson(
    "/interface/scripted/rl_systemthreatscanner/rl_systemthreatscanner.config"
  )

  self.rl_currentWorldId = player.worldId()
  self.rl_isCelestialWorld = rl_worldIdCoordinate(self.rl_currentWorldId)

  message.setHandler("rl_asteroidbeltmanager_completed",
    rl_asteroidbeltmanagerCompleted)

  message.setHandler("rl_belterdungeons_resetMechBeacons", function()
      self.rl_belterdungeons_beaconPositions = nil
    end)

  message.setHandler("rl_systemThreatScannerCallback",
    rl_systemThreatScannerCallback)
end

function update(dt)
  retval = previous_update(dt)
  if retval ~= nil then return retval end

  if self.rl_isCelestialWorld then
    if not self.rl_systemthreatscanner_loaded then
      player.interact("ScriptPane", self.rl_systemthreatscanner_config)
      self.rl_systemthreatscanner_loaded = true
    end

    if self.rl_systemthreatscanner_completed and
       self.rl_belterdungeons_asteroidbeltmanager == nil
    then
      self.rl_belterdungeons_asteroidbeltmanager =
        rl_belterdungeons_asteroidbeltmanager_init()
    end

    if inMech() and self.mechEnergyRatio > 0 then
      if self.rl_belterdungeons_beaconPositions then
        rl_belterdungeons_drawBeacons()
      else
        self.rl_belterdungeons_beaconPositions = world.getProperty(
          "rl_belterdungeons_mechBeacons", {}
        )
      end
    end
  end
end

function rl_belterdungeons_asteroidbeltmanager_init()
  if world.type() ~= "asteroids" then return false end

  if self.rl_belterdungeons_asteroidbeltmanager_loader then
    local status, result = coroutine.resume(
      self.rl_belterdungeons_asteroidbeltmanager_loader,
      self.rl_currentWorldId
    )
    if not status then error(result) end
    if result then
      self.rl_belterdungeons_asteroidbeltmanager_loader = nil
      return result
    end
  else
    self.rl_belterdungeons_asteroidbeltmanager_loader = coroutine.create(
      rl_belterdungeons_asteroidbeltmanager_load
    )
  end
end

function rl_belterdungeons_asteroidbeltmanager_load(worldId)
  local stagehandType = "rl_asteroidbeltmanager"
  local stagehandParameters = {
    parentEntityId = player.id(),
    tryUniqueId = stagehandType,
    worldId = worldId
  }

  while true do
    local findManager = world.findUniqueEntity(stagehandType)
    while not findManager:finished() do coroutine.yield() end
    if findManager:succeeded() then
      -- findUniqueEntity returns the position, about which we do not
      -- care. We only care to validate the existence of the unique Id.
      return stagehandType
    else
      world.spawnStagehand({5, 5}, stagehandType, stagehandParameters)
    end
    coroutine.yield()
  end
end

function rl_belterdungeons_drawBeacons()
  local beaconDetectRadius = 3000
  local pos = entity.position()
  for _, bPos in pairs(self.rl_belterdungeons_beaconPositions) do
    local beaconVec = world.distance(bPos, pos)
    local dist = vec2.mag(beaconVec)
    if dist > 15 and dist < beaconDetectRadius then
      local arrowAngle = vec2.angle(beaconVec)
      local arrowOffset = vec2.withAngle(arrowAngle, 6.5)
      localAnimator.addDrawable({
          image = "/scripts/deployment/rl_belterdungeons_beaconarrow.png",
          rotation = arrowAngle,
          position = arrowOffset,
          fullbright = true,
          centered = true,
          color = {
            255, 255, 255,
            100 + math.floor(50 * (1 - dist / beaconDetectRadius))
          }
        }, "overlay")
      player.radioMessage("rl_belterdungeons-mechBeaconDetected", 5)
    end
  end
end

function rl_asteroidbeltmanagerCompleted(_, _, dungeonsCount)
  if dungeonsCount > 0 then
    player.radioMessage("rl_belterdungeons-dungeonsFound", 1)
  else
    player.radioMessage("rl_belterdungeons-dungeonsNotFound", 1)
  end
end

function rl_systemThreatScannerCallback(_, _, success)
  self.rl_systemthreatscanner_completed = true
end

function rl_worldIdCoordinate(worldId)
  local parts = {}
  for p in string.gmatch(worldId, "-?[%a%d]+") do table.insert(parts, p) end
  if parts[1] == "CelestialWorld" then return true end
  return false
end
