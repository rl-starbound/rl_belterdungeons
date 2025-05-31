require("/scripts/util.lua")
require("/quests/scripts/generated/common.lua")

function conditionsMet()
  return objective("kill"):isComplete()
end

function onInit()
  -- Replace the original abort message handler.
  self.questClient:setMessageHandler("abort", onAbort)

  self.questClient:setMessageHandler("entitiesDead", onEntitiesDead)
  self.questClient:setMessageHandler("entitiesSpawned", onEntitiesSpawned)

  storage.enemyGroupCount = storage.enemyGroupCount or 0
end

function onQuestStart()
  storage.questStarted = true
end

function onUpdate(dt)
  if storage.questStarted and
     not objective("findPlace"):isComplete() and
     not self.triggerSpawnCoroutine
  then
    local range = config.getParameter("spawnPointObjectiveRange")
    local spawnPoint = rect.center(quest.parameters().spawnPoint.region)
    if world.magnitude(entity.position(), spawnPoint) < range then
      self.triggerSpawnCoroutine = coroutine.create(triggerSpawn)
    end
  elseif self.triggerSpawnCoroutine then
    local status, result = coroutine.resume(self.triggerSpawnCoroutine)
    if not status then
      sb.logError("rl_belterdungeons_kill: triggerSpawn failed: %s", result)
      self.questClient:abort()
      return
    end
    if result then self.triggerSpawnCoroutine = nil end
  end
end

function onAbort(_, _, reason)
  if reason then
    local textGenerator = currentQuestTextGenerator()
    setPortraits(bind(textGenerator.substituteTags, textGenerator))
    local failureText = textGenerator:generateText(
      string.format("abortText.%s", reason), "default"
    )
    if failureText and failureText ~= "" then
      quest.setFailureText(failureText)
    end
  end
  self.questClient:abort()
end

function onEntitiesDead(_, _, group)
  if group ~= "enemies" then return end
  storage.enemyGroupCount = storage.enemyGroupCount - 1
  if storage.enemyGroupCount <= 0 then
    objective("kill"):complete()

    local notificationType = config.getParameter("enemiesDeadNotification")
    if notificationType then
      for _,victim in pairs(storage.victims or {}) do
        notifyNpc(victim, notificationType)
      end
    end
  end
end

function onEntitiesSpawned(_, _, group, entityNames)
  if not objective("findPlace"):isComplete() then
    objective("findPlace"):complete()
  end
  if group == "victims" then
    storage.victims = entityNames
    setIndicators(entityNames)
    self.compass:setTarget("parameter", entityNames)

  elseif group == "enemies" then
    storage.enemyGroupCount = storage.enemyGroupCount + 1

    if not storage.victims then
      setIndicators(entityNames)
      self.compass:setTarget("parameter", entityNames)
    end
  end
end

function triggerSpawn()
  util.wait(2)

  objective("findPlace"):complete()
  self.questClient:sendToStagehand("rl_triggerSpawnEntities", "enemies")

  return true
end
