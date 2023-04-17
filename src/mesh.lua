-- to be run on another thread
local CHUNK_SIZE = 16
local CHUNK_HEIGHT = 48

local position, blocks, channel, blockTypes, dataTable = ...

local ffi = require "ffi"

local shading = {
  0.3, 0.4, 0.6, 1,
}

local function sign(value)
  if value > 0 then
    return 1
  elseif value < 0 then
    return -1
  else
    return 0
  end
end

local function getBlock(i, j, k)
  return blocks[i][j][k]
end

function setVertex(index, i, mesh, x, y, z, outVertex)
  local block = getBlock(x, y, z)

  local vertex = mesh[index*6+i]
  local vx, vy, vz, u, v, normal = unpack(vertex)

  local dx, dy, dz = sign(vx), sign(vy), sign(vz)
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

  s = shading[state] * 255

  outVertex.x, outVertex.y, outVertex.z = vx + x, vy + y, vz + z
  outVertex.u, outVertex.v = u, v
  outVertex.nx, outVertex.ny, outVertex.nz = nx, ny, nz
  outVertex.r, outVertex.g, outVertex.b, outVertex.a = s, s, s, mesh.alpha * 255

  return true
end

ffi.cdef [[
typedef struct {
  float x, y, z;
  float u, v;
  float nx, ny, nz;
  unsigned char r, g, b, a;
} ck_vertex;
]]


function getMesh(opaque, data)
  local pointer = ffi.cast('ck_vertex*', data:getFFIPointer())

  local vi = 0

  function setFace(index, mesh, x, y, z, value)
    for i = 1, 6 do
      local vertex = pointer[vi]
      local prev = blockTypes[value]

      if (value == 0 or prev.opaque ~= opaque) and mesh.opaque == opaque then
        setVertex(index, i, mesh, x, y, z, vertex)
        vi = vi + 1
      end
    end
  end

  for k = 1, CHUNK_SIZE do
    for j = 1, CHUNK_HEIGHT do
      for i = 1, CHUNK_SIZE do
        local block = blocks[i][j][k]
        local mesh = blockTypes[block]

        if mesh then
          setFace(0, mesh, i, j, k, getBlock(i, j, k + 1))
          setFace(1, mesh, i, j, k, getBlock(i, j + 1, k))
          setFace(2, mesh, i, j, k, getBlock(i, j, k - 1))
          setFace(3, mesh, i, j, k, getBlock(i, j - 1, k))
          setFace(4, mesh, i, j, k, getBlock(i + 1, j, k))
          setFace(5, mesh, i, j, k, getBlock(i - 1, j, k))
        end
      end
    end
  end

  local channelSuffix = opaque and "opaque" or "transparent"

  love.thread.getChannel(channel .. channelSuffix):supply(vi)
end

getMesh(true, dataTable.opaque)
getMesh(false, dataTable.transparent)
