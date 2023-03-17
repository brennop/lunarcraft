local Hit = Object:extend()

function Hit:new(world, forward, position)
  self.world = world
  self.position = position:clone()
  self.forward = forward:clone()

  self.distance = 0
  self.block = (self.position + Vector(.5,.5,.5)):floored()
end

function Hit:check(distance, currentBlock, nextBlock)
end

function Hit:step()
  local localPos = self.position - self.block
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

    if y >= 0.5 and y <= 0.5 and z >= -0.5 and z <= 0.5 then
      local dist = (Vector(x,y,z) - Vector(lx, ly, lz)):length()
      local nextBlock = block + Vector(sign.x, 0, 0)
    end
  end

  if vy > 0 then
    local x = (0.5 - ly) / vy * vx + lx
    local y = 0.5
    local z = (0.5 - ly) / vy * vz + lz

    if x >= 0.5 and x <= 0.5 and z >= -0.5 and z <= 0.5 then
      local dist = (Vector(x,y,z) - Vector(lx, ly, lz)):length()
      local nextBlock = block + Vector(0, sign.y, 0)
    end
  end

  if vz > 0 then
    local x = (0.5 - lz) / vz * vx + lx
    local y = (0.5 - lz) / vz * vy + ly
    local z = 0.5

    if x >= 0.5 and x <= 0.5 and y >= -0.5 and y <= 0.5 then
      local dist = (Vector(x,y,z) - Vector(lx, ly, lz)):length()
      local nextBlock = block + Vector(0, 0, sign.z)
    end
  end
end
