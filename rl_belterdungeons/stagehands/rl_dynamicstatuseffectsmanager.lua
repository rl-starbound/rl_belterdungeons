require "/scripts/util.lua"

local function getNamespace(dungeonId)
  if type(dungeonId) ~= "number" then
    return "global"
  else
    return math.floor(dungeonId)
  end
end

function init()
  self.privateTemplate = "rl_dynamicstatuseffectsmanager_%s"
  self.propertyTemplate = "rl_dynamicstatuseffects_%s"
  local uniqueName = string.format(self.propertyTemplate, "global")
  if entity.uniqueId() ~= uniqueName then
    if world.findUniqueEntity(uniqueName):result() == nil then
      stagehand.setUniqueId(uniqueName)
    else
      script.setUpdateDelta(0)
      stagehand.die()
    end
  end

  message.setHandler("getEffects", getEffects)
  message.setHandler("setEffects", setEffects)
  message.setHandler("clearEffects", clearEffects)
  message.setHandler("clearAllEffects", clearAllEffects)
end

-- The parameter `dungeonId` is either a numeric dungeon ID or nil; if
-- nil, the global namespace is used. The parameter `effectCategory` is
-- a string naming the status effect category being queried. Returns a
-- dictionary of effect names and values. If the effect is a status
-- effect, its name and value are identical. If the effect is a stat
-- modifier, the name is the stat and the value is the full stat
-- modifier table.
function getEffects(_, _, dungeonId, effectCategory)
  dungeonId = getNamespace(dungeonId)
  local privateName = string.format(self.privateTemplate, dungeonId)

  return (world.getProperty(privateName) or {})[effectCategory] or {}
end

-- The parameter `dungeonId` is either a numeric dungeon ID or nil; if
-- nil, the global namespace is used. The parameter `effectCategory` is
-- a string naming the status effect category being updated.
function setEffects(_, _, dungeonId, effectCategory, effects)
  dungeonId = getNamespace(dungeonId)
  local privateName = string.format(self.privateTemplate, dungeonId)
  local propertyName = string.format(self.propertyTemplate, dungeonId)

  local newEffects = validateStatusEffects(effects)
  local data = world.getProperty(privateName) or jobject()
  data[effectCategory] = newEffects
  world.setProperty(privateName, data)
  local mergedEffects = mergeStatusEffectsCategories(data)
  if #mergedEffects == 0 then mergedEffects = nil end
  world.setProperty(propertyName, mergedEffects)
  broadcastUpdate(dungeonId)
end

-- The parameter `dungeonId` is either a numeric dungeon ID or nil; if
-- nil, the global namespace is used. The parameter `effectCategory` is
-- a string naming the status effect category being updated.
function clearEffects(_, _, dungeonId, effectCategory)
  setEffects(nil, nil, dungeonId, effectCategory, nil)
end

-- The parameter `dungeonId` is either a numeric dungeon ID or nil; if
-- nil, the global namespace is used.
function clearAllEffects(_, _, dungeonId)
  dungeonId = getNamespace(dungeonId)
  local privateName = string.format(self.privateTemplate, dungeonId)
  local propertyName = string.format(self.propertyTemplate, dungeonId)

  world.setProperty(privateName, jobject())
  world.setProperty(propertyName, nil)
  broadcastUpdate(dungeonId)
end

function broadcastUpdate(dungeonId)
  if type(dungeonId) ~= "number" then dungeonId = nil end

  -- A race condition exists here. For approximately the first quarter
  -- second that a world is loaded, the core engine may not correctly
  -- report the players in the world, which means affected players will
  -- not receive change notifications, and thus will not apply the
  -- correct status effects or blocking stats. So, any entity that makes
  -- a change to status effects must refrain from doing so in its init
  -- function and must prevent its update function from making such
  -- changes for the first quarter second that it is loaded.
  for _,player in ipairs(world.players()) do
    --sb.logInfo("rl_dynamicstatuseffectsmanager: sending update for %s to player %s", dungeonId or "global", player)
    world.sendEntityMessage(player, "rl_dynamicstatuseffects_updated",
      dungeonId
    )
  end

  for _,vehicle in ipairs(worldVehicles()) do
    --sb.logInfo("rl_dynamicstatuseffectsmanager: sending update for %s to vehicle %s", dungeonId or "global", vehicle)
    world.sendEntityMessage(vehicle, "rl_dynamicstatuseffects_updated",
      dungeonId
    )
  end
end

function validateStatusEffects(effects)
  if effects then
    local newEffects = jobject()
    for _,effect in ipairs(effects) do
      local effectType = type(effect)
      if effectType == "string" then
        newEffects[effect] = effect
      elseif effectType == "table" and type(effect.stat) == "string" and
        ((type(effect.amount) == "number") or
         (type(effect.baseMultiplier) == "number" and effect.baseMultiplier >= 1) or
         (type(effect.effectiveMultiplier) == "number"))
      then
        local newStatModifier = jobject()
        newStatModifier.stat = effect.stat
        if type(effect.amount) == "number" then
          newStatModifier.amount = effect.amount
        end
        if type(effect.baseMultiplier) == "number" then
          newStatModifier.baseMultiplier = effect.baseMultiplier
        end
        if type(effect.effectiveMultiplier) == "number" then
          newStatModifier.effectiveMultiplier = effect.effectiveMultiplier
        end
        newEffects[effect.stat] = newStatModifier
      else
        sb.logError("rl_dynamicstatuseffectsmanager: " ..
          "ignoring invalid status effect: %s", effect
        )
      end
    end
    return newEffects
  end
end

function mergeStatusEffectsCategories(data)
  local effects = {}
  for _,categories in pairs(data) do
    for effectName,effect in pairs(categories) do
      if type(effect) == "string" then
        effects[effectName] = effect
      else
        local existingEffect = effects[effectName]
        if not existingEffect then
          effects[effectName] = effect
        else
          if effect.amount and existingEffect.amount then
            -- The `amount` value stacks arithmetically.
            effects[effectName] = {
              stat = existingEffect.stat,
              amount = existingEffect.amount + effect.amount
            }
          elseif effect.baseMultiplier and existingEffect.baseMultiplier then
            -- The `baseMultiplier` value is always >= 1 (i.e., a base
            -- multiplier of 1.1 adds 10% to the base value), so when
            -- adding two base multipliers, subtract 1.
            effects[effectName] = {
              stat = existingEffect.stat,
              baseMultiplier = existingEffect.baseMultiplier + effect.baseMultiplier - 1
            }
          elseif effect.effectiveMultiplier and existingEffect.effectiveMultiplier then
            -- The `effectiveMultiplier` value stacks geometrically.
            effects[effectName] = {
              stat = existingEffect.stat,
              effectiveMultiplier = existingEffect.effectiveMultiplier * effect.effectiveMultiplier
            }
          else
            -- Determining which effect has the "correct" stat value is
            -- intractable so just assume the first one was correct and
            -- ignore subsequent "wrong" effects.
            sb.logError("rl_dynamicstatuseffectsmanager: " ..
              "failed merging status effects: %s and %s",
              existingEffect, effect
            )
          end
        end
      end
    end
  end
  return util.values(effects)
end

function worldVehicles()
  return world.entityQuery({0,0}, world.size(), {includedTypes={"vehicle"}})
end
