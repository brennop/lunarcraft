local Chunk = Object:extend()

local blockTypes = require "src.blocks"
local Vector = require "src.vector"
local Matrix = require "src.matrix"

-- TODO: use less memory for the vertex
local format = {
  { "VertexPosition", "float", 3 }, -- 12 bytes
  { "VertexTexCoord", "float", 2 }, -- 8 bytes
  { "VertexNormal", "float", 3 },   -- 12 bytes
  { "VertexColor", "byte", 4 },     -- 4 bytes
}

local maxVertices = CHUNK_SIZE * CHUNK_HEIGHT * CHUNK_SIZE * 6 * 6

function Chunk:new(x, y, z, world)
  self.position = Vector(x * CHUNK_SIZE, y * CHUNK_HEIGHT, z * CHUNK_SIZE)
  self.world = world

  self.blocks = self.world.terrain:generateChunk(self.position.x, self.position.z)

  self.loaded = false
  self.dirty = true

  self.mesh = nil

  self.model = Matrix()
  self.model[4] = self.position.x
  self.model[8] = self.position.y
  self.model[12] = self.position.z

  self.channel = self:__tostring()

  self.done = nil
end

function Chunk:__tostring()
  local nx = math.floor((self.position.x-1) / CHUNK_SIZE)
  local nz = math.floor((self.position.z-1) / CHUNK_SIZE)
  return "Chunk: "..nx..", "..nz
end

function Chunk:load(thread)
  self.doneStart = love.timer.getTime()
  self.dirty = false

  -- each vertex is currently 36 bytes
  self.verticesData = love.data.newByteData(maxVertices * 36)

  -- add 1 to the size to include the border
  local blocks = {}
  for i = 0, CHUNK_SIZE + 1 do
    blocks[i] = {}
    for j = 0, CHUNK_HEIGHT + 1 do
      blocks[i][j] = {}
      for k = 0, CHUNK_SIZE + 1 do
        local x, y, z = self.position.x + i, self.position.y + j, self.position.z + k
        blocks[i][j][k] = self.world:getBlock(x, y, z)
      end
    end
  end

  thread:start(self.position:table(), blocks, self.channel, blockTypes, self.verticesData)
end

function Chunk:getBlock(x, y, z)
  if y < 1 or y > CHUNK_HEIGHT then return 0 end

  -- translate to local coordinates
  local i, j, k = x - self.position.x, y - self.position.y, z - self.position.z

  return self.blocks[i][j][k]
end

function Chunk:setBlock(x, y, z, block)
  if y < 1 or y > CHUNK_HEIGHT then return end

  -- translate to local coordinates
  local i, j, k = x - self.position.x, y - self.position.y, z - self.position.z

  if self.blocks[i][j][k] == block then return end

  self.blocks[i][j][k] = block

  self.dirty = true

  -- if border block, mark adjacent chunks as dirty
  local adjacentX, adjacentZ
  if i == 1 then
    adjacentX = self.world:getChunk(x - 1, z)
  elseif i == CHUNK_SIZE then
    adjacentX = self.world:getChunk(x + 1, z)
  end

  if k == 1 then
    adjacentZ = self.world:getChunk(x, z - 1)
  elseif k == CHUNK_SIZE then
    adjacentZ = self.world:getChunk(x, z + 1)
  end

  if adjacentX then adjacentX.dirty = true end
  if adjacentZ then adjacentZ.dirty = true end
end

function Chunk:update()
  local message = love.thread.getChannel(self.channel):pop()

  if message then
    local numVertices = message

    self.done = love.timer.getTime() - self.doneStart
    print("Chunk done in "..self.done.." seconds")

    if numVertices == 0 then return end

    if self.mesh then self.mesh:release() end

    self.mesh = love.graphics.newMesh(format, numVertices, "triangles", "static")
    self.mesh:setTexture(tileset)
    self.mesh:setVertices(self.verticesData, 1, numVertices)

    self.verticesData:release()
  end
end

function Chunk:draw()
  if self.mesh then 
    love.graphics.getShader():send("modelMatrix", self.model)
    love.graphics.draw(self.mesh)
  end
end

return Chunk
