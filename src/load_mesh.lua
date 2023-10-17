local CHUNK_SIZE = 16
local CHUNK_HEIGHT = 48

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


function getMesh(position, blocks, blockTypes, data)
  local function getBlock(i, j, k)
    return blocks[i][j][k]
  end

  local pointer = ffi.cast('ck_vertex*', data:getFFIPointer())

  local vi = 0

  function setFace(index, mesh, x, y, z, value)
    for i = 1, 6 do
      if value == 0 and mesh then
        setVertex(index, i, mesh, x, y, z, value, getBlock, pointer, vi)

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

  return vi
end

return getMesh
