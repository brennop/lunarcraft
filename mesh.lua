local CHUNK_SIZE = 8
local CHUNK_HEIGHT = 32

local shading = {
  0.3, 0.4, 0.6, 1,
}

function getVertex(index, i, mesh, x, y, z, value, cPos, getBlock)
  local vertexData = nil

  local cx, cy, cz = cPos[1], cPos[2], cPos[3]
  if value == 0 and mesh then
    local vertex = mesh[index*6+i]
    local vx, vy, vz, u, v, normal = unpack(vertex)

    local dx, dy, dz = 2*vx, 2*vy, 2*vz
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

    s = m * shading[state]

    vertexData = {
      vx + x + cx, vy + y + cy, vz + z + cz,
      u, v,
      s, s, s, 1
    }
  end

  local vi = i + (index)*6 + (x-1)*6*6 + (y-1)*6*6*CHUNK_SIZE + (z-1)*6*6*CHUNK_SIZE*CHUNK_HEIGHT

  return vertexData
end

return getVertex
