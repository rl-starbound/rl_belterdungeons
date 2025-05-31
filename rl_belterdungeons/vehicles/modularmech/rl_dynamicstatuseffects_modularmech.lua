local previous_init = init
local previous_update = update

-- This duplicates some code in the base game's init function because
-- that `hazards` variable was local-only so it's not visible outside
-- the main init function.
local function buildHazardVulnerabilities()
  local hazards = config.getParameter("hazardVulnerabilities")
  for _, statusEffect in pairs(self.parts.body.hazardImmunities or {}) do
    hazards[statusEffect] = nil
  end
  return hazards
end

-- Merges the dynamic status effect hazards into a single set. Excludes
-- all hazards that have a dynamic blocking stat in effect, or that were
-- already accounted for in the world hazards.
local function mergeDynamicHazards()
  local blockingStats = {}

  for _,v in ipairs(self.rlDynamicStatusEffects.globalEffects) do
    if type(v) == "table" and v.amount and v.amount > 0 then
      local blockingStat = config.getParameter("hazardProtection", {})[v.stat]
      if blockingStat then blockingStats[blockingStat] = true end
    end
  end

  local dungeonEffects = self.rlDynamicStatusEffects.dungeonEffects[
    self.rlDynamicStatusEffects.currentDungeonId
  ]
  for _,v in ipairs(dungeonEffects) do
    if type(v) == "table" and v.amount and v.amount > 0 then
      local blockingStat = config.getParameter("hazardProtection", {})[v.stat]
      if blockingStat then blockingStats[blockingStat] = true end
    end
  end

  local worldStatusEffects = world.environmentStatusEffects({0, 0})
  local effects = {}

  for _,v in ipairs(self.rlDynamicStatusEffects.globalEffects) do
    if type(v) == "string" and self.hazardVulnerabilities[v] and
       not blockingStats[v] and not contains(worldStatusEffects, v)
    then
      effects[v] = true
    end
  end

  for _,v in ipairs(dungeonEffects) do
    if type(v) == "string" and self.hazardVulnerabilities[v] and
       not blockingStats[v] and not contains(worldStatusEffects, v)
    then
      effects[v] = true
    end
  end

  return effects
end

-- Builds the current set of hazards. Notifies the player of any hazards
-- that were not present at the previous check.
local function buildDynamicHazards()
  local newHazards = mergeDynamicHazards()
  for statusEffect,_ in pairs(newHazards) do
    if not self.rlDynamicStatusEffectsHazardsPrevious[statusEffect] then
      world.sendEntityMessage(self.ownerEntityId, "queueRadioMessage",
        self.hazardVulnerabilities[statusEffect].message, 1.5
      )
    end
  end
  self.rlDynamicStatusEffectsHazards = util.keys(newHazards)
  self.rlDynamicStatusEffectsHazardsPrevious = newHazards
end

function init()
  previous_init()

  self.hazardVulnerabilities = buildHazardVulnerabilities()

  self.rlDynamicStatusEffects = {
    currentDungeonId = nil,
    dungeonEffects = {},
    globalEffects = nil
  }
  self.rlDynamicStatusEffectsHazards = {}
  self.rlDynamicStatusEffectsHazardsPrevious = {}

  -- Interval between searches for dynamic status effects
  self.rlDynamicStatusEffectSearchTime = 1

  -- Wait a short time before doing the first search to allow the world
  -- to fully load.
  self.rlDynamicStatusEffectSearchTimer = 0.5

  message.setHandler("rl_dynamicstatuseffects_updated", rlDynamicStatusEffectsUpdated)
end

