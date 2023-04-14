-- to be run on another thread
local CHUNK_SIZE = 16
local CHUNK_HEIGHT = 48

local position, blocks, channel, blockTypes, data = ...

local getVertex = require "src.mesh"

local ffi = require "ffi"

ffi.cdef [[
typedef struct {
  float x, y, z;
  float u, v;
  float nx, ny, nz;
  unsigned char r, g, b, a;
} ck_vertex;
]]

local function encodeIndex(i, j, k)
  return i + (j-1) * CHUNK_SIZE + (k-1) * CHUNK_SIZE * CHUNK_HEIGHT
end

local function decodeIndex(index)
  local i = (index - 1) % CHUNK_SIZE + 1
  local j = math.floor((index - 1) / CHUNK_SIZE) % CHUNK_HEIGHT + 1
  local k = math.floor((index - 1) / (CHUNK_SIZE * CHUNK_HEIGHT)) % CHUNK_SIZE + 1

  return i, j, k
end


local function getBlock(i, j, k)
  return blocks[i][j][k]
end

-- face indexes
-- 0: front
-- 1: top
-- 2: back
-- 3: bottom
-- 4: right
-- 5: left

local normals = {
  {  0,  0,  1 },
  {  0,  1,  0 },
  {  0,  0, -1 },
  {  0, -1,  0 },
  {  1,  0,  0 },
  { -1,  0,  0 },
}

function getMesh()
  local pointer = ffi.cast('ck_vertex*', data:getFFIPointer())

  local vi = 0

  function setFace(index, mesh, x, y, z, value)
    for i = 1, 6 do
      local vertex = pointer[vi]
      local vertexData = setVertex(index, i, mesh, x, y, z, value, getBlock, vertex)

      if vertexData then
        vi = vi + 1
      end
    end
  end

  local queue = { encodeIndex(1, CHUNK_HEIGHT, 1) }
  local visited = {}
  
  while #queue > 0 do
    local current = table.remove(queue, 1)

    if not visited[current] then
      visited[current] = true

      local x, y, z = decodeIndex(current)

      local value = getBlock(x, y, z)

      if value == 0 then
        -- check neighbors
        for i = 1, 6 do
          local nx, ny, nz = x + normals[i][1] * -1, y + normals[i][2] * -1, z + normals[i][3] * -1

          -- check boundaries
          if nx >= 0 and nx <= CHUNK_SIZE and ny >= 0 and ny <= CHUNK_HEIGHT and nz >= 0 and nz <= CHUNK_SIZE then
            local block = getBlock(nx, ny, nz)

            if block == 0 then
              table.insert(queue, encodeIndex(nx, ny, nz))
            else
              local mesh = blockTypes[block]
              setFace(i - 1, mesh, nx, ny, nz, value)
            end
          end
        end
      end
    end
  end

  love.thread.getChannel(channel):supply(vi)
end

getMesh()
