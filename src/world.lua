local bitser = require "lib.bitser"

local Chunk = require "src.chunk"
local Terrain = require "src.terrain"

local World = {}

local profile = require "jit.p"

local DEBUG_first_update = true

function World:new()
  self.chunks = {}
  self.terrain = Terrain()

  -- self:load()

  -- self:loadChunk(0, 0)

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

function World:update(dt)
  if not DEBUG_first_update then
    profile.start "Fl3"
  end

  for i, v in pairs(self.chunks) do
    for j, chunk in pairs(v) do
      if chunk.loaded then

        if chunk.dirty then
          chunk:load()
        end

        chunk:update(dt)
      end

      chunk.loaded = false
    end
  end

  if not DEBUG_first_update then
    profile.stop()

    print("mean load time:")
    local mean = 0
    for i = 1, #load_times do
      mean = mean + load_times[i]
    end
    mean = mean / #load_times
    print(mean)

    love.event.quit() 
  end

  DEBUG_first_update = false

end

function World:draw()
  for i, v in pairs(self.chunks) do
    for j, chunk in pairs(v) do
      chunk:draw()
    end
  end
end

return World
