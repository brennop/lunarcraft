local Vector = require "vector"
local Camera = require "camera"
local Collider = require "collider"

local Player = Object:extend()

function Player:new(world)
  self.world = world

  self.position = Vector(0, 30, 0)
  self.velocity = Vector(0, 0, 0)
  self.accel = Vector(0, -0.2, 0)

  self.speed = 1000

  self.width = 0.6
  self.height = 1.8

  self.yaw = math.pi/2
  self.pitch = 0

  self.collider = Collider(Vector(), Vector())

  self.camera = Camera(world)
end


function Player:update(dt)
  self:handleInput(dt)
  self:updateCollider()
  self:checkCollisions(dt)

  self.velocity.x = self.velocity.x * math.pow(0.99, dt * self.speed)
  self.velocity.z = self.velocity.z * math.pow(0.99, dt * self.speed)

  self.velocity = self.velocity + self.accel * dt
  self.position = self.position + self.velocity * dt

  self.camera.position = self.position + Vector(0, self.height, 0)
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

function Player:updateCollider()
  self.collider.pos1 = self.position - Vector(self.width/2, 0, self.width/2)
  self.collider.pos2 = self.position + Vector(self.width/2, self.height, self.width/2)
end

local function sign(x) return x < 0 and -1 or 1 end

function Player:checkCollisions(dt)
  local dv = self.velocity * dt
  local sx, sy, sz = sign(dv.x), sign(dv.y), sign(dv.z)

  local stepsXZ = math.floor(self.width/2)
  local stepsY = math.floor(self.height)

  local x, y, z = self.position:floored():unpack()
  local cx, cy, cz = (self.position + dv):floored():unpack()

  local potential = {}
  for i = x - sx * (stepsXZ+1), cx + sx * (stepsXZ+2), sx do
    for j = y - sy * (stepsY+2), cy + sy * (stepsY+3), sy do
      for k = z - sz * (stepsXZ+1), cz + sz * (stepsXZ+2), sz do
        local pos = Vector(i, j, k)
        local half = Vector(0.5, 0.5, 0.5)
        local block = self.world:getBlock(i, j, k)

        collider = Collider(pos - half, pos + half)

        local entry, normal = self.collider:collide(collider, dv)

        if entry then
          table.insert(potential, { entry, normal })
        end

        -- TODO: allow different hitboxes for blocks
      end
    end
  end

  -- TODO: change to a min
  table.sort(potential, function(a, b)
    return a[1] < b[1]
  end)

  local col = potential[1]

  if col then
    local entry, normal = col[1], col[2]
    entry = entry - 0.001
    local vx, vy, vz = dv:unpack()

    if normal.x ~= 0 then
      self.velocity.x = 0
      self.position.x = self.position.x - vx * entry
    end

    if normal.y ~= 0 then
      self.velocity.y = 0
      self.position.y = self.position.y - vy * entry
    end

    if normal.z ~= 0 then
      self.velocity.z = 0
      self.position.z = self.position.z - vz * entry
    end
  end
end

return Player
