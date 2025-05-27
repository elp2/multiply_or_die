-- Shared constants for the Multiply or Die game
local Constants = {}

-- Platform dimensions and positioning
Constants.PLATFORM_DIM = 30
Constants.PLATFORM_HEIGHT = 50
Constants.PLATFORM_FALL = 50

-- Lane configuration
Constants.MAX_LANES = 30
Constants.LANE_SPACING_MULTIPLIER = 1.25  -- Creates 0.25x gap between lanes

-- Timing
Constants.SPAWN_INTERVAL = 2  -- Seconds between platform spawns
Constants.GATE_COOLDOWN = 2   -- Seconds between gate touches for same player

-- Player scaling
Constants.MAX_PLAYER_SIZE = 10.0
Constants.SCORE_TO_SIZE_RATIO = 200  -- Divide score by this for size multiplier

-- Grass collision
Constants.GRASS_Y_THRESHOLD = 10  -- Y position below which player is considered to have hit grass

-- Initial player values
Constants.INITIAL_PLAYER_SCORE = 10

return Constants 