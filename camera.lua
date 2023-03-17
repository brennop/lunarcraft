local Object = require "lib.classic"

local Camera = Object:extend()

local Vector = require "vector"
local Matrix = require "matrix"

local cos, sin = math.cos, math.sin

local w, h = 400, 300

function Camera:new()
  self.position = Vector(0, 0, 0)

  self.view = Matrix()
  self.projection = Matrix()

  self.yaw = math.pi / 2
  self.pitch = 0

  self.right   = Vector(1, 0, 0)
  self.up      = Vector(0, 1, 0)
  self.forward = Vector(0, 0, 1)

  self.near = 0.1
  self.far = 1000
  self.fov = 90
  self.aspect = h / w

  self._fov = 1 / math.tan(self.fov / 2 * math.pi / 180)

  self:updateProjection()
  self:updateView()
end

function Camera:updateProjection()
  local q = self.far / (self.far - self.near)
  self.projection[1] = self._fov * self.aspect
  self.projection[6] = self._fov
  self.projection[11] = q
  self.projection[12] = -1
  self.projection[15] = q * -self.near
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

  if love.keyboard.isDown "w" then dz = 1
  elseif love.keyboard.isDown "s" then dz = -1
  end
  if love.keyboard.isDown "a" then dx = 1
  elseif love.keyboard.isDown "d" then dx = -1
  end
  if love.keyboard.isDown "space" then dy = 1
  elseif love.keyboard.isDown "lshift" then dy = -1
  end
  
  local dir = Vector(dx, dy, dz):normalized()

  -- take into account the camera direction (forward, right)
  dir = self.right * dir.x + self.up * dir.y + self.forward * dir.z

  self.position = self.position + dir * 0.1

  self:updateView()
end

return Camera

