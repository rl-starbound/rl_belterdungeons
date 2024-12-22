PositionalQuestTextGenerator = subclass(QuestTextGenerator, "PositionalQuestTextGenerator")

function PositionalQuestTextGenerator:init(templateId, parameters, seed, arcPosition, originPosition)
  self.originPosition = originPosition
  QuestTextGenerator.init(self, templateId, parameters, seed, arcPosition)
end

-- Cloned verbatim from the base game because it was a local function.
local function directionInRange(direction, angleRange)
  -- This breaks if the angle range >= 180 degrees
  local min = vec2.rotate({0, -1}, util.toRadians(angleRange[1]))
  local max = vec2.rotate({0, -1}, util.toRadians(angleRange[2]))

  local minDiff = vec2.sub(min, direction)
  local maxDiff = vec2.sub(max, direction)
  local dot = vec2.dot(minDiff, maxDiff)
  return dot <= 0
end

-- Based on the base game function, but it takes an optional parameter
-- `originPosition`, instead of assuming the origin is the questmanager
-- stagehand, and an optional parameter `directionDefs`, which if given
-- defines the direction text.
local function describeDirection(targetPosition, originPosition, directionDefs)
  originPosition = originPosition or entity.position()
  local direction = vec2.norm(world.distance(originPosition, targetPosition))

  local descriptions = nil
  for _,directionDef in pairs(
    directionDefs or
    config.getParameter("directions") or
    root.assetJson("/quests/quests.config:directions")
  ) do
    if directionInRange(direction, directionDef.angleRange) then
      return directionDef.descriptions[math.random(#directionDef.descriptions)]
    end
  end

  return ""
end

-- Cloned verbatim from the base game because it was a local function.
local function paramHumanoidIdentity(paramValue)
  local level = paramValue.parameters.level or 1
  local npcVariant = root.npcVariant(paramValue.species, paramValue.typeName, level, paramValue.seed, paramValue.parameters)
  return npcVariant.humanoidIdentity
end

-- Cloned verbatim from the base game because it was a local function.
local function pronounGender(species, gender)
  gender = gender or "neutral"
  local genderOverrides = root.assetJson("/quests/quests.config:pronounGenders")
  if species and genderOverrides[species] and genderOverrides[species][gender] then
    gender = genderOverrides[species][gender]
  end
  return gender
end

-- Modified from the base game function to orient directions from an
-- optional origin position, rather than assuming the questmanager
-- stagehand's position. If the origin position is nil, it is
-- functionally identical to the base game version.
function PositionalQuestTextGenerator:generateExtraTags()
  local tags = {}
  local pronouns = root.assetJson("/quests/quests.config:pronouns")

  for paramName, paramValue in pairs(self.parameters) do
    if paramValue.region then
      tags[paramName .. ".direction"] = describeDirection(
        rect.center(paramValue.region), self.originPosition,
        self.config.directions
      )
    end

    local gender = nil
    if paramValue.type == "npcType" then
      local identity = paramHumanoidIdentity(paramValue)
      tags[paramName .. ".name"] = identity.name
      tags[paramName .. ".gender"] = identity.gender
      gender = pronounGender(identity.species, identity.gender)
    elseif paramValue.type == "entity" then
      tags[paramName .. ".gender"] = paramValue.gender
      gender = pronounGender(paramValue.species, paramValue.gender)
    end

    if gender then
      for pronounType, pronounText in pairs(pronouns[gender]) do
        tags[paramName .. ".pronoun." .. pronounType] = pronounText
      end
    end
  end

  local fluff = self.config.generatedText and self.config.generatedText.fluff
  if fluff then
    util.mergeTable(tags, generateFluffTags(fluff, self.seed))
  end

  return tags
end

function positionalQuestTextGenerator(questDesc, originPosition)
  return PositionalQuestTextGenerator.new(
    questDesc.templateId, questDesc.parameters, questDesc.seed, nil, originPosition
  )
end
