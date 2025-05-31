local previous_init = init
local previous_update = update

function init()
  previous_init()

  -- Wait 1 second between sync checks.
  self.rlBelterSyncTime = 1
  self.rlBelterSyncTimer = self.rlBelterSyncTime

  -- In the base game, the shield generator script's init function sets
  -- the update delta to 0, so we must re-enable it here.
  script.setUpdateDelta(config.getParameter("scriptDelta", 5))
end

function update(dt)
  if previous_update then previous_update(dt) end

  -- The object's state can become out of sync with the world's state if
  -- some other method of toggling shields is used, e.g., admin commands
  -- or another shield switch. Periodically resync and update outputs if
  -- necessary. The real-world state of the shield takes precedence over
  -- the input node's current value, however, if the input node changes
  -- value, the new value will retake precedence and may raise or lower
  -- the shield.
  self.rlBelterSyncTimer = self.rlBelterSyncTimer - dt
  if self.rlBelterSyncTimer <= 0 then
    local newState = world.isTileProtected(entity.position())
    if newState ~= storage.state then
      storage.state = newState
      updateAnimationState(storage.state)
      if object.outputNodeCount() > 0 then
        object.setOutputNodeLevel(0, storage.state)
      end
    end
    self.rlBelterSyncTimer = self.rlBelterSyncTime
  end
end
