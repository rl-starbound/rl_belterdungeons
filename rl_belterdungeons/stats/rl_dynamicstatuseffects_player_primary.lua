local previous_init = init
local previous_update = update

function init()
  previous_init()

  self.rlDynamicStatusEffects = {
    currentDungeonId = nil,
    dungeonEffects = {},
    globalEffects = nil
  }

  -- Wait 1 second between checks.
  self.rlDynamicStatusEffectsSearchTime = 1

  -- When the player beams into a world, the deployment finishes after
  -- the world loads its dungeon IDs, and therefore the first check can
  -- take place immediately and be accurate. However, when loading a
  -- game from the start screen, the player deployment may finish before
  -- the world loads its dungeon IDs, and therefore an immediate check
  -- will be inaccurate. So, wait briefly before doing the first check.
  -- Note this implies that if the dynamic status effects are blocking
  -- stats for environment hazards, the environment hazards may begin
  -- affecting the player before the blocking stats are applied. Such
  -- hazards should wait for a moment before their effects begin, to
  -- allow world loading and player deployment to complete, but they do
  -- not in the base game. I fixed this in `rl_betterenvirohazards`.
  self.rlDynamicStatusEffectsSearchTimer = 0.5

  message.setHandler("rl_dynamicstatuseffects_updated", rlDynamicStatusEffectsUpdated)
end

function update(dt)
  self.rlDynamicStatusEffectsSearchTimer = self.rlDynamicStatusEffectsSearchTimer - dt
  if self.rlDynamicStatusEffectsSearchTimer <= 0 then
    if not self.rlDynamicStatusEffects.globalEffects then
      self.rlDynamicStatusEffects.globalEffects = world.getProperty(
        "rl_dynamicstatuseffects_global"
      ) or {}
      --sb.logInfo("rl_dynamicstatuseffects_player_primary: fetched global effects: %s", sb.printJson(self.rlDynamicStatusEffects.globalEffects))
      if #self.rlDynamicStatusEffects.globalEffects > 0 then
        status.setPersistentEffects("rl_dynamicstatuseffects_global",
          self.rlDynamicStatusEffects.globalEffects
        )
      else
        status.clearPersistentEffects("rl_dynamicstatuseffects_global")
      end
    end

    local dungeonId = world.dungeonId(mcontroller.position())
    if dungeonId ~= self.rlDynamicStatusEffects.currentDungeonId then
      --sb.logInfo("rl_dynamicstatuseffects_player_primary: changing dungeon to %s", dungeonId)
      if not self.rlDynamicStatusEffects.dungeonEffects[dungeonId] then
        self.rlDynamicStatusEffects.dungeonEffects[dungeonId] = world.getProperty(
          string.format("rl_dynamicstatuseffects_%d", dungeonId)
        ) or {}
        --sb.logInfo("rl_dynamicstatuseffects_player_primary: fetched dungeon %s effects: %s", dungeonId, sb.printJson(self.rlDynamicStatusEffects.dungeonEffects[dungeonId]))
      end
      if #self.rlDynamicStatusEffects.dungeonEffects[dungeonId] > 0 then
        status.setPersistentEffects("rl_dynamicstatuseffects",
          self.rlDynamicStatusEffects.dungeonEffects[dungeonId]
        )
      else
        status.clearPersistentEffects("rl_dynamicstatuseffects")
      end
      self.rlDynamicStatusEffects.currentDungeonId = dungeonId
    end

    self.rlDynamicStatusEffectsSearchTimer = self.rlDynamicStatusEffectsSearchTime
  end

  previous_update(dt)
end

function rlDynamicStatusEffectsUpdated(_, _, dungeonId)
  --sb.logInfo("rl_dynamicstatuseffects_player_primary: received update for %s", dungeonId or "global")
  if not dungeonId then
    self.rlDynamicStatusEffects.globalEffects = nil
  else
    self.rlDynamicStatusEffects.dungeonEffects[dungeonId] = nil
    if dungeonId == self.rlDynamicStatusEffects.currentDungeonId then
      self.rlDynamicStatusEffects.currentDungeonId = nil
    end
  end
  self.rlDynamicStatusEffectsSearchTimer = 0
end
