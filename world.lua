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

  self._generated = false
end

function World:generateChunk(wx, wz)
  if self._generated then return end

  -- only allow one chunk to be generated at a time
  self._generated = true

  local x = math.floor((wx-1) / CHUNK_SIZE)
  local z = math.floor((wz-1) / CHUNK_SIZE)

  local chunk = Chunk(x, 0, z, self)
  chunk:updateMesh()

  if self.chunks[x] == nil then self.chunks[x] = {} end
  self.chunks[x][z] = chunk
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

  return 0
end

function World:setBlock(x, y, z, block)
  local chunk = self:getChunk(x, z)

  if chunk then
    chunk:setBlock(x, y, z, block)
    chunk:updateMesh()
  end
end

function World:update(dt)
  self._generated = false
end

function World:draw()
  for i, v in pairs(self.chunks) do
    for j, chunk in pairs(v) do
      chunk:draw()
    end
  end
end

return World
