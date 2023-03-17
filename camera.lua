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

  debug("block", block, next)
end

function Camera:draw()
end

function Camera:hit()
  local position = self.position:clone()
  local block = (self.position + Vector(.5,.5,.5)):floored()
  local distance = 0

  for i = 1, 10 do
    local localPos = position - block
    local absolute = self.forward:clone()
    local sign = Vector(1, 1, 1)

    if self.forward.x < 0 then
      absolute.x = -absolute.x
      localPos.x = -localPos.x
      sign.x = -1
    end

    if self.forward.y < 0 then
      absolute.y = -absolute.y
      localPos.y = -localPos.y
      sign.y = -1
    end

    if self.forward.z < 0 then
      absolute.z = -absolute.z
      localPos.z = -localPos.z
      sign.z = -1
    end

    local lx, ly, lz = localPos:unpack()
    local vx, vy, vz = absolute:unpack()

    if vx > 0 then
      local x = 0.5
      local y = (0.5 - lx) / vx * vy + ly
      local z = (0.5 - lx) / vx * vz + lz


      if y >= -0.5 and y <= 0.5 and z >= -0.5 and z <= 0.5 then
        local dist = (Vector(x,y,z) - Vector(lx, ly, lz)):length()
        local nextBlock = block + Vector(sign.x, 0, 0)

        if self.world:getBlock(nextBlock:unpack()) > 0 then
          return currentBlock, nextBlock
        else
          position = position + self.forward * distance
          block = nextBlock
          distance = distance + dist
        end
      end
    end

    if vy > 0 then
      local x = (0.5 - ly) / vy * vx + lx
      local y = 0.5
      local z = (0.5 - ly) / vy * vz + lz

      if x >= -0.5 and x <= 0.5 and z >= -0.5 and z <= 0.5 then
        local dist = (Vector(x,y,z) - Vector(lx, ly, lz)):length()
        local nextBlock = block + Vector(0, sign.y, 0)

        if self.world:getBlock(nextBlock:unpack()) > 0 then
          return currentBlock, nextBlock
        else
          position = position + self.forward * distance
          block = nextBlock
          distance = distance + dist
        end
      end
    end

    if vz > 0 then
      local x = (0.5 - lz) / vz * vx + lx
      local y = (0.5 - lz) / vz * vy + ly
      local z = 0.5

      if x >= -0.5 and x <= 0.5 and y >= -0.5 and y <= 0.5 then
        local dist = (Vector(x,y,z) - Vector(lx, ly, lz)):length()
        local nextBlock = block + Vector(0, 0, sign.z)

        if self.world:getBlock(nextBlock:unpack()) > 0 then
          return currentBlock, nextBlock
        else
          position = position + self.forward * distance
          block = nextBlock
          distance = distance + dist
        end
      end
    end
  end

  debug("nil")
  return nil
end

return Camera
