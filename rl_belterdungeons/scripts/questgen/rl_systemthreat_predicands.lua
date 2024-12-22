QuestPredicands.TemporarySystemThreatNpc = subclass(QuestPredicands.TemporaryNpc, "TemporarySystemThreatNpc")

function QuestPredicands.TemporarySystemThreatNpc:init(species, typeName, spawnRegion)
  QuestPredicands.TemporaryNpc.init(self, species, typeName, spawnRegion)
end

function QuestPredicands.TemporarySystemThreatNpc:spawn()
  local seed = generateSeed()
  local overrides = {
      damageTeamType = "assistant",
      scriptConfig = {
        behaviorConfig = {
          beamOutWhenNotInUse = true
        },
        questGenerator = {
          pools = {},
          enableParticipation = false
        }
      }
    }
  local threatLevel = math.max(
      world.getProperty("rl_starSystemThreatLevel", 3),
      world.threatLevel()
    )
  local entityId = world.spawnNpc(entity.position(), self.species, self.typeName, threatLevel, seed, overrides)
  local boundBox = world.callScriptedEntity(entityId, "mcontroller.boundBox")
  world.callScriptedEntity(entityId, "mcontroller.setPosition", findSpaceInRect(self.spawnRegion, boundBox) or rect.center(self.spawnRegion))
  world.callScriptedEntity(entityId, "status.addEphemeralEffect", "beamin")
  return entityId
end
