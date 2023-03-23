local Terrain = Object:extend()

local WATER_HEIGHT = 28

function Terrain:new(seed)
  self.seed = seed or love.math.random(1, 1000000)
  
  self.heightMap = {}

  love.math.setRandomSeed(self.seed)

  -- noise offsets
  self.offsetX = love.math.random(1, 1000000)
  self.offsetZ = love.math.random(1, 1000000)
end

function Terrain:generateHeight(wx, wz)
  x = wx + self.offsetX
  z = wz + self.offsetZ

  local height = 0
  local frequency = 0.01
  local amplitude = 1
  local max = 0

  for i = 1, 8 do
    height = height + love.math.noise(x * frequency, z * frequency) * amplitude
    max = max + amplitude
    amplitude = amplitude / 2
    frequency = frequency * 2
  end

  local h = height / max
  -- local e = math.exp(h * 4 - 4)
  local e = math.sin(h * math.pi - math.pi / 2) * 0.5 + 0.5

  return math.floor((e * 0.5 + 0.5) * CHUNK_HEIGHT)
end

function Terrain:generateHeightMap(wx, wz)
  for i = 1, CHUNK_SIZE do
    self.heightMap[i] = {}
    for j = 1, CHUNK_SIZE do
      local x = wx + i - 1
      local z = wz + j - 1
      self.heightMap[i][j] = self:generateHeight(x, z)
    end
  end
end

function Terrain:addWater(blocks)
  for i = 1, CHUNK_SIZE do
    for k = 1, CHUNK_SIZE do
      local height = self.heightMap[i][k]
      for j = height - 1, WATER_HEIGHT do
        local block = blocks[i][j][k]

        if block == 0 then
          blocks[i][j][k] = 4
        elseif j == WATER_HEIGHT then
          blocks[i][j][k] = 5
        end
      end
    end
  end
end

function Terrain:addTrees(blocks)
  local amount = love.math.random(0, 2)

  for i = 1, amount do
    local x = love.math.random(4, CHUNK_SIZE - 4)
    local z = love.math.random(4, CHUNK_SIZE - 4)
    local height = self.heightMap[x][z]

    local treeHeight = love.math.random(3, 5)

    if height > WATER_HEIGHT and height < CHUNK_HEIGHT - 10 then
      for j = 1, treeHeight do
        blocks[x][height + j][z] = 6
      end

      for i = -2, 2 do
        for k = -2, 2 do
          for j = 1, 3 do
            local shouldPlace = true

            if i == 2 and k == -2 and j ~= 2 then
              shouldPlace = love.math.random(0, 5) == 0
            elseif i == -2 and k == -2 and j ~= 2 then
              shouldPlace = love.math.random(0, 5) == 0
            else
              shouldPlace = true
            end

            if shouldPlace then
              blocks[x + i][height + treeHeight + j][z + k] = 7
            end
          end
        end
      end

      for i = -1, 1 do
        for k = -1, 1 do
          blocks[x + i][height + treeHeight + 4][z + k] = 7
        end
      end
    end
  end
end

function Terrain:generateChunk(wx, wz)
  local blocks = {}

  self:generateHeightMap(wx, wz)

  for i = 1, CHUNK_SIZE do
    blocks[i] = {}
    for j = 1, CHUNK_HEIGHT do
      blocks[i][j] = {}
      for k = 1, CHUNK_SIZE do
        local height = self.heightMap[i][k]

        if j == height then
          blocks[i][j][k] = 2
        elseif j < height and j > 16 then
          blocks[i][j][k] = 3
        elseif j < height then
          blocks[i][j][k] = 1
        else
          blocks[i][j][k] = 0
        end
      end
    end
  end

  self:addWater(blocks)
  self:addTrees(blocks)

  return blocks
end

return Terrain
