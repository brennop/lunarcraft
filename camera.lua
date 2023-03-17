local Camera = Object:extend()

local Vector = require "vector"
local Matrix = require "matrix"

local cos, sin = math.cos, math.sin

local w, h = 400, 300

function Camera:new(world)
  self.position = Vector(0, CHUNK_HEIGHT + 2, 0)
  self.world = world

  self.view = Matrix()
  self.projection = Matrix()

  self.yaw = math.pi/2
  self.pitch = 0

  self.right   = Vector(1, 0, 0)
  self.up      = Vector(0, 1, 0)
  self.forward = Vector(0, 0, 1)

  self.near = 0.1
  self.far = 1000
  self.fov = 90
  self.aspect = w / h

  self._fov = 1 / math.tan(self.fov / 2 * math.pi / 180)

  self:updateDirection(0,0)
  self:updateProjection()
  self:updateView()
end

function Camera:updateProjection()
  local top = self.near * self._fov
  local right = top * self.aspect
  local bottom = -top
  local left = -right

  local x = 2 * self.near / (right - left)
  local y = 2 * self.near / (top - bottom)
  local a = (right + left) / (right - left)
  local b = (top + bottom) / (top - bottom)
  local c = -(self.far + self.near) / (self.far - self.near)
  local d = -2 * self.far * self.near / (self.far - self.near)

  self.projection:set({
    x, 0, a, 0,
    0, y, b, 0,
    0, 0, c, d,
    0, 0, -1, 0
  })
end

function Camera:updateView()
  local z = (self.forward):normalized()
  local x = self.up:cross(z):normalized()
  local y = z:cross(x)

  self.view:set({
    x.x, x.y, x.z, -x:dot(self.position),
    y.x, y.y, y.z, -y:dot(self.position),
    z.x, z.y, z.z, -z:dot(self.position),
    0,   0,   0,   1
  })
end

function Camera:updateDirection(dx, dy)
  self.yaw = self.yaw + dx * 0.001
  self.pitch = self.pitch + dy * 0.001

  -- fix pitch
  if self.pitch > math.pi / 2 then
    self.pitch = math.pi / 2
  elseif self.pitch < -math.pi / 2 then
    self.pitch = -math.pi / 2
  end

  self.forward.x = cos(self.yaw) * cos(self.pitch)
  self.forward.y = sin(self.pitch)
  self.forward.z = sin(self.yaw) * cos(self.pitch)

  self.right = self.forward:cross(Vector(0, 1, 0))
  self.up = self.right:cross(self.forward)

  self:updateView()
end

function Camera:update()
  local dx,dy,dz = 0,0,0

  if love.keyboard.isDown "w" then dz = -1
  elseif love.keyboard.isDown "s" then dz = 1
  end
  if love.keyboard.isDown "a" then dx = 1
  elseif love.keyboard.isDown "d" then dx = -1
  end
  if love.keyboard.isDown "space" then dy = 1
  elseif love.keyboard.isDown "lshift" then dy = -1
  end
  
  local dir = Vector(dx, dy, dz):normalized()

  -- take into account the camera direction (forward, right)
  dir = self.right * dir.x + Vector(0,1,0) * dir.y + self.forward * dir.z

  self.position = self.position + dir * 0.1

  self:updateView()

  local block, x, y, z = self:getHit()

  debug("block", block, x, y, z)
  if block > 0 and love.mouse.isDown(1) then
    self.world:setBlock(x, y, z, 0)
  end
end

function Camera:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("fill", w, h, 2)
end

local DOF = 16
function Camera:getHit()
  local x, y, z = self.position:unpack()
  local dx, dy, dz = (-self.forward):unpack()

  for dof = 1, DOF do
    local fx, fy, fz = math.ceil(x-0.5), math.ceil(y-0.5), math.ceil(z-0.5)
    local block = self.world:getBlock(fx, fy, fz)

    if block > 0 then
      return block, fx, fy, fz
    end

    x, y, z = x + dx, y + dy, z + dz
  end

  return 0, 0, 0, 0
end

return Camera
