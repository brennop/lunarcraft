local Light = {}

local maxLight = 8

local normals = {
  {  0,  0,  1 },
  {  0,  1,  0 },
  {  0,  0, -1 },
  {  1,  0,  0 },
  { -1,  0,  0 },
  {  0, -1,  0 },
}

function Light.updateSunLight(chunk)
  local j = CHUNK_HEIGHT
  local queue = {}

  for i = 1, CHUNK_SIZE do
    for k = 1, CHUNK_SIZE do
      chunk.lightMap[i][j][k] = maxLight
      local index = chunk.encodeIndex(i, j, k)
      table.insert(queue, { chunk, index })
    end
  end

  Light.propagateLight(queue)
end

function Light.propagateLight(queue)
  while #queue > 0 do
    local node = table.remove(queue, 1)
    local chunk, index = node[1], node[2]

    local i, j, k = chunk.decodeIndex(index)

    local light = chunk.lightMap[i][j][k]

    if light > 0 then
      -- down propagation
      if j > 1 then
        local cj = j - 1
        local block = chunk.blocks[i][cj][k]
        if block <= 0 and light == maxLight then
          chunk.lightMap[i][cj][k] = maxLight
          chunk.blocks[i][cj][k] = 0

          chunk:scheduleUpdate(i, cj, k)

          local index = chunk.encodeIndex(i, cj, k)
          table.insert(queue, { chunk, index })
        end
      end

      for n = 1, 6 do
        local dir = normals[n]
        local x, y, z = i + dir[1] + chunk.position.x, j + dir[2] + chunk.position.y, k + dir[3] + chunk.position.z
        local chunk = chunk.world:getChunk(x, z)

        if y > 0 and y <= CHUNK_HEIGHT and chunk then
          local ci, cj, ck = x - chunk.position.x, y - chunk.position.y, z - chunk.position.z

          local block = chunk.blocks[ci][cj][ck]

          if block <= 0 and chunk.lightMap[ci][cj][ck] + 2 <= light then
            chunk.lightMap[ci][cj][ck] = light - 1
            chunk.blocks[ci][cj][ck] = light - 1 - maxLight

            chunk:scheduleUpdate(ci, cj, ck)

            local index = chunk.encodeIndex(ci, cj, ck)
            table.insert(queue, { chunk, index })
          end
        end
      end
    end
  end
end

function Light.addLight(chunk, i, j, k)
  local value = chunk.lightMap[i][j][k]

  if j < CHUNK_HEIGHT then
    value = chunk.lightMap[i][j + 1][k]
  end

  -- TODO: sample from neighbors

  Light.setLight(chunk, i, j, k, value)
end

function Light.setLight(chunk, i, j, k, value)
  chunk.lightMap[i][j][k] = value

  local index = chunk.encodeIndex(i, j, k)
  local queue = { { chunk, index } }

  Light.propagateLight(queue)
end

function Light.removeLight(chunk, i, j, k, block)
  local index = chunk.encodeIndex(i, j, k)
  local value = chunk.lightMap[i][j][k]

  chunk.lightMap[i][j][k] = 0
  chunk.blocks[i][j][k] = block

  local queue = { { chunk, index, value } }
  local propagateQueue = {}

  while #queue > 0 do
    local node = table.remove(queue, 1)
    local chunk, index, value = node[1], node[2], node[3]

    local i, j, k = chunk.decodeIndex(index)
    local currentLight = value

    -- down propagation
    if j > 1 then
      local cj = j - 1
      local block = chunk.blocks[i][cj][k]
      if block <= 0 and currentLight == maxLight then
        chunk.lightMap[i][cj][k] = 0
        chunk.blocks[i][cj][k] = -maxLight

        chunk:scheduleUpdate(i, cj, k)

        local index = chunk.encodeIndex(i, cj, k)
        table.insert(queue, { chunk, index, currentLight })
      end
    end

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
          chunk.blocks[ci][cj][ck] = -maxLight

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
