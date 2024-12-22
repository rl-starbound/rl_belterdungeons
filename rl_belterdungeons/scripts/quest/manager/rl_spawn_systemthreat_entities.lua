require("/scripts/quest/manager/spawn_entities.lua")
require("/scripts/quest/rl_positional_text_generation.lua")

SpawnSystemThreatEntities = subclass(SpawnEntities, "SpawnSystemThreatEntities")

function SpawnSystemThreatEntities:init(...)
  SpawnEntities.init(self, ...)

  self.data.playersWaiting = self.data.playersWaiting or {}

  if self.config.triggeredBy == "message" then
    message.setHandler("rl_triggerSpawnEntities", function (_, _, ...) self:triggerSpawn(...) end)
  end
end

-- Modified from the base game function `spawnEntity` in the file
-- `/scripts/quest/manager/spawn_entites.lua` by 1) using star system
-- threat level instead of world threat level; 2) removing miniboss
-- scaling and visual effects; 3) configuring "gangmember" NPCs.
local function spawnSystemThreatEntity(spawnConfig)
  local parameters = shallowCopy(spawnConfig.parameters)
  if type(spawnConfig.parameters.scriptConfig) == "table" then
    parameters.scriptConfig = shallowCopy(spawnConfig.parameters.scriptConfig)
  end
  parameters.level = (parameters.level or math.max(world.getProperty("rl_starSystemThreatLevel", 3), world.threatLevel())) + (spawnConfig.levelBoost or 0)

  local typeName = spawnConfig.typeName
  local species = spawnConfig.species
  if type(typeName) == "table" then
    typeName = typeName[math.random(#typeName)]
  end
  if type(species) == "table" then
    species = species[math.random(#species)]
  end

  local entityId = nil
  if spawnConfig.entityType == "monster" then
    parameters.aggressive = spawnConfig.aggressive

    if spawnConfig.miniboss then
      parameters.level = parameters.level + 1
      parameters.aggressive = true
      parameters.capturable = false
    end

    if spawnConfig.evolve then
      local monsterEvolution = root.assetJson("/quests/quests.config:spawnEntities.monsterEvolution")
      typeName = monsterEvolution[typeName] or typeName
      parameters.level = parameters.level + 1
    end

    entityId = world.spawnMonster(typeName, entity.position(), parameters)
  else
    assert(spawnConfig.entityType == "npc")

    if typeName == "gangmember" then
      parameters.scriptConfig = parameters.scriptConfig or {}
      parameters.scriptConfig.gang = world.getProperty("rl_gangConfig") or {
        name = "Chaotic Crime Collective",
        hat = "bandithat1",
        majorColor = 1,
        capstoneColor = 2,
        species = {
          "apex", "avian", "floran", "glitch", "human", "hylotl", "novakid"
        }
      }
      species = parameters.scriptConfig.gang.species
      parameters.scriptConfig.gang.species = nil
      if type(species) == "table" then
        species = species[math.random(#species)]
      end
    end

    entityId = world.spawnNpc(entity.position(), species, typeName, parameters.level, spawnConfig.seed, parameters)
  end

  for category, effects in pairs(spawnConfig.statusEffects) do
    world.callScriptedEntity(entityId, "status.addPersistentEffects", category, effects)
  end
  return entityId
end

-- This should be identical to the version in the base game's
-- SpawnEntities class, with the exception of calling the function
-- `spawnSystemThreatEntity` instead of `spawnEntity`.
function SpawnSystemThreatEntities:spawnUnique(evolve, miniboss, statusEffects, extraDrops)
  local entitySpawnConfig = {
      evolve = evolve,
      miniboss = miniboss
    }

  if self.config.spawnParameter then
    local param = self.questParameters[self.config.spawnParameter]
    if param.type == "npcType" then
      entitySpawnConfig.entityType = "npc"
    else
      assert(param.type == "monsterType")
      entitySpawnConfig.entityType = "monster"
    end
    entitySpawnConfig.species = param.species
    entitySpawnConfig.typeName = param.typeName
    entitySpawnConfig.parameters = param.parameters or {}
    entitySpawnConfig.seed = param.seed
  else
    entitySpawnConfig.entityType = self.config.entityType
    entitySpawnConfig.species = self.config.species
    entitySpawnConfig.typeName = self.config.typeName
    entitySpawnConfig.parameters = self.config.parameters or {}
  end
  entitySpawnConfig.aggressive = self.config.aggressive
  if self.config.persistent then
    entitySpawnConfig.parameters.persistent = true
  end
  entitySpawnConfig.levelBoost = self.config.levelBoost
  entitySpawnConfig.statusEffects = statusEffects
  local entityId = spawnSystemThreatEntity(entitySpawnConfig)

  if entitySpawnConfig.entityType == "npc" then
    world.callScriptedEntity(entityId, "status.addEphemeralEffect", "beamin")
  end

  if self.config.drops then
    local drops = self.config.drops
    if type(drops) == "string" then
      drops = self.questParameters[drops].items
    end
    assert(drops ~= nil)
    world.callScriptedEntity(entityId, "addDrops", drops)
  end
  if extraDrops then
    world.callScriptedEntity(entityId, "addDrops", extraDrops)
  end

  local uniqueId = sb.makeUuid()
  world.setUniqueId(entityId, uniqueId)

  for _,relationship in pairs(self.config.relationships or {}) do
    local relationName, converse, relatee = table.unpack(relationship)
    local relateeUniqueId = self.questParameters[relatee].uniqueId
    local relateeEntityId = relateeUniqueId and world.loadUniqueEntity(relateeUniqueId)
    if relateeEntityId and world.entityExists(relateeEntityId) then
      world.callScriptedEntity(entityId, "addRelationship", relationName, converse, relateeUniqueId)
      world.callScriptedEntity(relateeEntityId, "addRelationship", relationName, not converse, uniqueId)
    end
  end

  self.justSpawned = true
  self.data.entitiesNeedReserving = entitySpawnConfig.entityType == "npc"
  self.data.entitiesAvailable = entitySpawnConfig.entityType ~= "npc"
  sb.logInfo("rl_spawn_systemthreat_entities: spawnUnique: spawned uniqueId: %s", uniqueId)
  return uniqueId, entityId
end

-- This should be identical to the version in the base game's
-- SpawnEntities class, but with the addition of position variance for
-- rect.center positions.
function SpawnSystemThreatEntities:findPosition(boundBox)
  assert(self.config.positionParameter ~= nil)
  local positionParam = self.questParameters[self.config.positionParameter]
  assert(positionParam.uniqueId ~= nil)

  if positionParam.type == "location" then
    local locationEntityId = world.loadUniqueEntity(positionParam.uniqueId)
    local position = world.callScriptedEntity(locationEntityId, "findPosition", boundBox)
    if position then
      return position
    end

    -- The zero-G stagehands should fall through to this because there
    -- should be no "ground" within or adjacent to the region.
    assert(positionParam.region)
    position = rect.center(positionParam.region)
    if self.config.positionVariance then
      position = {
        position[1] + util.randomInRange({-self.config.positionVariance[1], self.config.positionVariance[1]}),
        position[2] + util.randomInRange({-self.config.positionVariance[2], self.config.positionVariance[2]})
      }
    end
    return position
  else
    return world.findUniqueEntity(positionParam.uniqueId):result()
  end
end

-- This should be identical to the version in the base game's
-- SpawnEntities class, but should additionally calculate the system
-- threat level and pass that to the addTreasure call.
function SpawnSystemThreatEntities:spawnTreasure(config)
  local searchCenter = rect.center(self.questParameters[self.config.positionParameter].region)
  if not searchCenter then return nil end
  local locations = Location.search(searchCenter, nil, config.minDistance, config.maxDistance)
  if #locations == 0 then return nil end

  local location = locations[math.random(#locations)]
  local entityId = world.loadUniqueEntity(location.uniqueId)
  local threatLevel = math.max(world.getProperty("rl_starSystemThreatLevel", 3), world.threatLevel())
  if world.callScriptedEntity(entityId, "addTreasure", config.treasurePool, threatLevel) then
    return location
  end
end

function SpawnSystemThreatEntities:generateTreasureNote(location)
  local textGenerator = positionalQuestTextGenerator(self.questDescriptor,
    rect.center(self.questParameters[self.config.positionParameter].region)
  )
  local templates = questNoteTemplates(self.templateId, "treasureNote")
  return generateNoteItem(templates, nil, textGenerator)
end

-- In the base game, SpawnEntities always spawns its entities on quest
-- start. In this subclass we provide a mechanism to delay the spawning
-- until a trigger event has occurred in the quest.
function SpawnSystemThreatEntities:questStarted()
  sb.logInfo("rl_spawn_systemthreat_entities: questStarted")
  if self.config.triggeredBy == "questStart" or self.config.triggeredBy == nil then
    sb.logInfo("rl_spawn_systemthreat_entities: questStarted: spawning")
    SpawnEntities.questStarted(self)
    self.data.hasTriggered = true
  end
end

function SpawnSystemThreatEntities:triggerSpawn(group)
  assert(self.config.triggeredBy == "message")
  if self.data.hasTriggered then return end
  sb.logInfo("rl_spawn_systemthreat_entities: triggerSpawn: %s", group)
  if group == self.config.group then
    sb.logInfo("rl_spawn_systemthreat_entities: triggerSpawn: spawning: %s", group)
    -- First, check that the questlocation entity still exists. If it
    -- was removed between when the quest was accepted and when it was
    -- triggered, the quest must be aborted.
    local locationEntityId = world.loadUniqueEntity(
      self.questParameters[self.config.positionParameter].uniqueId
    )
    if not world.entityExists(locationEntityId) then
      self.questManager:cancel("questlocationRemoved")
      return
    end

    SpawnEntities.questStarted(self)
    self.data.hasTriggered = true

    for player,_ in pairs(self.data.playersWaiting) do
      -- Send player the profiles of the spawned entities.
      self.questManager:sendToPlayer(player, "updateParameters",
        self.questManager:questParameters(self.questId)
      )

      -- Reserve participant entities and notify player that they have spawned.
      self:playerStarted(player)

      -- Behavior overrides are added by participants' playerStarted handlers.
      self.questManager:sendToParticipants("playerStarted", player,
        self.questId, self.questManager:questParameters(self.questId)
      )
    end
    self.data.playersWaiting = {}
  end
end

function SpawnSystemThreatEntities:playerStarted(player)
  if not self.data.hasTriggered then
    sb.logInfo("rl_spawn_systemthreat_entities: playerStarted: waiting: %s", player)
    self.data.playersWaiting[player] = true
  else
    sb.logInfo("rl_spawn_systemthreat_entities: playerStarted: started %s", player)
    SpawnEntities.playerStarted(self, player)
  end
end

function SpawnSystemThreatEntities:playerFinished(player)
  self.data.playersWaiting[player] = nil
  SpawnEntities.playerFinished(self, player)
end