function update(dt)
  previous_update(dt)

  -- This script should only be included for player mechs, not NPC
  -- mechs, so we can skip checking for NPC mechs.
  if alive() and storage.energy > 0 and self.driverId then
    self.rlDynamicStatusEffectSearchTimer = self.rlDynamicStatusEffectSearchTimer - dt
    if self.rlDynamicStatusEffectSearchTimer <= 0 then
      local triggerRebuild = false

      if not self.rlDynamicStatusEffects.globalEffects then
        self.rlDynamicStatusEffects.globalEffects = world.getProperty(
          "rl_dynamicstatuseffects_global"
        ) or {}
        --sb.logInfo("rl_dynamicstatuseffects_modularmech: fetched global effects: %s", sb.printJson(self.rlDynamicStatusEffects.globalEffects))
        triggerRebuild = true
      end

      local dungeonId = world.dungeonId(mcontroller.position())
      if dungeonId ~= self.rlDynamicStatusEffects.currentDungeonId then
        --sb.logInfo("rl_dynamicstatuseffects_modularmech: changing dungeon to %s", dungeonId)
        if not self.rlDynamicStatusEffects.dungeonEffects[dungeonId] then
          self.rlDynamicStatusEffects.dungeonEffects[dungeonId] = world.getProperty(
            string.format("rl_dynamicstatuseffects_%d", dungeonId)
          ) or {}
          --sb.logInfo("rl_dynamicstatuseffects_modularmech: fetched dungeon %s effects: %s", dungeonId, sb.printJson(self.rlDynamicStatusEffects.dungeonEffects[dungeonId]))
        end
        triggerRebuild = true
      end
      self.rlDynamicStatusEffects.currentDungeonId = dungeonId

      if triggerRebuild then buildDynamicHazards() end
      self.rlDynamicStatusEffectSearchTimer = self.rlDynamicStatusEffectSearchTime
    end

    rlDynamicStatusEffectsApply(dt)
  end
end

function rlDynamicStatusEffectsApply(dt)
  if self.environmentStatusHealthDrain ~= nil then
    -- RL Mech Overhaul Reborn compatibility.
    rlDynamicStatusEffectsApplyMechOverhaulReborn(dt)
  elseif activateFUMechStats ~= nil then
    -- Frackin Universe compatibility
    rlDynamicStatusEffectsApplyFrackin(dt)
  elseif storage.health ~= nil then
    -- MechOverhaul compatibility.
    rlDynamicStatusEffectsApplyMechOverhaul(dt)
  else
    -- Base game compatibility.
    rlDynamicStatusEffectsApplyBaseGame(dt)
  end
end

function rlDynamicStatusEffectsApplyMechOverhaulReborn(dt)
  local healthDrain = 0
  for _,statusEffect in ipairs(self.rlDynamicStatusEffectsHazards) do
    healthDrain = healthDrain + self.hazardVulnerabilities[statusEffect].energyDrain
  end

  storage.health = math.max(0, storage.health - (0.5 * healthDrain) * dt)
  if storage.health == 0 then
    explode()
    return
  end
end

function rlDynamicStatusEffectsApplyFrackin(dt)
  -- FU modularmech.lua defines a `regenPenalty` but never uses it, so
  -- ignore this for now.
  --local regenPenalty = 0

  local energyDrain = 0
  local healthDrain = 0

  for _,statusEffect in ipairs(self.rlDynamicStatusEffectsHazards) do
    -- FU modularmech.lua defines a `regenPenalty` but never uses it, so
    -- ignore this for now.
    --regenPenalty = self.hazardVulnerabilities[statusEffect].energyDrain or 0

    energyDrain = energyDrain + self.hazardVulnerabilities[statusEffect].energyDrain
    healthDrain = 0.1
  end

  if healthDrain > 0 then
    -- It's reasonable to assume that `totalMass` has been called by the
    -- main update function already.
    --totalMass()

    if self.massTotal > 47 then
      healthDrain = 0.05
    elseif self.massTotal > 44 then
      healthDrain = 0.2
    elseif self.massTotal > 36 then
      healthDrain = 0.5
    elseif self.massTotal > 29 then
      healthDrain = 0.65
    elseif self.massTotal > 22 then
      healthDrain = 0.75
    else
      healthDrain = 1
    end
    storage.health = storage.health - healthDrain
    storage.energy = storage.energy - (healthDrain / 8)
  end

  if self.flightMode and world.gravity(mcontroller.position()) ~= 0 then
    energyDrain = energyDrain * 2
  elseif not self.flightMode and world.gravity(mcontroller.position()) ~= 0 then
    energyDrain = energyDrain * 0.5
  end

  -- Without reimplementing a very large amount of code from the main
  -- update function, we cannot tell whether the controls have been
  -- touched in the previous tick, so just assume they have.
  --if not hasTouched(newControls) and not hasTouched(oldControls) and not self.manualFlightMode then
  --  energyDrain = 0
  --end

  -- Only apply 50% of the energy drain here, to make up for the fact
  -- that we can't tell if the player was using the controls.
  storage.energy = math.max(0, storage.energy - (0.5 * energyDrain) * dt)

  world.sendEntityMessage(self.ownerEntityId, "setQuestFuelCount", storage.energy)

  if storage.health == 0 then
    explode()
    return
  end

  if storage.energy <= 0 then
    self.energyBackPlayed = false
    self.leftArm.bobLocked = true
    self.rightArm.bobLocked = true
    animator.setAnimationState("boost", "idle")
    animator.setLightActive("boostLight", false)
    animator.stopAllSounds("step")
    animator.stopAllSounds("jump")
    if not self.energyOutPlayed then
      animator.setAnimationState("power", "deactivate")
      animator.playSound("energyout")
      self.energyOutPlayed = true
    end

    for _, arm in pairs({"left", "right"}) do
      animator.resetTransformationGroup(arm .. "Arm")
      animator.resetTransformationGroup(arm .. "ArmFlipper")

      self[arm .. "Arm"]:updateBase(dt, self.driverId, false, false, self.aimPosition, self.facingDirection, self.crouch * self.bodyCrouchMax)
      self[arm .. "Arm"]:update(dt)
    end
    return
  end
