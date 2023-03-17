
local Chunk = Object:extend()

local Block = require "block"
local Vector = require "vector"

local format = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
}

function Chunk:new(x, y, z, world)
  self.position = Vector(x * CHUNK_SIZE, y * CHUNK_HEIGHT, z * CHUNK_SIZE)
  self.world = world

  self.blocks = {}
  for i = 1, CHUNK_SIZE do
    self.blocks[i] = {}
    for j = 1, CHUNK_HEIGHT do
      self.blocks[i][j] = {}
      for k = 1, CHUNK_SIZE do
        self.blocks[i][j][k] = Block(i,j,k)
      end
    end
  end

  self.mesh = nil
end

function Chunk:updateMesh()
  local vertices = {}

  local function addFace(index, x, y, z)
    for i = 1, 6 do
      local vertex = Block.mesh[index*6+i]
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

        if block then
          local x, y, z = i + cx, j + cy, k + cz

          if not self.world:getBlock(x, y, z + 1) then addFace(0, x, y, z) end
          if not self.world:getBlock(x, y + 1, z) then addFace(1, x, y, z) end
          if not self.world:getBlock(x, y, z - 1) then addFace(2, x, y, z) end
          if not self.world:getBlock(x, y - 1, z) then addFace(3, x, y, z) end
          if not self.world:getBlock(x + 1, y, z) then addFace(4, x, y, z) end
          if not self.world:getBlock(x - 1, y, z) then addFace(5, x, y, z) end
        end
      end
    end
  end

  self.mesh = love.graphics.newMesh(format, vertices, "triangles")
  self.mesh:setTexture(tileset)
end

function Chunk:getBlock(x, y, z)
  if y < 1 or y > CHUNK_HEIGHT then return nil end

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
