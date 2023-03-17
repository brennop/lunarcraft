
local Chunk = Object:extend()

local blockTypes = require "block"
local Vector = require "vector"

local format = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
}

function Chunk:new(x, y, z, world)
  self.position = Vector(x * CHUNK_SIZE, y * CHUNK_HEIGHT, z * CHUNK_SIZE)
  self.world = world

  self.blocks = {}

  local _overworld = { 0, 2 }
  local _terrain = { 0, 3 }
  local _caves = { 0, 0, 1 }
  

  for i = 1, CHUNK_SIZE do
    self.blocks[i] = {}
    for j = 1, CHUNK_HEIGHT do
      self.blocks[i][j] = {}
      for k = 1, CHUNK_SIZE do
        if j == 16 then
          self.blocks[i][j][k] = _overworld[math.random(1, #_overworld)]
        elseif j > 13 then
          self.blocks[i][j][k] = _terrain[math.random(1, #_terrain)]
        else
          self.blocks[i][j][k] = _caves[math.random(1, #_caves)]
        end
      end
    end
  end

  self.mesh = nil
end

function Chunk:updateMesh()
  local vertices = {}

  local function addFace(index, mesh, x, y, z)
    for i = 1, 6 do
      local vertex = mesh[index*6+i]
      local vx, vy, vz, u, v = unpack(vertex)
      table.insert(vertices, {
        vx + x, vy + y, vz + z,
        u, v
      })
    end
  end

  local cx, cy, cz = self.position:unpack()
  for i = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for k = 1, CHUNK_SIZE do
        local block = self.blocks[i][j][k]
        if block > 0 then
          local mesh = blockTypes[block]
          local x, y, z = i + cx, j + cy, k + cz

          if self.world:getBlock(x, y, z + 1) == 0 then addFace(0, mesh, x, y, z) end
          if self.world:getBlock(x, y + 1, z) == 0 then addFace(1, mesh, x, y, z) end
          if self.world:getBlock(x, y, z - 1) == 0 then addFace(2, mesh, x, y, z) end
          if self.world:getBlock(x, y - 1, z) == 0 then addFace(3, mesh, x, y, z) end
          if self.world:getBlock(x + 1, y, z) == 0 then addFace(4, mesh, x, y, z) end
          if self.world:getBlock(x - 1, y, z) == 0 then addFace(5, mesh, x, y, z) end
        end
      end
    end
  end

  self.mesh = love.graphics.newMesh(format, vertices, "triangles")
  self.mesh:setTexture(tileset)
end

function Chunk:getBlock(x, y, z)
  if y < 1 or y > CHUNK_HEIGHT then return 0 end

  -- translate to local coordinates
  x = x - self.position.x
  y = y - self.position.y
  z = z - self.position.z

  return self.blocks[x][y][z]
end

function Chunk:draw()
  love.graphics.draw(self.mesh)
end

return Chunk
