local TemporarySystemThreatNpc = QuestPredicands.TemporarySystemThreatNpc

QuestRelations.temporarySystemThreatNpc = defineQueryRelation("temporarySystemThreatNpc", true) {
  [case(1, TemporarySystemThreatNpc, NonNil, NonNil, QuestPredicands.Location)] = function (self, npc, species, typeName, spawnLocation)
      if xor(self.negated, npc.species == species and npc.typeName == typeName) then
        return {{npc, species, typeName, spawnLocation}}
      end
      return Relation.empty
    end,

  [case(2, Nil, NonNil, NonNil, QuestPredicands.Location)] = function (self, _, species, typeName, spawnLocation)
      if self.negated then return Relation.some end
      return {{TemporarySystemThreatNpc.new(species, typeName, spawnLocation.region), species, typeName, spawnLocation}}
    end,

  default = Relation.some
}
