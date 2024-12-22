-- Originally, this was cloned from `/objects/wired/door/door.lua`, so
-- that docking fields count as doors. But then I noticed that function
-- returned incorrect results for doors that lie across the world's X
-- origin. This function is somewhat slower but returns correct results.
function doorOccupiesSpace(position)
  local pos = entity.position()
  position = {math.floor(position[1]), math.floor(position[2])}
  for _,space in ipairs(object.spaces()) do
    local absSpace = {world.xwrap(space[1] + pos[1]), space[2] + pos[2]}
    if position[1] == absSpace[1] and position[2] == absSpace[2] then
      return true
    end
  end
  return false
end
