local cube = require "src.cube"

blockTypes = {
  -- 1: cobblestone
  cube({ { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 }, { 8, 1 } }),
  -- 2: grass
  cube({ { 3, 30 }, { 3, 17 }, { 3, 30 }, { 3, 31 }, { 3, 30 }, { 3, 30 } }),
  -- 3: dirt
  cube({ { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 }, { 3, 31 } }),
  -- 4: water
  cube({ { 2, 9 }, { 2, 9 }, { 2, 9 }, { 2, 9 }, { 2, 9 }, { 2, 9 } }, {
    vertices = {
      { -1, -1,  1 },
      {  1, -1,  1 },
      { -1,  0.75,  1 },
      {  1,  0.75,  1 },
      { -1,  0.75, -1 },
      {  1,  0.75, -1 },
      { -1, -1, -1 },
      {  1, -1, -1 },
    },
    alpha = 0.5
  }),
  -- 5: sand
  cube({ { 3, 7 }, { 3, 7 }, { 3, 7 }, { 3, 7 }, { 3, 7 }, { 3, 7 } }),
  -- 6: wood
  cube({ { 14, 13 }, { 15, 13 }, { 14, 13 }, { 15, 13 }, { 14, 13 }, { 14, 13 } }),
  -- 7: leaves
  cube({ { 1, 17 }, { 1, 17 }, { 1, 17 }, { 1, 17 }, { 1, 17 }, { 1, 17 } }, { 
    alpha = 0.95
  }),
}

return blockTypes
