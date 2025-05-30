-- Shared constants for the Multiply or Die game
local Constants = {}

-- Platform dimensions and positioning
Constants.PLATFORM_DIM = 30
Constants.PLATFORM_HEIGHT = 50
Constants.PLATFORM_FALL = 50

-- Lane configuration
Constants.MAX_LANES = 30
Constants.LANE_SPACING_MULTIPLIER = 1.25

-- Timing
Constants.SPAWN_INTERVAL = 2 
Constants.GATE_COOLDOWN = 2

-- Player scaling
Constants.MAX_PLAYER_SIZE = 5.0
Constants.SCORE_TO_SIZE_RATIO = 200

-- Grass collision
Constants.GRASS_Y_THRESHOLD = 10

-- Terrain generation
Constants.TERRAIN_CHUNK_SIZE = 256
Constants.TERRAIN_BOTTOM_Y = -32
Constants.TERRAIN_TOP_Y = -30

-- Initial player values
Constants.INITIAL_PLAYER_SCORE = 10

return Constants 