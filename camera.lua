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

  self.mesh = love.graphics.newMesh({
    { "VertexPosition", "float", 3 },
    { "VertexTexCoord", "float", 2 },
  }, {
    { -0.5,  0.5, 0.51, 0, 0 },
    { -0.5, -0.5, 0.51, 1, 1 },
    {  0.5, -0.5, 0.51, 0, 1 },
    {  0.5,  0.5, 0.51, 1, 0 },
  }, "fan")

  self.model = Matrix()
  self.model[8] = self.position.y

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

  local block, next = self:hit()

  if block then
    local x, y, z = block:unpack()
    self.world:setBlock(x, y, z, 0)
  end

  debug("block", block, next)
end

function Camera:draw()
end

function Camera:hit()
  local x, y, z    = self.position:unpack()
  local rx, ry, rz = self.position:unpack()
  local fx, fy, fz = (-self.forward):unpack()
  local dx, dy, dz

  local ytan = -math.tan(self.yaw)
  local ptan = math.tan(self.pitch)

  local dof = 0

  -- x rays
  if fx > 0 then -- looking right
    rx = math.floor(x) + 1
    ry = (x - rx) * ptan + y
    rz = (x - rx) * ytan + z
    dx = 1
    dy = -1 * ptan
    dz = -1 * ytan
  elseif fx < 0 then
    rx = math.floor(x)
    rz = (x - rx) * ytan + z
    ry = (x - rx) * ptan + y
    dx = -1
    dy = 1 * ptan
    dz = 1 * ytan
  else
    dof = 16
  end

  while dof < 16 do
    local bx = math.floor(rx) + 1
    local by = math.floor(ry) + 1
    local bz = math.floor(rz) + 1

    debug(bx, by, bz)

    local block = self.world:getBlock(bx, by, bz)

    if block > 0 then
      dof = 16
      return Vector(bx, by, bz)
    else
      rx = rx + dx
      ry = ry + dy
      rz = rz + dz
      dof = dof + 1
    end
  end
end

return Camera
