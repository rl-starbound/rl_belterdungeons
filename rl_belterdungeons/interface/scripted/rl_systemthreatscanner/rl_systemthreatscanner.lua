-- While on a celestial world, the result of activating this pane and
-- allowing it to automatically dismiss itself will be to add four
-- properties to the world file: `rl_gangConfig` containing a gang
-- configuration, `rl_starSystemThreatLevel` containing the numeric
-- threat level of the star, and `rl_worldId` containing the string
-- representation of the world coordinates, and `rl_worldSeed`
-- containing the hash of the world ID.
--
-- Note that scripts using these properties MUST be prepared to deal
-- with a nil value by providing sensible defaults.

require "/interface/cockpit/cockpitutil.lua"
require "/scripts/util.lua"

local statusCodes = {
  invalid = 0,       -- should not set value, should not report
  timedOut = 1,      -- should not set value, should report failure
  alreadyExists = 2, -- should not set value, should report success
  success = 3        -- should set value, should report success
}

function init()
  self.playerId = player.id()
  self.threatLevel = 3 -- minimum spaceThreatLevel in `/celestial.config`
  self.ttl = 60

  self.serverUuid = player.serverUuid()
  self.worldId = player.worldId()
  sb.logInfo("rl_systemthreatscanner: init: current world = %s", self.worldId)

  local coordinate = worldIdCoordinate(self.worldId)
  if not coordinate then
    sb.logWarn("rl_systemthreatscanner: init: not a celestial world; terminating")
    self.status = statusCodes.invalid
    pane.dismiss()
    return
  end
  self.systemCoordinate = coordinateSystem(coordinate)
  sb.logInfo("rl_systemthreatscanner: init: current system = %s", self.systemCoordinate)

  local existingWorldId = world.getProperty("rl_worldId")
  if existingWorldId and existingWorldId == self.worldId then
    local existingThreatLevel = world.getProperty("rl_starSystemThreatLevel")
    if existingThreatLevel then
      sb.logInfo("rl_systemthreatscanner: init: threat level already set to %s", existingThreatLevel)
      self.status = statusCodes.alreadyExists
      self.threatLevel = existingThreatLevel
      pane.dismiss()
      return
    end
  end

  self.worldSeed = util.hashString(self.worldId)
  self.gangConfig = generateGang(self.worldSeed)
  sb.logInfo("rl_systemthreatscanner: init: gangConfig = %s", self.gangConfig)
end

function update(dt)
  if not world.entityExists(self.playerId) then
    sb.logWarn("rl_systemthreatscanner: update: player not on world; terminating")
    self.status = statusCodes.invalid
    pane.dismiss()
    return
  end

  -- In theory, this check will never trigger, due to the previous check
  -- triggering, but I am leaving it in for safety.
  if playerChangedWorlds() then
    sb.logWarn("rl_systemthreatscanner: update: player changed worlds; terminating")
    self.status = statusCodes.invalid
    pane.dismiss()
    return
  end

  -- Fetching "planet" parameters for a system coordinate will return
  -- the parameters of the star.
  local starParameters = celestial.planetParameters(self.systemCoordinate)
  if starParameters == nil then
    self.ttl = self.ttl - 1
    if self.ttl <= 0 then
      sb.logWarn("rl_systemthreatscanner: update: timed out")
      self.status = statusCodes.timedOut
      pane.dismiss()
    else
      sb.logInfo("rl_systemthreatscanner: update: loading star parameters; waiting...")
    end
    return
  end
  --sb.logInfo("rl_systemthreatscanner: update: star parameters = %s", starParameters)
  self.threatLevel = math.floor(starParameters.spaceThreatLevel)

  self.status = statusCodes.success
  pane.dismiss()
end

function dismissed()
  if not self.status then
    -- This happens if the user interrupts the execution of the script
    -- pane by hitting `Esc` while it is active. We will treat this as
    -- though the script timed out; the value will not be recorded in
    -- the world properties and the player script will be notified of
    -- the failure.
    self.status = statusCodes.timedOut
  end

  if self.status == statusCodes.invalid then return end

  if self.status == statusCodes.success then
    sb.logInfo("rl_systemthreatscanner: dismissed: threat level = %s", self.threatLevel)
    world.setProperty("rl_gangConfig", self.gangConfig)
    world.setProperty("rl_worldId", self.worldId)
    world.setProperty("rl_worldSeed", self.worldSeed)
    world.setProperty("rl_starSystemThreatLevel", self.threatLevel)
  end

  if world.entityExists(self.playerId) then
    sb.logInfo("rl_systemthreatscanner: dismissed: sending callback")
    world.sendEntityMessage(self.playerId, "rl_systemThreatScannerCallback",
      self.status == statusCodes.alreadyExists or self.status == statusCodes.success
    )
  end
end

-- Partially cloned (with simplification and extension) from
-- `/scripts/bountygeneration.lua`
function generateGang(seed)
  local rand = sb.makeRandomSource(seed)
  local gangConfig = root.assetJson("/quests/bounty/gang.config")

  local prefix = util.randomFromList(gangConfig.genericPrefix, rand)
  local mid = util.randomFromList(gangConfig.genericMid, rand)
  local suffix = util.randomFromList(gangConfig.suffix, rand)

  local majorColor, capstoneColor = rand:randInt(1, 11), rand:randInt(1, 11)
  while capstoneColor == majorColor do
    capstoneColor = rand:randInt(1, 11)
  end

  -- Add species, which is not part of gang config in the base game.
  local multispecies = config.getParameter("gangConfig.multispeciesChance", 0.2)
  sb.logInfo("rl_systemthreatscanner: generateGang: multispecies chance = %s", multispecies)
  local species = config.getParameter("gangConfig.speciesChoices", {
    "apex", "avian", "floran", "glitch", "human", "hylotl", "novakid"
  })
  sb.logInfo("rl_systemthreatscanner: generateGang: species choices = %s", species)
  if multispecies - rand:randf(0.0, 1.0) < 0 then
    species = util.randomFromList(species, rand)
  end

  return {
    name = string.format("%s%s%s", prefix, mid, suffix),
    hat = "bandithat1",
    majorColor = majorColor,
    capstoneColor = capstoneColor,
    species = species,
  }
end

function playerChangedWorlds()
  return self.serverUuid ~= player.serverUuid() or self.worldId ~= player.worldId()
end
