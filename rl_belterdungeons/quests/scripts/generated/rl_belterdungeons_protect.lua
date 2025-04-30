require("/scripts/util.lua")
require("/quests/scripts/generated/common.lua")

function conditionsMet()
  return objective("kill"):isComplete()
end

function onInit()
  -- Replace the original abort message handler.
  self.questClient:setMessageHandler("abort", onAbort)

  self.questClient:setMessageHandler("entitiesDead", onEnemiesDead)
  self.questClient:setMessageHandler("entitiesSpawned", onEnemiesSpawned)
  self.questClient:setEventHandler({"target", "death"}, onTargetDied)
  self.questClient:setEventHandler({"target", config.getParameter("checkInConfirmedEventName")}, onCheckInConfirmed)
end

function onQuestStart()
  setIndicators({"target"})
end

function onUpdate(dt)
  if objective("checkIn"):isComplete() and
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
    if not status then error(result) end
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

function onCheckInConfirmed(target, interactor)
  if interactor ~= entity.id() then return end

  setIndicators({})
  objective("checkIn"):complete()
  self.compass:setTarget("parameter", "spawnPoint")
end

function onEnemiesDead(_, _)
  if not objective("findPlace"):isComplete() then objective("findPlace"):complete() end
  if not objective("checkIn"):isComplete() then onCheckInConfirmed(nil, entity.id()) end
  objective("kill"):complete()
end

function onEnemiesSpawned(_, _, group, entityNames)
  if not objective("findPlace"):isComplete() then objective("findPlace"):complete() end
  if not objective("checkIn"):isComplete() then onCheckInConfirmed(nil, entity.id()) end
  setIndicators(entityNames)
end

function onTargetDied()
  -- Failed to protect target
  quest.fail()
end

function questInteract(entityId)
  if world.entityUniqueId(entityId) ~= quest.parameters().target.uniqueId then return end
  if objective("checkIn"):isComplete() then return end

  notifyNpc("target", config.getParameter("requestCheckInNotification"))
  return true
end

function triggerSpawn()
  util.wait(2)

  objective("findPlace"):complete()
  self.questClient:sendToStagehand("rl_triggerSpawnEntities", "enemies")

  return true
end
