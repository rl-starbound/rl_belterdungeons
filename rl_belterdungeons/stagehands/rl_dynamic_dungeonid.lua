require "/scripts/vec2.lua"

-- The permissible range disallows dungeonIds 65520 and above, because
-- those dungeonIds have special meaning to the game.
local idRange = {0, 65519}

function init()
  self.area = config.getParameter("broadcastArea")

  -- `dungeonIdOffset` must be a positive integer. The sum of the base
  -- dungeonId and the offset must be within the idRange.
  self.dungeonIdOffset = config.getParameter("dungeonIdOffset")
end

function update(dt)
  local pos = entity.position()
  for i, v in ipairs(pos) do pos[i] = math.floor(v) end

  local ll = world.xwrap(vec2.add(pos, {self.area[1], self.area[2]}))
  local ur = world.xwrap(vec2.add(pos, {self.area[3], self.area[4]}))
  local region = {ll[1], ll[2], ur[1], ur[2]}

  -- TODO: We are ignoring handling out-of-bounds Y-coordinates for now
  -- because that cannot happen given how this stagehand is currently
  -- used. If it achieves more widespread use, we may need to reconsider
  -- checking for this.
  local regions = {}
  if region[3] < region[1] then
    table.insert(regions, {region[1], region[2], world.size()[1], region[4]})
    if region[3] > 0 then
      table.insert(regions, {0, region[2], region[3], region[4]})
    end
  else
    table.insert(regions, region)
  end

  local dungeonId = world.dungeonId(pos) + self.dungeonIdOffset
  if dungeonId >= idRange[1] and dungeonId <= idRange[2] then
    for _, v in ipairs(regions) do
      world.setDungeonId(v, dungeonId)
    end
  else
    sb.logWarn("rl_dynamic_dungeonid: update: target dungeonId %d out of range at position %s; skipping", dungeonId, pos)
  end

  stagehand.die()
end
