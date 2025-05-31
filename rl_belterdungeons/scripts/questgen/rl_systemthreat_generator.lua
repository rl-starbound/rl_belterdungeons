require("/scripts/questgen/generator.lua")
require("/scripts/questgen/rl_systemthreat_predicands.lua")
require("/scripts/questgen/rl_systemthreat_relations.lua")

SystemThreatQuestGenerator = subclass(QuestGenerator, "SystemThreatQuestGenerator")

function SystemThreatQuestGenerator:init(...)
  QuestGenerator.init(self, ...)
end

-- Should be identical to the base class except for added support for
-- the TemporarySystemThreatNpc predicand.
function SystemThreatQuestGenerator:generateUniqueIds(planner, plan)
  for _, operation in ipairs(plan) do
    for key, symbol in pairs(operation.symbols) do
      local predicand = Predicand.value(operation.symbols[key])
      match (predicand) {
        [QuestPredicands.Entity] = function (entity)
            local uniqueId = entity:uniqueId()
            if not uniqueId then
              uniqueId = sb.makeUuid()
              entity:setUniqueId(uniqueId)
            end
          end,

        [QuestPredicands.TemporaryNpc] = function (npc)
            local entityId = npc:spawn()
            local uniqueId = sb.makeUuid()
            npc.entityId = entityId
            npc.uniqueId = uniqueId
            world.setUniqueId(entityId, uniqueId)
            local entity = QuestPredicands.Entity.new(planner.context, entityId, uniqueId)
            planner.context:markEntityUsed(entity, true)
          end,

        [QuestPredicands.TemporarySystemThreatNpc] = function (npc)
            local entityId = npc:spawn()
            local uniqueId = sb.makeUuid()
            npc.entityId = entityId
            npc.uniqueId = uniqueId
            world.setUniqueId(entityId, uniqueId)
            local entity = QuestPredicands.Entity.new(planner.context, entityId, uniqueId)
            planner.context:markEntityUsed(entity, true)
          end,

        default = function () end
      }
    end
  end

  -- Wait one more tick so that any uniqueIds we've just set are ready for use.
  coroutine.yield()

  return plan
end

-- Should be identical to the base class except for added support for
-- the TemporarySystemThreatNpc predicand.
function SystemThreatQuestGenerator:generateParameter(templateId, paramName, parameterDef, predicand)
  local value = Predicand.value(predicand)
  local param = match (value) {
    [QuestPredicands.Item] = function (item)
        return {
            type = "item",
            item = {
                name = item.itemName,
                parameters = item.parameters
              },
            name = root.itemConfig(item.itemName).shortdescription
          }
      end,

    [QuestPredicands.ItemTag] = function (itemTag)
        return {
            type = "itemTag",
            tag = itemTag.tag,
            name = itemTag.name
          }
      end,

    [QuestPredicands.ItemList] = function (itemList)
        return {
            type = "itemList",
            items = itemList:toJson()
          }
      end,

    [QuestPredicands.NullEntity] = function ()
        return {
            type = "entity"
          }
      end,

    [QuestPredicands.Entity] = function (entity)
        local uniqueId = entity:uniqueId()
        assert(uniqueId ~= nil)
        local entityId = entity:entityId()
        return {
            type = "entity",
            uniqueId = uniqueId,
            species = world.entitySpecies(entityId),
            gender = world.entityGender(entityId),
            name = world.entityName(entityId),
            portrait = world.entityPortrait(entityId, "full")
          }
      end,

    [QuestPredicands.TemporaryNpc] = function (npc)
        local uniqueId = npc.uniqueId
        local entityId = npc.entityId
        assert(uniqueId ~= nil and entityId ~= nil and world.entityExists(entityId))
        return {
            type = "entity",
            uniqueId = uniqueId,
            species = world.entitySpecies(entityId),
            gender = world.entityGender(entityId),
            name = world.entityName(entityId),
            portrait = world.entityPortrait(entityId, "full")
          }
      end,

    [QuestPredicands.TemporarySystemThreatNpc] = function (npc)
        local uniqueId = npc.uniqueId
        local entityId = npc.entityId
        assert(uniqueId ~= nil and entityId ~= nil and world.entityExists(entityId))
        return {
            type = "entity",
            uniqueId = uniqueId,
            species = world.entitySpecies(entityId),
            gender = world.entityGender(entityId),
            name = world.entityName(entityId),
            portrait = world.entityPortrait(entityId, "full")
          }
      end,

    [QuestPredicands.Location] = function (location)
        return {
            type = "location",
            region = location.region,
            name = location.name,
            uniqueId = location.uniqueId
          }
      end,

    [QuestPredicands.NpcType] = function (npcType)
        local seed = npcType.seed
        if seed == "stable" then
          seed = generateSeed()
        end
        return {
            type = "npcType",
            name = npcType.name,
            species = npcType.species,
            typeName = npcType.typeName,
            parameters = npcType.parameters,
            seed = seed,
            portrait = npcType:portrait(seed)
          }
      end,

    [QuestPredicands.MonsterType] = function (monsterType)
        local parameters = shallowCopy(monsterType.parameters)
        if parameters.seed == "stable" then
          parameters.seed = generateSeed()
        end
        return {
            type = "monsterType",
            name = monsterType.name,
            typeName = monsterType.typeName,
            parameters = parameters,
            portrait = monsterType:portrait(parameters.seed)
          }
      end,

    default = function ()
        if type(value) == "string" then
          return {
              type = "noDetail",
              name = value
            }
        else
          error("Invalid "..paramName.." parameter for quest "..templateId..": "..tostring(value))
        end
      end
  }

  if parameterDef.type and parameterDef.type ~= param.type then
    error("Quest generator expected param type "..parameterDef.type.." but generated "..param.type)
  end

  -- Fill in defaults from the param def (e.g. the indicator icon)
  for key, value in pairs(parameterDef) do
    if not param[key] and key ~= "example" then
      param[key] = value
    end
  end

  return param
end

-- Modified from the base class to use the higher of star system threat
-- level or world threat level when creating the reward bag.
function SystemThreatQuestGenerator:createRewardBag(overallDifficulty)
  local bag = QuestGenerator.createRewardBag(self, overallDifficulty)
  if bag then
    bag.items[1].parameters.treasure.level = math.max(
      world.getProperty("rl_starSystemThreatLevel") or 2, world.threatLevel()
    )
  end
  return bag
end
