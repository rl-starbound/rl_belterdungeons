-- Identical to the base game version, except adds a `reason` argument,
-- which is forwarded to the player in the abort message. If non-nil, it
-- must be a string referencing a failure text template in the quest's
-- template. If nil, the behavior is identical to the base game.
function QuestManager:cancel(reason)
  if self.data.canceled then return end

  for _, questDesc in pairs(self:arc().quests) do
    self.plugins:questFinished(questDesc.questId)
  end

  self:sendToParticipants("unreserve", self:arc())

  for player,_ in pairs(self.data.playerProgress) do
    self:sendToPlayer(player, "abort", reason)
  end

  self.data.playerProgress = {}
  self.data.playerStarted = {}

  self.data.offering = false
  self.data.canceled = true
end
