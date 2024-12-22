local previous_init = init

function init()
  while entity.uniqueId() == nil do
    local tryUniqueId = string.format("rl_beltermechbeacon:%s", sb.makeUuid())
    if world.findUniqueEntity(tryUniqueId):result() == nil then
      object.setUniqueId(tryUniqueId)
    end
  end

  previous_init()
end

if update then
  sb.logWarn("rl_beltermechbeacon: replaced unexpected light 'update' function")
end
function update(dt)
  if xor(storage.state, storage.rl_belterdungeons_registered) then
    if storage.state then
      sb.logInfo("rl_beltermechbeacon: update: registering %s at %s", entity.uniqueId(), entity.position())
    else
      sb.logInfo("rl_beltermechbeacon: update: deregistering %s", entity.uniqueId())
    end
    local mechBeacons = world.getProperty("rl_belterdungeons_mechBeacons", {})
    mechBeacons[entity.uniqueId()] = storage.state and entity.position() or nil
    world.setProperty("rl_belterdungeons_mechBeacons", mechBeacons)
    storage.rl_belterdungeons_registered = storage.state
    broadcastMechBeaconsReset()
  end
end

if die then
  sb.logWarn("rl_beltermechbeacon: replaced unexpected light 'die' function")
end
function die(smash)
  sb.logInfo("rl_beltermechbeacon: die: deregistering %s", entity.uniqueId())
  local mechBeacons = world.getProperty("rl_belterdungeons_mechBeacons", {})
  mechBeacons[entity.uniqueId()] = nil
  world.setProperty("rl_belterdungeons_mechBeacons", mechBeacons)
  broadcastMechBeaconsReset()
end

function broadcastMechBeaconsReset()
  for _, v in ipairs(world.players()) do
    sb.logInfo("rl_beltermechbeacon: broadcastMechBeaconsReset: sending rl_belterdungeons_resetMechBeacons to %s", v)
    world.sendEntityMessage(v, "rl_belterdungeons_resetMechBeacons")
  end
end
