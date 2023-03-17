local Vector = require "vector"
local Matrix = require "matrix"

local cube = require "cube"

blockTypes = {
  -- 1: cobblestone
  cube({ { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 } }),
  -- 2: grass
  cube({ { 3, 30 }, { 3, 16 }, { 3, 30 }, { 3, 31 }, { 3, 30 }, { 3, 30 } }),
  -- 3: dirt
  cube({ { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 } }),
}

return blockTypes
