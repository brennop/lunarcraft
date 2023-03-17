local CHUNK_SIZE = 16
local CHUNK_HEIGHT = 16

local Chunk = Object:extend()

local Block = require "block"
local Vector = require "vector"

local format = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
}

function Chunk:new(x, y, z)
  self.position = Vector(x * CHUNK_SIZE, y * CHUNK_HEIGHT, z * CHUNK_SIZE)

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

  self:updateMesh()
end

function Chunk:updateMesh()
  local vertices = {}

  for i = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for k = 1, CHUNK_SIZE do
        local block = self.blocks[i][j][k]
        if block then
          local x, y, z = (block.position + self.position):unpack()
          for _, vertex in ipairs(block.mesh) do
            local vx, vy, vz, u, v = unpack(vertex)
            table.insert(vertices, {
              x + vx, y + vy, z + vz,
              u, v
            })
          end
        end
      end
    end
  end

  self.mesh = love.graphics.newMesh(format, vertices, "triangles")
  self.mesh:setTexture(tileset)
end

function Chunk:draw()
  love.graphics.draw(self.mesh)
end

return Chunk
