local previous_init = init

function init()
  local tryUniqueId = "rl_beltermechbeaconvalidator"
  if entity.uniqueId() ~= tryUniqueId then
    if not storage.state then
      if world.findUniqueEntity(tryUniqueId):result() == nil then
        object.setUniqueId(tryUniqueId)
      else
        sb.logWarn("rl_beltermechbeaconvalidator: init: not unique; destroying")
        object.smash(true)
      end
    else
      script.setUpdateDelta(0)
    end
  end

  previous_init()

  self.deployTicks = 2
end

if update then
  sb.logWarn("rl_beltermechbeaconvalidator: replaced unexpected light 'update' function")
end
function update(dt)
  if self.deployTicks > 0 then
    self.deployTicks = self.deployTicks - 1
    return
  end

  local mechBeacons = world.getProperty("rl_belterdungeons_mechBeacons", {})
  for k, _ in pairs(mechBeacons) do
    local pos = world.findUniqueEntity(k):result()
    mechBeacons[k] = pos
  end
  world.setProperty("rl_belterdungeons_mechBeacons", mechBeacons)
  broadcastMechBeaconsReset()
  storage.state = true
  setLightState(storage.state)
  script.setUpdateDelta(0)
  object.setUniqueId()
end

function broadcastMechBeaconsReset()
  for _, v in ipairs(world.players()) do
    world.sendEntityMessage(v, "rl_belterdungeons_resetMechBeacons")
  end
end
