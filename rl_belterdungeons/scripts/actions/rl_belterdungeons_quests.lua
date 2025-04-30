-- Cloned verbatim from `/scripts/actions/quests.lua` because that
-- function is also defined as a local.
local function tooManyQuestsNearby()
  local searchRadius = config.getParameter("questGenerator.nearbyQuestRange", 50)
  local questManagers = 0
  local entities = world.entityQuery(entity.position(), searchRadius)
  for _,entity in pairs(entities) do
    if world.entityName(entity) == "questgentest" then
      -- Testing object suppresses automatic quest generation
      return true
    end

    if world.entityType(entity) == "stagehand" and world.stagehandType(entity) == "questmanager" then
      questManagers = questManagers + 1
    end
  end

  if questManagers >= config.getParameter("questGenerator.nearbyQuestLimit", 2) then
    return true
  end
  return false
end

-- This should be identical to the `generateNewArc` function in
-- `/scripts/actions/quests.lua` except it should choose the generator
-- class based on the world type.
function rl_belterdungeons_generateNewArc()
  if not self.questGenerator then
    local generators = root.assetJson("/rl_belterdungeons.config:questGenerators")
    local generatorClassName = generators.byWorldType[world.type()] or "QuestGenerator"
    local generatorScript = generators.script[generatorClassName]
    if generatorScript then require(generatorScript) end
    local generatorClass = _ENV[generatorClassName]

    self.questGenerator = generatorClass.new()
  end
  self.questGenerator.debug = self.debug or false
  self.questGenerator.abortQuestCallback = tooManyQuestsNearby
  return self.questGenerator:generateStep()
end

-- Cloned verbatim from `/scripts/actions/quests.lua` because that
-- function is also defined as a local.
local function decideWhetherToGenerateQuest(rolls)
  if not config.getParameter("questGenerator.enableParticipation") then
    return false
  end

  if world.getProperty("ephemeral") then
    return false
  end

  if self.quest:hasRole() then
    return false
  end

  local baseChance = config.getParameter("questGenerator.chance", 0.1)
  -- If we're supposed to make a decision every 30 seconds, and 4 minutes have
  -- passed, we have 8 decisions to make.
  -- 'chance' is equal to the chance of at least one of these decisions (each
  -- with probability 'baseChance') being positive.
  local maxChance = config.getParameter("questGenerator.maxBoostedChance", 0.5)
  local chance = math.min(1.0 - (1.0 - baseChance) ^ rolls, maxChance)
  util.debugLog("rolls = %s, baseChance = %s, chance = %s", rolls, baseChance, chance)
  if chance < math.random() then
    return false
  end

  if tooManyQuestsNearby() then
    return false
  end

  return true
end

-- Cloned verbatim from `/scripts/actions/quests.lua` because that
-- function is also defined as a local.
local function getDecisionRolls()
  if not storage.lastQuestGenDecisionTime then
    return 1
  end
  local elapsed = world.time() - storage.lastQuestGenDecisionTime
  local period = config.getParameter("questGenerator.timeLimit", 30)
  return math.floor(elapsed / period)
end

-- This should be identical to the `maybeGenerateQuest` function in
-- `/scripts/actions/quests.lua` except it should generate arcs using a
-- dynamically-defined quest generator.
function rl_belterdungeons_maybeGenerateQuest(args, output)
  if self.quest:hasRole() then
    self.isGeneratingQuest = false
    return false
  end

  local rolls = getDecisionRolls()
  if rolls > 0 then
    self.isGeneratingQuest = decideWhetherToGenerateQuest(rolls)
    storage.lastQuestGenDecisionTime = world.time()

    if self.isGeneratingQuest then
      util.debugLog("Decided to generate a quest.")
    else
      util.debugLog("Decided not to generate a quest.")
    end
  end

  if not self.isGeneratingQuest then
    return false
  end

  local arc = rl_belterdungeons_generateNewArc()
  if not arc then
    return false
  end

  self.isGeneratingQuest = false

  local position = entity.position()
  world.spawnStagehand(position, "questmanager", {
      uniqueId = arc.questArc.stagehandUniqueId,
      quest = {
          arc = storeQuestArcDescriptor(arc.questArc),
          participants = arc.participants
        },
      plugins = arc.managerPlugins
    })
  return true
end
