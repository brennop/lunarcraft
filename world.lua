local World = Object:extend()

local Chunk = require "chunk"

function World:new()
  self.chunks = {}

  for i = -2, 2 do
    self.chunks[i] = {}
    for j = -2, 2 do
      self.chunks[i][j] = Chunk(i, 0, j, self)
    end
  end

  for i = -2, 2 do
    for j = -2, 2 do
      self.chunks[i][j]:updateMesh()
    end
  end
end

function World:getChunk(x, z)
  -- convert to chunk coordinates
  local nx = math.floor((x-1) / CHUNK_SIZE)
  local nz = math.floor((z-1) / CHUNK_SIZE)

  local c = self.chunks[nx]

  if c then return c[nz] end

  return nil
end

function World:getBlock(x, y, z)
  local chunk = self:getChunk(x, z)

  if chunk then
    return chunk:getBlock(x, y, z)
  end

  return nil
end

function World:draw()
  for i, v in pairs(self.chunks) do
    for j, chunk in pairs(v) do
      chunk:draw()
    end
  end
end

return World