end

function rlDynamicStatusEffectsApplyMechOverhaul(dt)
  local energyDrain = 0
  for _,statusEffect in ipairs(self.rlDynamicStatusEffectsHazards) do
    energyDrain = energyDrain + self.hazardVulnerabilities[statusEffect].energyDrain
  end

  -- Without reimplementing a very large amount of code from the main
  -- update function, we cannot tell whether the controls have been
  -- touched in the previous tick, so just assume they have.
  --if not hasTouched(newControls) and not hasTouched(oldControls) and not self.manualFlightMode then
  --  energyDrain = 0
  --end

  -- Only apply 50% of the energy drain here, to make up for the fact
  -- that we can't tell if the player was using the controls.
  storage.energy = math.max(0, storage.energy - (0.5 * energyDrain) * dt)
  world.sendEntityMessage(self.ownerEntityId, "setQuestFuelCount", storage.energy)

  if storage.energy <= 0 then
    self.energyBackPlayed = false
    self.leftArm.bobLocked = true
    self.rightArm.bobLocked = true
    animator.setAnimationState("boost", "idle")
    animator.setLightActive("boostLight", false)
    animator.stopAllSounds("step")
    animator.stopAllSounds("jump")
    if not self.energyOutPlayed then
      animator.setAnimationState("power", "deactivate")
      animator.playSound("energyout")
      self.energyOutPlayed = true
    end
    animator.setLightActive("mechChipLight", false)

    local chains = {}

    for _, arm in pairs({"left", "right"}) do
      animator.resetTransformationGroup(arm .. "Arm")
      animator.resetTransformationGroup(arm .. "ArmFlipper")

      self[arm .. "Arm"]:updateBase(dt, self.driverId, false, false, self.aimPosition, self.facingDirection, self.crouch * self.bodyCrouchMax)
      self[arm .. "Arm"]:update(dt)

      if self[arm .. "Arm"].renderChain then
        table.insert(chains, self[arm .. "Arm"].chain)
      end
    end

    vehicle.setAnimationParameter("chains", chains)
    return
  end
end

function rlDynamicStatusEffectsApplyBaseGame(dt)
  local energyDrain = 0
  for _,statusEffect in ipairs(self.rlDynamicStatusEffectsHazards) do
    energyDrain = energyDrain + self.hazardVulnerabilities[statusEffect].energyDrain
  end

  storage.energy = math.max(0, storage.energy - energyDrain * dt)
  if storage.energy == 0 then
    despawn()
    return
  end
end

function rlDynamicStatusEffectsUpdated(_, _, dungeonId)
  --sb.logInfo("rl_dynamicstatuseffects_modularmech: received update for %s", dungeonId or "global")
  if not dungeonId then
    self.rlDynamicStatusEffects.globalEffects = nil
  else
    self.rlDynamicStatusEffects.dungeonEffects[dungeonId] = nil
    if dungeonId == self.rlDynamicStatusEffects.currentDungeonId then
      self.rlDynamicStatusEffects.currentDungeonId = nil
    end
  end
  self.rlDynamicStatusEffectSearchTimer = 0
end
