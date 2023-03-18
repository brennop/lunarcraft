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
  local nx, ny, nz

  local ax = t(other.pos1.x - self.pos2.x, velocity.x)
  local bx = t(other.pos2.x - self.pos1.x, velocity.x)

  if velocity.x > 0 then
    nx = 1
  else
    ax, bx = bx, ax
    nx = -1
  end

  local ay = t(other.pos1.y - self.pos2.y, velocity.y)
  local by = t(other.pos2.y - self.pos1.y, velocity.y)

  if velocity.y > 0 then
    ny = 1
  else
    ay, by = by, ay
    ny = -1
  end

  local az = t(other.pos1.z - self.pos2.z, velocity.z)
  local bz = t(other.pos2.z - self.pos1.z, velocity.z)

  if velocity.z > 0 then
    nz = 1
  else
    az, bz = bz, az
    nz = -1
  end

  if ax < 0 and ay < 0 and az < 0 then
    return nil
  end

  if ax > 1 or ay > 1 or az > 1 then
    return nil
  end

  entry = max(ax, ay, az)
  exit = min(bx, by, bz)

  if entry > exit then
    return nil
  end

  -- TODO: improve this
  if entry == ax then
    return entry, Vector(nx, 0, 0)
  elseif entry == ay then
    return entry, Vector(0, ny, 0)
  else
    return entry, Vector(0, 0, nz)
  end
end

return Collider
