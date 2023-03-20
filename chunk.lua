local Chunk = Object:extend()

local blockTypes = require "blocks"
local Vector = require "vector"
local Matrix = require "matrix"
local getVertex = require "mesh"

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

  for i = 1, CHUNK_SIZE do
    self.blocks[i] = {}
    for j = 1, CHUNK_HEIGHT do
      self.blocks[i][j] = {}
      for k = 1, CHUNK_SIZE do
        local x, y, z = self.position.x + i, self.position.y + j, self.position.z + k

        local h = CHUNK_HEIGHT - math.floor(love.math.noise(x/10, z/10, 0) * 8)
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

  self:updateLight()

  self.mesh = love.graphics.newMesh(format, maxVertices, "triangles")
  self.mesh:setTexture(tileset)

  self.model = Matrix()

  self.channel = "chunk"..x..y..z
  self.thread = love.thread.newThread("load_mesh.lua")

  self.start = 1
  self.step = 4
end

function Chunk:load()
  self.done = true

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

  self.thread:start(self.position:table(), blocks, self.channel, blockTypes)
end

function Chunk:setFace(index, mesh, x, y, z, value)
  local function getBlock(i, j, k)
    local x, y, z = self.position.x + i, self.position.y + j, self.position.z + k
    return self.world:getBlock(x, y, z)
  end

  for i = 1, 6 do
    local vi, vertexData = getVertex(index, i, mesh, x, y, z, value, self.position:table(), getBlock)

    self.mesh:setVertex(vi, vertexData)
  end
end

function Chunk:updateMesh()
  local vertices = {}
  local v = 1

  local cx, cy, cz = self.position:unpack()

  for k = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for i = 1, CHUNK_SIZE do
        local block = self.blocks[i][j][k]
        local mesh = blockTypes[block]
        local x, y, z = i + cx, j + cy, k + cz

        self:setFace(0, mesh, i, j, k, self.world:getBlock(x, y, z + 1))
        self:setFace(1, mesh, i, j, k, self.world:getBlock(x, y + 1, z))
        self:setFace(2, mesh, i, j, k, self.world:getBlock(x, y, z - 1))
        self:setFace(3, mesh, i, j, k, self.world:getBlock(x, y - 1, z))
        self:setFace(4, mesh, i, j, k, self.world:getBlock(x + 1, y, z))
        self:setFace(5, mesh, i, j, k, self.world:getBlock(x - 1, y, z))
      end
    end
  end

  self.mesh:setVertices(vertices)
end

function Chunk:updateBlockMesh(x, y, z)
  if y < 1 or y > CHUNK_HEIGHT then return end

  -- translate to local coordinates
  local i, j, k = x - self.position.x, y - self.position.y, z - self.position.z

  local block = self.blocks[i][j][k]
  local mesh = blockTypes[block]

  self:setFace(0, mesh, i, j, k, self.world:getBlock(x, y, z + 1))
  self:setFace(1, mesh, i, j, k, self.world:getBlock(x, y + 1, z))
  self:setFace(2, mesh, i, j, k, self.world:getBlock(x, y, z - 1))
  self:setFace(3, mesh, i, j, k, self.world:getBlock(x, y - 1, z))
  self:setFace(4, mesh, i, j, k, self.world:getBlock(x + 1, y, z))
  self:setFace(5, mesh, i, j, k, self.world:getBlock(x - 1, y, z))
end

function Chunk:getBlock(x, y, z)
  if y < 1 or y > CHUNK_HEIGHT then return 0 end

  -- translate to local coordinates
  x = x - self.position.x
  y = y - self.position.y
  z = z - self.position.z

  return self.blocks[x][y][z]
end

function Chunk:updateLight()
  local normals = {
    {  0,  0,  1 },
    {  0,  0, -1 },
    {  0, -1,  0 },
    {  1,  0,  0 },
    { -1,  0,  0 },
  }

  local lights = {}
  for i = 1, CHUNK_SIZE do
    lights[i] = {}
    for j = 1, CHUNK_HEIGHT do
      lights[i][j] = {}
      for k = 1, CHUNK_SIZE do
        lights[i][j][k] = 0
      end
    end
  end

  -- start at the top, in the middle and work our way down
  local sx, sy, sz = math.floor(CHUNK_SIZE / 2), CHUNK_HEIGHT, math.floor(CHUNK_SIZE / 2)
  lights[sx][sy][sz] = CHUNK_HEIGHT

  -- traverse the chunk, propagating light
  local queue = {}
  
  table.insert(queue, { sx, sy, sz })

  while #queue > 0 do
    local x, y, z = unpack(table.remove(queue, 1))
    local light = lights[x][y][z]

    for i = 1, 5 do
      local nx, ny, nz = x + normals[i][1], y + normals[i][2], z + normals[i][3]

      if nx < 1 or nx > CHUNK_SIZE or ny < 1 or ny > CHUNK_HEIGHT or nz < 1 or nz > CHUNK_SIZE then
        goto continue
      end

      local block = self.blocks[nx][ny][nz]
      if block <= 0 then
        local nlight = light - 1
        if nlight > lights[nx][ny][nz] then
          lights[nx][ny][nz] = nlight
          table.insert(queue, { nx, ny, nz })
        end
      end

      ::continue::
    end
  end

  for i = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for k = 1, CHUNK_SIZE do
        local block = self.blocks[i][j][k]
        if block <= 0 then
          self.blocks[i][j][k] = math.min(lights[i][j][k], 8) - 8
        end
      end
    end
  end
end

function Chunk:setBlock(x, y, z, block)
  if y < 1 or y > CHUNK_HEIGHT then return end

  -- translate to local coordinates
  local i, j, k = x - self.position.x, y - self.position.y, z - self.position.z

  if self.blocks[i][j][k] == block then return end

  self.blocks[i][j][k] = block
  -- self.world:updateBlockMesh(x, y, z)
  self:updateLight()
  self:updateMesh()
end

function Chunk:update()
  local message = love.thread.getChannel(self.channel):pop()

  if message then
    local vertices, start, count = unpack(message)
    self.mesh:setVertices(vertices, start, count)
  end
end

function Chunk:draw()
  love.graphics.getShader():send("modelMatrix", self.model)
  love.graphics.draw(self.mesh)
end

return Chunk
