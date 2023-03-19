local Vector = Object:extend()

function Vector:new(x, y, z)
  self.x = x or 0
  self.y = y or 0
  self.z = z or 0
end

function Vector:__tostring()
  return string.format("Vector(%.2f, %.2f, %.2f)", self.x, self.y, self.z)
end

function Vector:__add(other)
  return Vector(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vector:__sub(other)
  return Vector(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vector:__mul(other)
  return Vector(self.x * other, self.y * other, self.z * other)
end

function Vector:__div(other)
  return Vector(self.x / other, self.y / other, self.z / other)
end

function Vector:__unm()
  return Vector(-self.x, -self.y, -self.z)
end

function Vector:__eq(other)
  return self.x == other.x and self.y == other.y and self.z == other.z
end

function Vector:__lt(other)
  return self.x < other.x and self.y < other.y and self.z < other.z
end

function Vector:__le(other)
  return self.x <= other.x and self.y <= other.y and self.z <= other.z
end

function Vector:length()
  return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vector:clone()
  return Vector(self.x, self.y, self.z)
end

function Vector:unpack()
  return self.x, self.y, self.z
end

function Vector:dot(other)
  return self.x * other.x + self.y * other.y + self.z * other.z
end

function Vector:cross(other)
  return Vector(
    self.y * other.z - self.z * other.y,
    self.z * other.x - self.x * other.z,
    self.x * other.y - self.y * other.x
  )
end

function Vector:normalize()
  local length = self:length()
  self.x = self.x / length
  self.y = self.y / length
  self.z = self.z / length
end

function Vector:normalized()
  local length = self:length()
  if length == 0 then return Vector(0, 0, 0) end
  return Vector(self.x / length, self.y / length, self.z / length)
end

function Vector:floored()
  return Vector(math.floor(self.x), math.floor(self.y), math.floor(self.z))
end

function Vector:rotated(angle)
  local c = math.cos(angle)
  local s = math.sin(angle)
  return Vector(self.x * c + self.z * s, self.y, self.x * s - self.z * c)
end

function Vector:table()
  return {self.x, self.y, self.z}
end

return Vector
