local cube = require "src.cube"

blockTypes = {
  -- 1: cobblestone
  cube({ { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 } }),
  -- 2: grass
  cube({ { 3, 30 }, { 3, 17 }, { 3, 30 }, { 3, 31 }, { 3, 30 }, { 3, 30 } }),
  -- 3: dirt
  cube({ { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 } }),
}

return blockTypes
