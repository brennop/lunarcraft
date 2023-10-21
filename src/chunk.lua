local Chunk = Object:extend()

local blockTypes = require "src.blocks"
local Vector = require "src.vector"
local Matrix = require "src.matrix"

local getMesh = require "src.mesh"

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

  self.mesh = nil

  self.model = Matrix()
  self.model[4] = self.position.x
  self.model[8] = self.position.y
  self.model[12] = self.position.z
end

function Chunk:__tostring()
  local nx = math.floor((self.position.x-1) / CHUNK_SIZE)
  local nz = math.floor((self.position.z-1) / CHUNK_SIZE)
  return "Chunk: "..nx..", "..nz
end

function Chunk.encodeIndex(i, j, k)
  return i + (j-1) * CHUNK_SIZE + (k-1) * CHUNK_SIZE * CHUNK_HEIGHT
end

function Chunk.decodeIndex(index)
  local i = (index - 1) % CHUNK_SIZE + 1
  local j = math.floor((index - 1) / CHUNK_SIZE) % CHUNK_HEIGHT + 1
  local k = math.floor((index - 1) / (CHUNK_SIZE * CHUNK_HEIGHT)) % CHUNK_SIZE + 1

  return i, j, k
end

function Chunk:load()
  local start = love.timer.getTime()

  self.dirty = false

  -- add 1 to the size to include the border
  local blocks = {}
  for i = 0, CHUNK_SIZE + 1 do
    blocks[i] = {}
    for j = 0, CHUNK_HEIGHT + 1 do
      blocks[i][j] = {}
      for k = 0, CHUNK_SIZE + 1 do
        if i == 0 or i == CHUNK_SIZE + 1 or
           j == 0 or j == CHUNK_HEIGHT + 1 or
           k == 0 or k == CHUNK_SIZE + 1 then
          local x, y, z = self.position.x + i, self.position.y + j, self.position.z + k
          blocks[i][j][k] = self.world:getBlock(x, y, z)
        else
          blocks[i][j][k] = self.blocks[i][j][k]
        end
      end
    end
  end

  local vertices = getMesh(self.position:table(), blocks)

  if self.mesh then self.mesh:release() end

  self.mesh = love.graphics.newMesh(format, vertices, "triangles", "static")
  self.mesh:setTexture(tileset)

  local elapsed = love.timer.getTime() - start
  table.insert(self.world.debugChunkTimes, elapsed * 1000)
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

  -- mark chunk as dirty
  self.world:markDirty(self)

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

  if adjacentX then self.world:markDirty(adjacentX) end
  if adjacentZ then self.world:markDirty(adjacentZ) end
end

function Chunk:update()
end

function Chunk:draw()
  if self.mesh then
    love.graphics.getShader():send("modelMatrix", self.model)
    love.graphics.draw(self.mesh)
  end
end

return Chunk
