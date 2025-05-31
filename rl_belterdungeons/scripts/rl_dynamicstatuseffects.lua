function getDynamicStatusEffectsManager()
  local uid = "rl_dynamicstatuseffects_global"
  local manager = world.loadUniqueEntity(uid)
  if manager == 0 then
    world.spawnStagehand({10, 10}, "rl_dynamicstatuseffectsmanager")
    manager = world.loadUniqueEntity(uid)
  end
  if manager == 0 then
    sb.logError(
      "rl_dynamicstatuseffects: failed to spawn rl_dynamicstatuseffectsmanager"
    )
    return
  end
  return manager
end
