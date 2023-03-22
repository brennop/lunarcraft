local Chunk = Object:extend()

local blockTypes = require "blocks"
local Vector = require "vector"
local Matrix = require "matrix"

-- TODO: use less memory for the vertex
local format = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
  { "VertexNormal", "float", 3 },
  { "VertexColor", "byte", 4 },
}

local maxVertices = CHUNK_SIZE * CHUNK_HEIGHT * CHUNK_SIZE * 6 * 6

function Chunk:new(x, y, z, world)
  self.position = Vector(x * CHUNK_SIZE, y * CHUNK_HEIGHT, z * CHUNK_SIZE)
  self.world = world

  self.blocks = {}

  self.loaded = false
  self.dirty = true

  for i = 1, CHUNK_SIZE do
    self.blocks[i] = {}
    for j = 1, CHUNK_HEIGHT do
      self.blocks[i][j] = {}
      for k = 1, CHUNK_SIZE do
        local x, y, z = self.position.x + i, self.position.y + j, self.position.z + k

        local h = CHUNK_HEIGHT - math.floor(love.math.noise(x/20, z/20, 0) * 16) - 1
        local c = math.floor(love.math.noise(x/8, y/4, z/8, 1)*2)

        if j == h then
          self.blocks[i][j][k] = 2
        elseif j <= 4 then
          self.blocks[i][j][k] = 1
        elseif j < h and j > 16 then
          self.blocks[i][j][k] = c * 3
        elseif j < h and j <= 16 then
          self.blocks[i][j][k] = c
        else
          self.blocks[i][j][k] = 0
        end
      end
    end
  end

  self.mesh = nil

  self.model = Matrix()
  self.model[4] = self.position.x
  self.model[8] = self.position.y
  self.model[12] = self.position.z

  self.channel = self:__tostring()
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

function Chunk:load(thread)
  self.dirty = false

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

  thread:start(self.position:table(), blocks, self.channel, blockTypes)
end

function Chunk:getBlock(x, y, z)
  if y < 1 or y > CHUNK_HEIGHT then return 0 end

  -- translate to local coordinates
  x = x - self.position.x
  y = y - self.position.y
  z = z - self.position.z

  return self.blocks[x][y][z]
end

function Chunk:setBlock(x, y, z, block)
  if y < 1 or y > CHUNK_HEIGHT then return end

  -- translate to local coordinates
  local i, j, k = x - self.position.x, y - self.position.y, z - self.position.z

  if self.blocks[i][j][k] == block then return end

  self.blocks[i][j][k] = block

  self.dirty = true
end

function Chunk:update()
  local message = love.thread.getChannel(self.channel):pop()

  if message then
    local vertices = message
    if self.mesh then self.mesh:release() end

    self.mesh = love.graphics.newMesh(format, vertices, "triangles", "static")
    self.mesh:setTexture(tileset)
  end
end

function Chunk:draw()
  if self.mesh then 
    love.graphics.getShader():send("modelMatrix", self.model)
    love.graphics.draw(self.mesh)
  end
end

return Chunk
