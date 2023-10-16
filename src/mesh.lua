local CHUNK_SIZE = 8
local CHUNK_HEIGHT = 32

local blockTypes = require "src.blocks"

local shading = {
  0.3, 0.4, 0.6, 1,
}

function sign(value)
  if value > 0 then
    return 1
  elseif value < 0 then
    return -1
  else
    return 0
  end
end

local translucent = {
  [4] = true,
  [7] = true,
}

function setVertex(index, i, mesh, x, y, z, value, getBlock, outVertex)
  local block = getBlock(x, y, z)

  if not mesh then return false end

  local vertex = mesh[index*6+i]
  local vx, vy, vz, u, v, normal, alpha = unpack(vertex)

  if (value == 0 or (translucent[value] and block ~= value)) and mesh then
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
    outVertex.r, outVertex.g, outVertex.b, outVertex.a = s, s, s, alpha * 255

    return true
  end

  return false
end

return setVertex
