local Chunk = Object:extend()

local blockTypes = require "blocks"
local Vector = require "vector"
local Matrix = require "matrix"

local format = {
  { "VertexPosition", "float", 3 },
  { "VertexTexCoord", "float", 2 },
  { "VertexNormal", "float", 3 },
  { "VertexColor", "byte", 4 },
}

function Chunk:new(x, y, z, world)
  self.position = Vector(x * CHUNK_SIZE, y * CHUNK_HEIGHT, z * CHUNK_SIZE)
  self.world = world

  self.blocks = {}

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

  maxVertices = CHUNK_SIZE * CHUNK_HEIGHT * CHUNK_SIZE * 6 * 6
  self.mesh = love.graphics.newMesh(format, maxVertices, "triangles")
  self.mesh:setTexture(tileset)

  self.model = Matrix()
end

function Chunk:updateMesh()
  local vertices = {}

  local function addFace(index, mesh, x, y, z)
    for i = 1, 6 do
      local vertex = mesh[index*6+i]
      local vx, vy, vz, u, v, s = unpack(vertex)
      table.insert(vertices, {
        vx + x, vy + y, vz + z,
        u, v,
        0, 0, 0,
        s, s, s, 255
      })
    end
  end

  local cx, cy, cz = self.position:unpack()
  for i = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for k = 1, CHUNK_SIZE do
        local block = self.blocks[i][j][k]
        if block > 0 then
          local mesh = blockTypes[block]
          local x, y, z = i + cx, j + cy, k + cz

          if self.world:getBlock(x, y, z + 1) == 0 then addFace(0, mesh, x, y, z) end
          if self.world:getBlock(x, y + 1, z) == 0 then addFace(1, mesh, x, y, z) end
          if self.world:getBlock(x, y, z - 1) == 0 then addFace(2, mesh, x, y, z) end
          if self.world:getBlock(x, y - 1, z) == 0 then addFace(3, mesh, x, y, z) end
          if self.world:getBlock(x + 1, y, z) == 0 then addFace(4, mesh, x, y, z) end
          if self.world:getBlock(x - 1, y, z) == 0 then addFace(5, mesh, x, y, z) end
        end
      end
    end
  end

  -- self.mesh:setVertices(vertices)
  self.mesh:release()
  self.mesh = love.graphics.newMesh(format, vertices, "triangles")
  self.mesh:setTexture(tileset)
end

function Chunk:getBlock(x, y, z)
  if y < 1 or y > CHUNK_HEIGHT then return 0 end

  -- translate to local coordinates
  x = x - self.position.x
  y = y - self.position.y
  z = z - self.position.z

  return self.blocks[x][y][z]
end

function Chunk:clear()
  for i = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for k = 1, CHUNK_SIZE do
        self.blocks[i][j][k] = 0
      end
    end
  end
  self:updateMesh()
end

function Chunk:setBlock(x, y, z, block)
  if y < 1 or y > CHUNK_HEIGHT then return end

  -- translate to local coordinates
  x = x - self.position.x
  y = y - self.position.y
  z = z - self.position.z

  if self.blocks[x][y][z] == block then return end

  if block == 0 then
    print("destroyed block at", x, y, z)
  end

  self.blocks[x][y][z] = block
  self:updateMesh()

  if x == 1 then 
    self.world:getChunk(x - 8, z):updateMesh()
  elseif x == CHUNK_SIZE then 
    self.world:getChunk(x, z):updateMesh()
  end

  if z == 1 then
    self.world:getChunk(x - 8, z - 8):updateMesh()
  elseif z == CHUNK_SIZE then
    self.world:getChunk(x - 8, z):updateMesh()
  end
end

function Chunk:draw()
  love.graphics.getShader():send("modelMatrix", self.model)
  love.graphics.draw(self.mesh)
end

return Chunk
