local bitser = require "lib.bitser"

local Chunk = require "src.chunk"
local Terrain = require "src.terrain"

local World = {}

function World:new()
  self.chunks = {}
  self.terrain = Terrain()

  -- self:load()

  self.threads = {}

  for i = 1, 4 do
    self.threads[i] = love.thread.newThread("src/mesh.lua")
  end

  self:loadChunk(0, 0)

  self.opaqueMeshes = {}
  self.transparentMeshes = {}

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

function World:getThread()
  for _, thread in pairs(self.threads) do
    if thread:isRunning() == false then
      return thread
    end
  end

  return nil
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

function World:update(dt)
  for i, v in pairs(self.chunks) do
    for j, chunk in pairs(v) do
      if chunk.loaded then

        if chunk.dirty then
          local thread = self:getThread()

          if thread then chunk:load(thread) end
        end

        chunk:update(dt)
      end

      chunk.loaded = false
    end
  end
end

function World:draw()
  local shader = love.graphics.getShader()

  for _, mesh in ipairs(self.opaqueMeshes) do
    shader:send("modelMatrix", mesh.model)
    if shader:hasUniform("shouldAnimate") then
      shader:send("shouldAnimate", false)
    end
    love.graphics.draw(mesh.mesh)
  end

  for _, mesh in ipairs(self.transparentMeshes) do
    shader:send("modelMatrix", mesh.model)
    if shader:hasUniform("shouldAnimate") then
      shader:send("shouldAnimate", true)
    end
    love.graphics.draw(mesh.mesh)
  end

  self.opaqueMeshes = {}
  self.transparentMeshes = {}
end

return World
