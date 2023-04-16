local Camera = Object:extend()

local Vector = require "src.vector"
local Matrix = require "src.matrix"

local cos, sin = math.cos, math.sin

local w, h = 400, 300
local shadowMapResolution = 2048

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
  self.fov = 75
  self.aspect = w / h

  self.drawDistance = 8

  self.shader = love.graphics.newShader("shaders/camera.glsl")
  self.light = Vector(16, 64, 20)

  self.shadowMap = love.graphics.newCanvas(shadowMapResolution, shadowMapResolution,  { format = "depth24", readable = true })
  self.shadowMap:setWrap("clamp")
  self.shadowMap:setFilter("linear", "linear")
  self.shadowShader = love.graphics.newShader("shaders/depthShader.glsl")

  self.shadowProjection = Matrix()
  self.shadowView = Matrix()

  local k = 80
  self.shadowProjection:ortho(-k, k, -k, k, 1, 100)

  self.debugShadowMapShader = love.graphics.newShader([[
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float v = Texel(tex, texture_coords).r;
    return vec4(v, v, v, 1.0);
}
  ]])

  self:updateDirection(0,0)
  self:updateProjection(self.fov)
  self:updateView()

end

function Camera:updateProjection(_fov)
  local fov = math.tan(_fov / 2 * math.pi / 180)

  local top = self.near * fov
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
  self.view:lookAt(self.position, self.position - self.forward, self.up)

  local pCenter = Vector(self.position.x, 0, self.position.z)
  local lightPos = self.light + pCenter
  self.shadowView:lookAt(lightPos, pCenter, Vector(0, 1, 0))
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

  -- self:updateView()
end

function Camera:update()
  self:updateView()
end

function Camera:drawWorld()
  for x = -self.drawDistance, self.drawDistance do
    for z = -self.drawDistance, self.drawDistance do
      if x * x + z * z <= self.drawDistance * self.drawDistance then
        local px, py = x * CHUNK_SIZE + self.position.x, z * CHUNK_SIZE + self.position.z
        local chunk = self.world:getChunk(px, py)

        if chunk then
          chunk:draw()
        end
      end
    end
  end

  self.world:draw()
end

function Camera:drawShadowMap()
  love.graphics.setShader(self.shadowShader)

  self.shadowShader:send("viewMatrix", self.shadowView)
  self.shadowShader:send("projectionMatrix", self.shadowProjection)

  love.graphics.setCanvas({ depthstencil = self.shadowMap })
  love.graphics.clear(1, 0, 0)

  love.graphics.setDepthMode("lequal", true)
  love.graphics.setMeshCullMode("back")

  self:drawWorld()

  love.graphics.setDepthMode()
  love.graphics.setCanvas()
  love.graphics.setShader()
end

function Camera:draw()
  self:drawShadowMap()

  love.graphics.setMeshCullMode("back")
  love.graphics.setDepthMode("lequal", true)
  love.graphics.setShader(self.shader)

  self.shader:send("lightPos", { self.light.x, self.light.z, self.light.y })
  self.shader:send("viewMatrix", self.view)
  self.shader:send("projectionMatrix", self.projection)

  self.shader:send("shadowViewMatrix", self.shadowView)
  self.shader:send("shadowProjectionMatrix", self.shadowProjection)
  self.shader:send("shadowMap", self.shadowMap)

  self:drawWorld()

  love.graphics.setShader()

  -- love.graphics.setShader(self.debugShadowMapShader)
  -- love.graphics.draw(self.shadowMap, 0, 0, 0, 0.25, 0.25)
  -- love.graphics.setShader()
end

function Camera:hit()
  local position = self.position:clone()
  local block = (self.position + Vector(.5,.5,.5)):floored()
  local distance = 0

  while distance < 10 do
    local localPos = position - block
    local absolute = (-self.forward):clone()
    local sign = Vector(1, 1, 1)

    if absolute.x < 0 then
      absolute.x = -absolute.x
      localPos.x = -localPos.x
      sign.x = -1
    end

    if absolute.y < 0 then
      absolute.y = -absolute.y
      localPos.y = -localPos.y
      sign.y = -1
    end

    if absolute.z < 0 then
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
          return block, nextBlock
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
          return block, nextBlock
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
          return block, nextBlock
        else
          position = position + self.forward * distance
          block = nextBlock
          distance = distance + dist
        end
      end
    end
  end

  return nil
end

return Camera
