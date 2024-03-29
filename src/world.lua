-- local bitser = require "lib.bitser"

local Chunk = require "src.chunk"
local Terrain = require "src.terrain"

local World = {}

function World:new()
  self.chunks = {}
  self.terrain = Terrain()
  self.loadQueue = {}
  self.debugChunkTimes = {}

  -- self:load()

  self:loadChunk(0, 0)

  self.chunkLoader = coroutine.create(function()
    while true do
      local chunk = table.remove(self.loadQueue, 1)

      if chunk then
        chunk:load()
      end

      coroutine.yield()
    end
  end)

  return self
end

function World:save()
  local chunks = {}
  for i, v in pairs(self.chunks) do
    for j, c in pairs(v) do
      table.insert(chunks, {i, j, c.blocks})
    end
  end

  bitser.dumpLoveFile("world.dat", chunks)
end

function World:load()
  local chunks = bitser.loadLoveFile("world.dat")

  for i, v in pairs(chunks) do
    local x, z, blocks = v[1], v[2], v[3]

    local chunk = Chunk(x, 0, z, self)
    chunk.blocks = blocks

    if self.chunks[x] == nil then self.chunks[x] = {} end
    self.chunks[x][z] = chunk
  end
end

function World:generateChunk(wx, wz)
  local x = math.floor((wx-1) / CHUNK_SIZE)
  local z = math.floor((wz-1) / CHUNK_SIZE)

  local chunk = Chunk(x, 0, z, self)

  if self.chunks[x] == nil then self.chunks[x] = {} end
  self.chunks[x][z] = chunk

  self:markDirty(chunk)

  -- mark adjacent chunks as dirty
  local north = self:getChunk(wx, wz - CHUNK_SIZE)
  local south = self:getChunk(wx, wz + CHUNK_SIZE)
  local east = self:getChunk(wx + CHUNK_SIZE, wz)
  local west = self:getChunk(wx - CHUNK_SIZE, wz)

  if north then self:markDirty(north) end
  if south then self:markDirty(south) end
  if east then self:markDirty(east) end
  if west then self:markDirty(west) end
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

  -- prevents ungenerated chunks from being treated as air
  return -1
end

function World:setBlock(x, y, z, block)
  local chunk = self:getChunk(x, z)

  if chunk then
    chunk:setBlock(x, y, z, block)
  end
end

function World:updateBlockMesh(x, y, z)
  for dx = -1, 1 do
    for dz = -1, 1 do
      local ix, iz = x + dx, z + dz
      local chunk = self:getChunk(ix, iz)

      chunk:updateBlockMesh(ix, y, iz)
      chunk:updateBlockMesh(ix, y - 1, iz)
      chunk:updateBlockMesh(ix, y + 1, iz)
    end
  end
end

function World:loadChunk(x, z)
  local chunk = self:getChunk(x, z)

  if chunk then
    chunk.loaded = true
  else
    self:generateChunk(x, z)
  end
end

function World:markDirty(chunk)
  if chunk.dirty then return end

  chunk.dirty = true
  table.insert(self.loadQueue, chunk)
end

function World:update(dt)
  for i, v in pairs(self.chunks) do
    for j, chunk in pairs(v) do
      if chunk.loaded then
        chunk:update(dt)
      end
    end
  end

  local chunkLatency = 0
  for i, v in ipairs(self.debugChunkTimes) do
    chunkLatency = chunkLatency + v
  end
  debug("time to load chunks:", chunkLatency / #self.debugChunkTimes)

  if #self.loadQueue > 0 then
    local result, value = coroutine.resume(self.chunkLoader)
    if not result then error(value) end
  end
end

function World:draw()
  for i, v in pairs(self.chunks) do
    for j, chunk in pairs(v) do
      chunk:draw()
    end
  end
end

return World
