local previous_init = init
local previous_getRentLevel = getRentLevel
local previous_spawn = spawn

-- The clothing with which an NPC is equipped may depend on the NPC's
-- tier, e.g., a tier 1 racial guard is equipped with tier 1 armor.
-- However, for belter NPCs, all clothing is cosmetic, as the NPC's tier
-- and stats are based on the system threat level. This function returns
-- the clothing the NPC would be wearing if spawned in the base game
-- with a fixed tier, to allow for a cosmetic variety of belter NPCs.
local function getTieredItems(species, typeName, level, overrides)
  local items = root.npcConfig(typeName).items or {}
  items = (overrides.items and overrides.items.override) or items.override or items[species] or items.default
  if not items then return end
  local tieredItems
  local currentTier = -1
  for _,v in ipairs(items) do
    if v[1] > currentTier and v[1] <= level then
      currentTier = v[1]
      tieredItems = v[2]
    end
  end
  if tieredItems then
    sb.logInfo("rl_belterdungeons_colonydeed: getTieredItems: %s", sb.printJson(tieredItems))
  end
  return tieredItems
end

function init()
  previous_init()

  local belterColonyDeedsConfig = root.assetJson("/rl_belterdungeons.config:belterColonyDeeds")
  self.rlBelterWorldTypes = belterColonyDeedsConfig.allowedWorldTypes
end

function getRentLevel()
  if self.rlBelterWorldTypes[world.type()] then
    return math.max(world.getProperty("rl_starSystemThreatLevel", 3), previous_getRentLevel())
  end
  return previous_getRentLevel()
end

function spawn(tenant)
  if self.rlBelterWorldTypes[world.type()] then
    sb.logInfo("rl_belterdungeons_colonydeed: using rl_spawnBelterTenant")
    return rl_spawnBelterTenant(tenant)
  end
  return previous_spawn(tenant)
end

-- A heavily modified clone of the `spawn` function that substitutes the
-- tenant type, handles level differently, and preserves rl_recruittimer
-- information if it is present.
function rl_spawnBelterTenant(tenant)
  local npcTypeReplacements = root.assetJson("/objects/spawner/colonydeed/rl_belter_tenants.config")
  local tenantType = npcTypeReplacements[tenant.type]
  if tenantType then
    tenant.type = tenantType
    tenant.isBelterTenant = true
    tenantType = nil
  elseif not tenant.isBelterTenant then
    sb.logInfo("rl_belterdungeons_colonydeed: no belter replacement for %s", tenant.type)
  end

  -- Keep track of type changes, which may occur throughout the lifetime
  -- of the tenant. For this purpose, initial belter type replacement
  -- does not count as a type change.
  tenant.previousType = tenant.previousType or tenant.type

  tenant.overrides = tenant.overrides or {}
  local overrides = tenant.overrides

  -- When a type change happens, don't carry over item overrides because
  -- they may not be compatible with the new type.
  if tenant.previousType ~= tenant.type and overrides.items then
    overrides.items = nil
  end

  local level = math.max(world.getProperty("rl_starSystemThreatLevel", 3), previous_getRentLevel())
  if tenant.level then
    -- In the base game, if a tenant's level is set explicitly, it's a
    -- guard tenant and the level is 1 through 4. Belter tenant guards
    -- are n-1 levels above the system threat level, so a tier 1 guard
    -- has the system threat level, a tier 2 guard has one level above
    -- the system threat, and so forth.
    if tenant.isBelterTenant then
      level = level + util.clamp(tenant.level, 1, 4) - 1
      if tenant.spawn == "npc" then
        local tieredItems = getTieredItems(tenant.species, tenant.type, tenant.level, overrides)
        if tieredItems then
          overrides.items = {
            override = {
              {0, tieredItems}
            }
          }
        end
      end
    else
      -- For a non-belter tenant type with a specified level, default to
      -- the base game behavior.
      level = tenant.level
    end
  end

  if not overrides.damageTeamType then
    overrides.damageTeamType = "friendly"
  end
  if not overrides.damageTeam then
    overrides.damageTeam = 0
  end
  overrides.persistent = true

  local position = {self.position[1], self.position[2]}
  for i,val in ipairs(self.positionVariance) do
    if val ~= 0 then
      position[i] = position[i] + math.random(val) - (val / 2)
    end
  end

  local entityId = nil
  if tenant.spawn == "npc" then
    -- Support rl_recruittimer degraduation
    if tenant.degraduationInfo then
      sb.logInfo("rl_belterdungeons_colonydeed: rl_spawnBelterTenant: adding degraduation info into tenant overrides")
      overrides.scriptConfig = overrides.scriptConfig or {}
      overrides.scriptConfig.questGenerator = overrides.scriptConfig.questGenerator or {}
      overrides.scriptConfig.questGenerator.graduation = overrides.scriptConfig.questGenerator.graduation or {}
      overrides.scriptConfig.questGenerator.graduation.oldNpcItems = tenant.degraduationInfo.oldNpcItems
      overrides.scriptConfig.questGenerator.graduation.oldNpcType = tenant.degraduationInfo.oldNpcType
      overrides.scriptConfig.questGenerator.graduation.timeout = tenant.degraduationInfo.timeout
      tenant.degraduationInfo = nil
    elseif tenant.degraduationInfo == false then
      sb.logInfo("rl_belterdungeons_colonydeed: rl_spawnBelterTenant: removing degraduation info in tenant overrides")
      if overrides.scriptConfig and
         overrides.scriptConfig.questGenerator and
         overrides.scriptConfig.questGenerator.graduation
      then
        overrides.scriptConfig.questGenerator.graduation.oldNpcItems = nil
        overrides.scriptConfig.questGenerator.graduation.oldNpcType = nil
        overrides.scriptConfig.questGenerator.graduation.timeout = nil
        if isEmpty(overrides.scriptConfig.questGenerator.graduation) then
          overrides.scriptConfig.questGenerator.graduation = nil
        end
        if isEmpty(overrides.scriptConfig.questGenerator) then
          overrides.scriptConfig.questGenerator = nil
        end
        if isEmpty(overrides.scriptConfig) then
          overrides.scriptConfig = nil
        end
      end
      tenant.degraduationInfo = nil
    else
      sb.logInfo("rl_belterdungeons_colonydeed: rl_spawnBelterTenant: not altering degraduation info in tenant overrides")
    end

    -- The type change must be processed by this point, and the new type
    -- now becomes the previous type.
    tenant.previousType = tenant.type

    entityId = world.spawnNpc(position, tenant.species, tenant.type, level, tenant.seed, overrides)
    if tenant.personality then
      world.callScriptedEntity(entityId, "setPersonality", tenant.personality)
    else
      tenant.personality = world.callScriptedEntity(entityId, "personality")
    end
    if not tenant.overrides.identity then
      tenant.overrides.identity = world.callScriptedEntity(entityId, "npc.humanoidIdentity")
    end

  elseif tenant.spawn == "monster" then
    if not overrides.seed and tenant.seed then
      overrides.seed = tenant.seed
    end
    if not overrides.level then
      overrides.level = level
    else
      sb.logWarn("rl_belterdungeons_colonydeed: untested edge case: %s", tenant)
    end

    -- The type change must be processed by this point, and the new type
    -- now becomes the previous type.
    tenant.previousType = tenant.type

    entityId = world.spawnMonster(tenant.type, position, overrides)

  else
    sb.logInfo("colonydeed can't be used to spawn entity type '" .. tenant.spawn .. "'")
    return nil
  end

  if tenant.seed == nil then
    tenant.seed = world.callScriptedEntity(entityId, "object.seed")
  end
  return entityId
end
