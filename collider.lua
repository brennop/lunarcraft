local Vector = require "vector"

local Collider = Object:extend()

local min, max = math.min, math.max

function Collider:new(pos1, pos2)
  self.pos1 = pos1
  self.pos2 = pos2
end

function Collider:__add(vec)
  return Collider(self.pos1 + vec, self.pos2 + vec)
end

function Collider:intersect(other)
  return (min(self.pos2.x, other.pos2.x) - max(self.pos1.x, other.pos1.x)) > 0
     and (min(self.pos2.y, other.pos2.y) - max(self.pos1.y, other.pos1.y)) > 0
     and (min(self.pos2.z, other.pos2.z) - max(self.pos1.z, other.pos1.z)) > 0
end

local function t(x, y)
  if y == 0 then
    return x/y * -1
  else
    return x/y
  end
end

function Collider:collide(other, velocity)
  local vx, vy, vz = velocity:unpack()

  local x_entry = t(vx > 0 and other.pos1.x - self.pos2.x or other.pos2.x - self.pos1.x, vx)
  local y_entry = t(vy > 0 and other.pos1.y - self.pos2.y or other.pos2.y - self.pos1.y, vy)
  local z_entry = t(vz > 0 and other.pos1.z - self.pos2.z or other.pos2.z - self.pos1.z, vz)

  local x_exit = t(vx > 0 and other.pos2.x - self.pos1.x or other.pos1.x - self.pos2.x, vx)
  local y_exit = t(vy > 0 and other.pos2.y - self.pos1.y or other.pos1.y - self.pos2.y, vy)
  local z_exit = t(vz > 0 and other.pos2.z - self.pos1.z or other.pos1.z - self.pos2.z, vz)

  local entry = max(max(x_entry, y_entry), z_entry)
  local exit = min(min(x_exit, y_exit), z_exit)

  if entry > exit or x_entry < 0 and y_entry < 0 and z_entry < 0 or x_entry > 1 or y_entry > 1 or z_entry > 1 then
    return nil
  end

  local normal = Vector(0, 0, 0)

  if x_entry > y_entry and x_entry > z_entry then
    normal.x = vx > 0 and -1 or 1
  elseif y_entry > z_entry then
    normal.y = vy > 0 and -1 or 1
  else
    normal.z = vz > 0 and -1 or 1
  end

  return entry, normal
end

return Collider
