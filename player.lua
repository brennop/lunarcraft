local Vector = require "vector"
local Camera = require "camera"

local Player = Object:extend()

function Player:new(world)
  self.world = world

  self.position = Vector(0, 32, 0)
  self.velocity = Vector(0, 0, 0)
  self.accel = Vector(0, -10, 0)

  self.speed = 1000

  self.height = 2

  self.yaw = math.pi/2
  self.pitch = 0

  self.camera = Camera(world)
end

function Player:update(dt)
  self:handleInput(dt)

  self.velocity = self.velocity + self.accel * dt
  self.position = self.position + self.velocity * dt

  local bottom = self.position:floored() - Vector(0, 1, 0)
  if self.world:getBlock(bottom:unpack()) > 0 then
    self.position.y = math.ceil(self.position.y)
  end

  self.camera.position = self.position + Vector(0, self.height, 0)

  self.velocity.x = self.velocity.x * math.pow(0.99, dt * self.speed)
  self.velocity.z = self.velocity.z * math.pow(0.99, dt * self.speed)

  self.camera:update(dt)
end

function Player:draw()
  self.camera:draw()
end

function Player:handleInput(dt)
  local dz, dx
  if love.keyboard.isDown "w" then dx = -1 end
  if love.keyboard.isDown "s" then dx = 1 end
  if love.keyboard.isDown "a" then dz = -1 end
  if love.keyboard.isDown "d" then dz = 1 end

  local d = Vector(dx, 0, dz):rotated(self.yaw)
  self.accel.x = d.x * self.speed * dt
  self.accel.z = d.z * self.speed * dt
end

function Player:updateDirection(dx, dy)
  -- TODO: only update once (on camera or on player)
  self.yaw = self.yaw + dx * 0.001

  self.camera:updateDirection(dx, dy)
end


return Player
