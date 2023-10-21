local CHUNK_SIZE = 16
local CHUNK_HEIGHT = 48

local blockTypes = require "src.blocks"

local shading = {
  0.3, 0.4, 0.6, 1,
}

local translucent = {
  [4] = true,
  [7] = true,
}

local function getVertex(vertex, x, y, z, value, getBlock, pointer, vi)
  local block = getBlock(x, y, z)

  local vx, vy, vz, u, v, normal, alpha, dx, dy, dz = unpack(vertex)

  local nx, ny, nz = normal[1], normal[2], normal[3]
  local side1, side2, corner, m

  if nx ~= 0 then
    side1 = getBlock(x + nx, y + dy, z) == 0 and 0 or 1
    side2 = getBlock(x + nx, y, z + dz) == 0 and 0 or 1
    corner = getBlock(x + nx, y + dy, z + dz) == 0 and 0 or 1
    m = nx == 1 and 0.8 or 0.6
  elseif ny ~= 0 then
    side1 = getBlock(x + dx, y + ny, z) == 0 and 0 or 1
    side2 = getBlock(x, y + ny, z + dz) == 0 and 0 or 1
    corner = getBlock(x + dx, y + ny, z + dz) == 0 and 0 or 1
    m = ny == 1 and 1 or 0.4
  elseif nz ~= 0 then
    side1 = getBlock(x + dx, y, z + nz) == 0 and 0 or 1
    side2 = getBlock(x, y + dy, z + nz) == 0 and 0 or 1
    corner = getBlock(x + dx, y + dy, z + nz) == 0 and 0 or 1
    m = nz == 1 and 0.6 or 0.8
  end

  local state

  if side1 == 1 and side2 == 1 then
    state = 1
  else
    state = 4 - side1 - side2 - corner
  end

  s = shading[state]

  return {
    vx + x, vy + y, vz + z,
    u, v,
    nx, ny, nz,
    s, s, s, alpha * 255,
  }
end

function getMesh(position, blocks)
  local function getBlock(i, j, k)
    return blocks[i][j][k]
  end

  local vi = 0
  local data = {}

  function setFace(index, mesh, x, y, z, value, block)
    if (value == 0 or (translucent[value] and block ~= value)) and mesh then
      for i = 1, 6 do
        local vertex = getVertex(mesh[index * 6 + i], x, y, z, value, getBlock)

        vi = vi + 1
        data[vi] = vertex
      end
    end
  end

  for k = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for i = 1, CHUNK_SIZE do
        local block = blocks[i][j][k]
        local mesh = blockTypes[block]

        setFace(0, mesh, i, j, k, getBlock(i, j, k + 1), block)
        setFace(1, mesh, i, j, k, getBlock(i, j + 1, k), block)
        setFace(2, mesh, i, j, k, getBlock(i, j, k - 1), block)
        setFace(3, mesh, i, j, k, getBlock(i, j - 1, k), block)
        setFace(4, mesh, i, j, k, getBlock(i + 1, j, k), block)
        setFace(5, mesh, i, j, k, getBlock(i - 1, j, k), block)
      end
    end
  end

  return data
end

return getMesh
