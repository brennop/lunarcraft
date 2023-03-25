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

local function getBlock(i, j, k)
  return blocks[i][j][k]
end

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

  for k = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for i = 1, CHUNK_SIZE do
        local block = blocks[i][j][k]
        local mesh = blockTypes[block]

        setFace(0, mesh, i, j, k, getBlock(i, j, k + 1))
        setFace(1, mesh, i, j, k, getBlock(i, j + 1, k))
        setFace(2, mesh, i, j, k, getBlock(i, j, k - 1))
        setFace(3, mesh, i, j, k, getBlock(i, j - 1, k))
        setFace(4, mesh, i, j, k, getBlock(i + 1, j, k))
        setFace(5, mesh, i, j, k, getBlock(i - 1, j, k))
      end
    end
  end

  love.thread.getChannel(channel):supply(vi)
end

getMesh()
