local Light = {}

local normals = {
  {  0,  0,  1 },
  {  0,  1,  0 },
  {  0,  0, -1 },
  {  0, -1,  0 },
  {  1,  0,  0 },
  { -1,  0,  0 },
}

function Light.propagateLight(queue)
  while #queue > 0 do
    local node = table.remove(queue, 1)
    local chunk, index = node[1], node[2]

    local i, j, k = chunk.decodeIndex(index)

    local light = chunk.lightMap[i][j][k]

    if light > 0 then
      for n = 1, 6 do
        local dir = normals[n]
        local x, y, z = i + dir[1] + chunk.position.x, j + dir[2] + chunk.position.y, k + dir[3] + chunk.position.z

        if y > 0 and y <= CHUNK_HEIGHT then
          local chunk = chunk.world:getChunk(x, z)
          local ci, cj, ck = x - chunk.position.x, y - chunk.position.y, z - chunk.position.z

          local block = chunk.blocks[ci][cj][ck]

          if block <= 0 and chunk.lightMap[ci][cj][ck] + 2 <= light then
            chunk.lightMap[ci][cj][ck] = light - 1
            chunk.blocks[ci][cj][ck] = light - 1 - 16

            chunk:scheduleUpdate(ci, cj, ck)

            local index = chunk.encodeIndex(ci, cj, ck)
            table.insert(queue, { chunk, index })
          end
        end
      end
    end
  end
end

function Light.setLight(chunk, i, j, k, value)
  chunk.lightMap[i][j][k] = value

  local index = chunk.encodeIndex(i, j, k)
  local queue = { { chunk, index } }

  Light.propagateLight(queue)
end

function Light.removeLight(chunk, i, j, k)
  local index = chunk.encodeIndex(i, j, k)
  local value = chunk.lightMap[i][j][k]

  chunk.lightMap[i][j][k] = 0
  chunk.blocks[i][j][k] = -16

  local queue = { { chunk, index, value } }
  local propagateQueue = {}

  while #queue > 0 do
    local node = table.remove(queue, 1)
    local chunk, index, value = node[1], node[2], node[3]

    local i, j, k = chunk.decodeIndex(index)
    local currentLight = value

    for n = 1, 6 do
      local dir = normals[n]
      local x, y, z = i + dir[1] + chunk.position.x, j + dir[2] + chunk.position.y, k + dir[3] + chunk.position.z

      if y > 0 and y <= CHUNK_HEIGHT then
        local chunk = chunk.world:getChunk(x, z)
        local ci, cj, ck = x - chunk.position.x, y - chunk.position.y, z - chunk.position.z

        local neighborLight = chunk.lightMap[ci][cj][ck]
        local index = chunk.encodeIndex(ci, cj, ck)

        if neighborLight ~= 0 and neighborLight < currentLight then
          chunk.lightMap[ci][cj][ck] = 0
          chunk.blocks[ci][cj][ck] = -16

          chunk:scheduleUpdate(ci, cj, ck)

          table.insert(queue, { chunk, index, neighborLight })
        elseif neighborLight >= currentLight then
          table.insert(propagateQueue, { chunk, index })
        end
      end
    end
  end

  Light.propagateLight(propagateQueue)
end

return Light
