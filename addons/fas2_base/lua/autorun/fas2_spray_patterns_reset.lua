AddCSLuaFile("autorun/fas2_spray_patterns_reset.lua")

if FAS2_CS2SprayResetLoaded then return end
FAS2_CS2SprayResetLoaded = true

-- CS2/Rust hybrid spray reset.
-- The values below are final intended angle offsets in degrees; install()
-- divides by FAS2_RecoilScale because GetSprayOffset multiplies by it later.
-- That keeps bullets, camera lift, ADS, hipfire, and the follow dot reading
-- from one deterministic pattern source.

FAS2_SprayPatterns = FAS2_SprayPatterns or {}
FAS2_RecoilScale = FAS2_RecoilScale or {}
FAS2_SprayResetTime = FAS2_SprayResetTime or {}
FAS2_PatternInvertPitch = FAS2_PatternInvertPitch or {}
FAS2_MuzzleVelocity = FAS2_MuzzleVelocity or {}
FAS2_Ballistics = FAS2_Ballistics or {}
FAS2_CS2SprayResetLock = true

local RESET_VERSION = "2026-05-24-leetify-scale-v4"

local DEFAULT_PATTERN_PITCH_SCALE = 2.5
local DEFAULT_PATTERN_YAW_SCALE = 2.5

FAS2_CS2PatternScalePitch = DEFAULT_PATTERN_PITCH_SCALE
FAS2_CS2PatternScaleYaw = DEFAULT_PATTERN_YAW_SCALE

if SERVER then
	print("[FAS2] CS2/Rust spray reset loader active " .. RESET_VERSION)
end

local function clamp(v, lo, hi)
	return math.min(math.max(v, lo), hi)
end

local function smooth(t)
	t = clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function mix(a, b, t)
	return a + (b - a) * t
end

local function round3(v)
	if v >= 0 then
		return math.floor(v * 1000 + 0.5) / 1000
	end

	return math.ceil(v * 1000 - 0.5) / 1000
end

local function sample(points, shot)
	local prev = points[1]

	if shot <= prev[1] then
		return prev[2], prev[3]
	end

	for i = 2, #points do
		local nextPoint = points[i]
		if shot <= nextPoint[1] then
			local span = nextPoint[1] - prev[1]
			local t = span > 0 and smooth((shot - prev[1]) / span) or 1
			return mix(prev[2], nextPoint[2], t), mix(prev[3], nextPoint[3], t)
		end

		prev = nextPoint
	end

	return prev[2], prev[3]
end

local function buildPattern(spec, scale)
	local pattern = {}
	local points = spec.points
	local wobble = spec.wobble
	local recoilScale = scale ~= 0 and scale or 1
	local startup = spec.startup or {}
	local pitchScale = spec.pitchScale or DEFAULT_PATTERN_PITCH_SCALE
	local yawScale = spec.yawScale or DEFAULT_PATTERN_YAW_SCALE

	for shot = 1, spec.length do
		local p, y = sample(points, shot)

		if wobble and shot >= (wobble.start or 3) then
			local t = shot / spec.length
			local fade = wobble.fade and smooth(t) or t
			local seed = wobble.seed or 0
			p = p + math.sin(shot * 1.71 + seed) * (wobble.p or 0) * fade
			y = y + math.sin(shot * 2.17 + seed) * (wobble.y or 0) * fade
		end

		-- Most CS/Rust-style sprays give the player one or two honest setup
		-- bullets before the real climb arrives.
		if shot == 1 then
			p = startup.firstP or 0
			y = startup.firstY or 0
		elseif shot == 2 then
			p = startup.secondP or (p * 0.18)
			y = startup.secondY or (y * 0.12)
		end

		p = p * pitchScale
		y = y * yawScale

		pattern[shot] = {round3(p / recoilScale), round3(y / recoilScale)}
	end

	return pattern
end

-- Positive yaw means bullets drift left in Source's view-angle convention.
-- Negative pitch means bullets climb upward.
local SPECS = {
	fas2_ak47 = {
		length = 38, scale = 4.7, reset = 0.42,
		points = {
			{1, 0.00, 0.00}, {2, -0.06, 0.00}, {3, -0.25, 0.00},
			{4, -0.55, -0.02}, {5, -0.95, -0.04}, {6, -1.40, -0.03},
			{7, -1.85, 0.00}, {8, -2.35, 0.15}, {9, -2.90, 0.45},
			{10, -3.40, 0.95}, {11, -3.85, 1.55}, {12, -4.20, 2.15},
			{13, -4.45, 2.75}, {14, -4.62, 3.05}, {15, -4.75, 2.75},
			{16, -4.83, 1.95}, {17, -4.87, 0.95}, {18, -4.90, -0.15},
			{19, -4.92, -1.25}, {20, -4.94, -2.20}, {21, -4.96, -2.85},
			{22, -4.98, -3.05}, {23, -4.99, -2.75}, {24, -5.00, -1.95},
			{25, -5.02, -0.80}, {26, -5.04, 0.45}, {27, -5.06, 1.55},
			{28, -5.08, 2.25}, {29, -5.10, 2.15}, {30, -5.12, 1.35},
			{31, -5.14, 0.25}, {32, -5.16, -0.85}, {33, -5.18, -1.45},
			{34, -5.20, -1.10}, {35, -5.22, -0.30}, {36, -5.24, 0.55},
			{37, -5.26, 1.00}, {38, -5.28, 0.60},
		},
		startup = {firstP = -0.10, firstY = 0.00, secondP = -0.23, secondY = 0.00},
		wobble = {start = 18, p = 0.035, y = 0.08, seed = 47, fade = true},
	},

	fas2_ak74 = {
		length = 38, scale = 3.8, reset = 0.39,
		points = {
			{1, 0.00, 0.00}, {2, -0.06, 0.00}, {5, -0.72, 0.02},
			{10, -3.35, 0.08}, {15, -4.15, 0.86}, {22, -4.48, -0.72},
			{30, -4.68, 0.20}, {38, -4.82, 0.02},
		},
		wobble = {start = 12, p = 0.06, y = 0.12, seed = 74, fade = true},
	},

	fas2_rk95 = {
		length = 38, scale = 4.2, reset = 0.40,
		points = {
			{1, 0.00, 0.00}, {2, -0.07, 0.00}, {5, -0.82, 0.02},
			{10, -3.80, 0.08}, {15, -4.65, 0.98}, {22, -4.95, -0.82},
			{30, -5.18, 0.20}, {38, -5.32, 0.02},
		},
		wobble = {start = 12, p = 0.07, y = 0.13, seed = 95, fade = true},
	},

	fas2_ak12 = {
		length = 38, scale = 3.6, reset = 0.37,
		points = {
			{1, 0.00, 0.00}, {2, -0.05, 0.00}, {6, -0.68, 0.00},
			{10, -3.05, 0.04}, {16, -3.70, 0.62}, {23, -3.98, -0.46},
			{30, -4.15, 0.12}, {38, -4.25, 0.00},
		},
		wobble = {start = 14, p = 0.05, y = 0.09, seed = 12, fade = true},
	},

	fas2_an94 = {
		length = 38, scale = 3.8, reset = 0.38,
		points = {
			{1, 0.00, 0.00}, {2, -0.04, 0.00}, {6, -0.58, 0.00},
			{10, -2.85, 0.04}, {16, -3.42, 0.55}, {23, -3.70, -0.38},
			{30, -3.86, 0.10}, {38, -3.95, 0.00},
		},
		wobble = {start = 14, p = 0.04, y = 0.08, seed = 94, fade = true},
	},

	fas2_m4a1 = {
		length = 38, scale = 3.5, reset = 0.36,
		points = {
			{1, 0.00, 0.00}, {2, -0.05, 0.00}, {5, -0.70, 0.01},
			{10, -3.35, 0.04}, {20, -4.35, 0.82}, {30, -4.72, -0.52},
			{38, -4.88, -0.10},
		},
		wobble = {start = 16, p = 0.05, y = 0.12, seed = 41, fade = true},
	},

	fas2_galil = {
		length = 45, scale = 4.0, reset = 0.40,
		points = {
			{1, 0.00, 0.00}, {2, -0.08, 0.02}, {5, -0.95, 0.15},
			{9, -3.45, 0.48}, {20, -5.10, 1.18}, {35, -5.55, 0.18},
			{45, -5.76, -0.02},
		},
		wobble = {start = 18, p = 0.08, y = 0.17, seed = 35, fade = true},
	},

	fas2_rpk = {
		length = 45, scale = 4.0, reset = 0.43,
		points = {
			{1, 0.00, 0.00}, {2, -0.07, 0.00}, {6, -0.90, 0.03},
			{12, -3.70, 0.18}, {22, -4.95, 0.98}, {34, -5.42, -0.34},
			{45, -5.70, 0.10},
		},
		wobble = {start = 16, p = 0.08, y = 0.16, seed = 45, fade = true},
	},

	fas2_g36c = {
		length = 38, scale = 2.8, reset = 0.34,
		points = {
			{1, 0.00, 0.00}, {2, -0.04, 0.00}, {6, -0.58, 0.00},
			{15, -2.88, 0.04}, {30, -3.60, 0.48}, {38, -3.68, 0.28},
		},
		wobble = {start = 18, p = 0.03, y = 0.06, seed = 36, fade = true},
	},

	fas2_sg552 = {
		length = 38, scale = 3.5, reset = 0.37,
		points = {
			{1, 0.00, 0.00}, {2, -0.05, 0.00}, {8, -1.15, 0.02},
			{15, -4.05, 0.08}, {30, -5.08, 1.08}, {38, -5.22, 0.78},
		},
		wobble = {start = 17, p = 0.05, y = 0.10, seed = 553, fade = true},
	},

	fas2_sg550 = {
		length = 38, scale = 4.2, reset = 0.40,
		points = {
			{1, 0.00, 0.00}, {2, -0.04, 0.00}, {8, -0.95, 0.00},
			{15, -3.45, 0.05}, {30, -4.15, 0.48}, {38, -4.24, 0.30},
		},
		wobble = {start = 18, p = 0.04, y = 0.07, seed = 550, fade = true},
	},

	fas2_famas = {
		length = 35, scale = 3.2, reset = 0.34,
		points = {
			{1, 0.00, 0.00}, {2, -0.05, 0.00}, {6, -0.72, -0.08},
			{15, -3.25, -0.46}, {25, -4.00, 0.62}, {35, -4.14, 0.12},
		},
		wobble = {start = 12, p = 0.05, y = 0.11, seed = 25, fade = true},
	},

	fas2_g3 = {
		length = 30, scale = 5.2, reset = 0.42,
		points = {
			{1, 0.00, 0.00}, {2, -0.10, 0.00}, {5, -1.10, 0.04},
			{10, -4.10, 0.20}, {20, -5.90, 0.92}, {30, -6.45, -0.22},
		},
		wobble = {start = 10, p = 0.09, y = 0.16, seed = 3, fade = true},
	},

	fas2_m14 = {
		length = 30, scale = 4.8, reset = 0.42,
		points = {
			{1, 0.00, 0.00}, {2, -0.08, 0.00}, {5, -0.95, 0.02},
			{10, -3.55, 0.12}, {20, -4.75, 0.72}, {30, -5.10, -0.10},
		},
		wobble = {start = 10, p = 0.08, y = 0.13, seed = 14, fade = true},
	},

	fas2_mp5sd6 = {
		length = 40, scale = 1.8, reset = 0.30,
		points = {
			{1, 0.00, 0.00}, {2, -0.03, 0.00}, {10, -0.82, 0.00},
			{20, -1.50, 0.04}, {30, -1.90, 0.02}, {40, -2.06, 0.00},
		},
		wobble = {start = 18, p = 0.02, y = 0.03, seed = 56, fade = true},
	},

	fas2_mp5a5 = {
		length = 40, scale = 2.2, reset = 0.31,
		points = {
			{1, 0.00, 0.00}, {2, -0.04, 0.00}, {10, -1.05, 0.08},
			{20, -1.90, 0.30}, {30, -2.28, 0.42}, {40, -2.40, 0.26},
		},
		wobble = {start = 16, p = 0.03, y = 0.06, seed = 55, fade = true},
	},

	fas2_mp5k = {
		length = 30, scale = 2.5, reset = 0.29,
		points = {
			{1, 0.00, 0.00}, {2, -0.04, 0.00}, {8, -1.00, 0.08},
			{18, -1.82, 0.42}, {30, -2.20, 0.18},
		},
		wobble = {start = 12, p = 0.04, y = 0.07, seed = 5, fade = true},
	},

	fas2_mac11 = {
		length = 38, scale = 3.0, reset = 0.28,
		points = {
			{1, 0.00, 0.00}, {2, -0.05, -0.02}, {6, -0.92, -0.24},
			{12, -2.45, -0.95}, {22, -3.55, -1.55}, {30, -3.92, -1.08},
			{38, -4.04, -0.62},
		},
		wobble = {start = 8, p = 0.06, y = 0.12, seed = 11, fade = true},
	},

	fas2_uzi = {
		length = 38, scale = 2.8, reset = 0.31,
		points = {
			{1, 0.00, 0.00}, {2, -0.04, 0.00}, {8, -1.00, -0.12},
			{18, -2.22, -0.58}, {30, -2.75, 0.46}, {38, -2.88, 0.10},
		},
		wobble = {start = 12, p = 0.05, y = 0.09, seed = 32, fade = true},
	},

	fas2_pp19 = {
		length = 75, scale = 2.25, reset = 0.34,
		points = {
			{1, 0.00, 0.00}, {2, -0.03, -0.01}, {3, -0.12, -0.08},
			{4, -0.28, -0.18}, {5, -0.50, -0.34}, {6, -0.75, -0.55},
			{7, -1.02, -0.78}, {8, -1.30, -1.02}, {9, -1.56, -1.22},
			{10, -1.80, -1.38}, {11, -2.00, -1.48}, {12, -2.15, -1.50},
			{13, -2.25, -1.42}, {14, -2.32, -1.26}, {15, -2.38, -1.02},
			{16, -2.43, -0.72}, {17, -2.47, -0.38}, {18, -2.50, -0.02},
			{19, -2.52, 0.34}, {20, -2.54, 0.70}, {21, -2.55, 1.02},
			{22, -2.56, 1.30}, {23, -2.57, 1.55}, {24, -2.58, 1.76},
			{25, -2.59, 1.92}, {26, -2.60, 2.02}, {27, -2.61, 2.08},
			{28, -2.62, 2.05}, {29, -2.62, 1.92}, {30, -2.63, 1.70},
			{31, -2.63, 1.40}, {32, -2.64, 1.06}, {33, -2.64, 0.72},
			{34, -2.65, 0.38}, {35, -2.65, 0.04}, {36, -2.66, -0.28},
			{37, -2.66, -0.58}, {38, -2.67, -0.84}, {39, -2.67, -1.04},
			{40, -2.68, -1.18}, {41, -2.68, -1.25}, {42, -2.69, -1.24},
			{43, -2.69, -1.14}, {44, -2.70, -0.96}, {45, -2.70, -0.70},
			{46, -2.71, -0.38}, {47, -2.71, -0.02}, {48, -2.72, 0.34},
			{49, -2.72, 0.68}, {50, -2.73, 0.96}, {51, -2.73, 1.16},
			{52, -2.74, 1.24}, {53, -2.74, 1.18}, {54, -2.75, 0.98},
			{55, -2.75, 0.68}, {56, -2.76, 0.32}, {57, -2.76, -0.04},
			{58, -2.77, -0.38}, {59, -2.77, -0.64}, {60, -2.78, -0.78},
			{61, -2.78, -0.76}, {62, -2.79, -0.58}, {63, -2.79, -0.28},
			{64, -2.80, 0.08}, {65, -2.80, 0.42}, {66, -2.81, 0.68},
			{67, -2.81, 0.82}, {68, -2.82, 0.78}, {69, -2.82, 0.58},
			{70, -2.83, 0.28}, {71, -2.83, -0.04}, {72, -2.84, -0.30},
			{73, -2.84, -0.44}, {74, -2.85, -0.38}, {75, -2.85, -0.12},
		},
		wobble = {start = 20, p = 0.018, y = 0.10, seed = 19, fade = true},
	},

	fas2_ots33 = {
		length = 30, scale = 2.8, reset = 0.28,
		points = {
			{1, 0.00, 0.00}, {2, -0.05, 0.00}, {8, -1.20, -0.18},
			{18, -2.35, -0.52}, {30, -2.80, 0.28},
		},
		wobble = {start = 8, p = 0.05, y = 0.10, seed = 33, fade = true},
	},

	fas2_glock20 = {
		length = 20, scale = 2.2, reset = 0.38,
		points = {
			{1, 0.00, 0.00}, {2, -0.08, 0.01}, {6, -1.10, 0.10},
			{12, -1.72, -0.18}, {20, -1.95, 0.08},
		},
		wobble = {start = 5, p = 0.04, y = 0.08, seed = 20, fade = true},
	},

	fas2_p226 = {
		length = 18, scale = 2.2, reset = 0.36,
		points = {
			{1, 0.00, 0.00}, {2, -0.06, 0.00}, {6, -0.88, 0.06},
			{12, -1.32, -0.12}, {18, -1.48, 0.04},
		},
		wobble = {start = 5, p = 0.03, y = 0.06, seed = 226, fade = true},
	},

	fas2_m1911 = {
		length = 16, scale = 3.5, reset = 0.42,
		points = {
			{1, 0.00, 0.00}, {2, -0.10, 0.02}, {5, -1.32, 0.18},
			{10, -2.10, -0.22}, {16, -2.34, 0.08},
		},
		wobble = {start = 4, p = 0.05, y = 0.08, seed = 1911, fade = true},
	},

	fas2_deagle = {
		length = 14, scale = 5.5, reset = 0.50,
		points = {
			{1, 0.00, 0.00}, {2, -0.18, 0.02}, {4, -1.80, 0.24},
			{8, -3.05, -0.35}, {14, -3.62, 0.16},
		},
		wobble = {start = 3, p = 0.08, y = 0.13, seed = 50, fade = true},
	},

	fas2_ragingbull = {
		length = 10, scale = 5.8, reset = 0.60,
		points = {
			{1, 0.00, 0.00}, {2, -0.22, 0.02}, {4, -2.05, 0.25},
			{7, -3.42, -0.32}, {10, -3.90, 0.10},
		},
		wobble = {start = 3, p = 0.08, y = 0.13, seed = 58, fade = true},
	},

	fas2_sks = {
		length = 20, scale = 4.2, reset = 0.42,
		points = {
			{1, 0.00, 0.00}, {2, -0.09, 0.00}, {5, -1.22, 0.10},
			{10, -2.35, 0.36}, {20, -3.10, -0.18},
		},
		wobble = {start = 5, p = 0.06, y = 0.10, seed = 62, fade = true},
	},

	fas2_m21 = {
		length = 20, scale = 4.5, reset = 0.45,
		points = {
			{1, 0.00, 0.00}, {2, -0.08, 0.00}, {5, -1.08, 0.08},
			{10, -2.15, 0.30}, {20, -2.90, -0.12},
		},
		wobble = {start = 5, p = 0.05, y = 0.08, seed = 21, fade = true},
	},

	fas2_sr25 = {
		length = 20, scale = 4.5, reset = 0.45,
		points = {
			{1, 0.00, 0.00}, {2, -0.08, 0.00}, {5, -1.05, 0.08},
			{10, -2.05, 0.24}, {20, -2.70, -0.10},
		},
		wobble = {start = 5, p = 0.05, y = 0.08, seed = 25, fade = true},
	},

	fas2_m82 = {
		length = 15, scale = 6.5, reset = 0.70,
		points = {
			{1, 0.00, 0.00}, {2, -0.18, 0.02}, {4, -2.05, 0.18},
			{8, -3.80, -0.26}, {15, -4.60, 0.12},
		},
		wobble = {start = 3, p = 0.08, y = 0.12, seed = 82, fade = true},
	},

	-- Future/extra class aliases if another FAS pack is mounted later.
	fas2_p90 = {
		length = 60, scale = 2.0, reset = 0.33,
		points = {
			{1, 0.00, 0.00}, {2, -0.03, 0.00}, {15, -1.35, 0.04},
			{30, -2.20, 0.54}, {50, -2.80, 1.22}, {60, -2.92, 1.04},
		},
		wobble = {start = 20, p = 0.04, y = 0.10, seed = 90, fade = true},
	},

	fas2_mp7 = {
		length = 38, scale = 2.1, reset = 0.30,
		points = {
			{1, 0.00, 0.00}, {2, -0.03, 0.00}, {10, -0.98, 0.00},
			{20, -1.85, -0.34}, {30, -2.20, -0.48}, {38, -2.30, -0.26},
		},
		wobble = {start = 14, p = 0.03, y = 0.06, seed = 7, fade = true},
	},

	fas2_mp9 = {
		length = 38, scale = 2.0, reset = 0.29,
		points = {
			{1, 0.00, 0.00}, {2, -0.03, 0.00}, {10, -0.82, 0.12},
			{20, -1.55, 0.36}, {30, -1.92, 0.48}, {38, -2.00, 0.34},
		},
		wobble = {start = 14, p = 0.03, y = 0.06, seed = 9, fade = true},
	},

	fas2_ump45 = {
		length = 35, scale = 2.6, reset = 0.34,
		points = {
			{1, 0.00, 0.00}, {2, -0.05, 0.00}, {9, -1.25, -0.30},
			{18, -2.22, -0.58}, {27, -2.65, 0.44}, {35, -2.76, 0.08},
		},
		wobble = {start = 10, p = 0.05, y = 0.09, seed = 45, fade = true},
	},
}

SPECS.fas2_mac10 = SPECS.fas2_mac11

-- Real-ish simplified ballistics. Source units are treated as inches elsewhere
-- in this pack, so muzzle speeds are inches/second and gravity is Earth gravity
-- in inches/second^2. This is still a no-drag model, but it is much closer to
-- real trajectory than the earlier flattened game-feel table.
local MUZZLE_VELOCITY = {
	fas2_ak47 = 28150, fas2_ak74 = 34600, fas2_rk95 = 28150,
	fas2_rpk = 28150, fas2_sks = 28150, fas2_galil = 36000,
	fas2_ak12 = 34600, fas2_an94 = 34600,
	fas2_m4a1 = 35400, fas2_g36c = 33000, fas2_famas = 37000,
	fas2_sg552 = 33400, fas2_sg550 = 37000,
	fas2_g3 = 32000, fas2_m14 = 32000, fas2_m21 = 32000,
	fas2_sr25 = 32600, fas2_m24 = 31500, fas2_m82 = 34500,
	fas2_svd = 32600, fas2_aw50 = 34500,
	fas2_mp5a5 = 15750, fas2_mp5k = 15000, fas2_mp5sd6 = 11250,
	fas2_pp19 = 12400, fas2_uzi = 15750, fas2_mac11 = 11800, fas2_mac10 = 11800,
	fas2_ots33 = 12400, fas2_glock20 = 15750, fas2_p226 = 16500,
	fas2_m1911 = 10000, fas2_deagle = 18000, fas2_ragingbull = 20500,
	fas2_m3s90 = 16000, fas2_rem870 = 16000, fas2_remington870 = 16000,
	fas2_ks23 = 14800, fas2_toz34 = 16000,
}

local BALLISTICS = {
	fas2_ak47 = {gravity = 386, zero = 3937},
	fas2_ak74 = {gravity = 386, zero = 3937},
	fas2_rk95 = {gravity = 386, zero = 3937},
	fas2_rpk = {gravity = 386, zero = 3937},
	fas2_sks = {gravity = 386, zero = 3937},
	fas2_galil = {gravity = 386, zero = 3937},
	fas2_ak12 = {gravity = 386, zero = 3937},
	fas2_an94 = {gravity = 386, zero = 3937},
	fas2_m4a1 = {gravity = 386, zero = 3937},
	fas2_g36c = {gravity = 386, zero = 3937},
	fas2_famas = {gravity = 386, zero = 3937},
	fas2_sg552 = {gravity = 386, zero = 3937},
	fas2_sg550 = {gravity = 386, zero = 3937},
	fas2_g3 = {gravity = 386, zero = 3937},
	fas2_m14 = {gravity = 386, zero = 3937},
	fas2_m21 = {gravity = 386, zero = 3937},
	fas2_sr25 = {gravity = 386, zero = 3937},
	fas2_m24 = {gravity = 386, zero = 3937},
	fas2_m82 = {gravity = 386, zero = 3937},
	fas2_svd = {gravity = 386, zero = 3937},
	fas2_aw50 = {gravity = 386, zero = 3937},
	fas2_mp5a5 = {gravity = 386, zero = 1969},
	fas2_mp5k = {gravity = 386, zero = 1969},
	fas2_mp5sd6 = {gravity = 386, zero = 1969},
	fas2_pp19 = {gravity = 386, zero = 1969},
	fas2_uzi = {gravity = 386, zero = 1969},
	fas2_mac11 = {gravity = 386, zero = 1969},
	fas2_mac10 = {gravity = 386, zero = 1969},
	fas2_ots33 = {gravity = 386, zero = 984},
	fas2_glock20 = {gravity = 386, zero = 984},
	fas2_p226 = {gravity = 386, zero = 984},
	fas2_m1911 = {gravity = 386, zero = 984},
	fas2_deagle = {gravity = 386, zero = 984},
	fas2_ragingbull = {gravity = 386, zero = 984},
	fas2_m3s90 = {gravity = 386, zero = 1378},
	fas2_rem870 = {gravity = 386, zero = 1378},
	fas2_remington870 = {gravity = 386, zero = 1378},
	fas2_ks23 = {gravity = 386, zero = 1378},
	fas2_toz34 = {gravity = 386, zero = 1378},
}

local function refreshWeaponInstances()
	if not player or not player.GetAll then return end

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply.GetWeapons then
			for _, weapon in ipairs(ply:GetWeapons()) do
				if IsValid(weapon) then
					local cls = weapon.Class or weapon:GetClass()
					if SPECS[cls] or MUZZLE_VELOCITY[cls] or BALLISTICS[cls] then
						if SPECS[cls] and FAS2_SprayPatterns[cls] then
							weapon.SprayPattern = FAS2_SprayPatterns[cls]
							weapon.RecoilScale = FAS2_RecoilScale[cls] or weapon.RecoilScale
							weapon.SprayResetTime = FAS2_SprayResetTime[cls] or weapon.SprayResetTime
						end
						weapon.MuzzleVelocity = FAS2_MuzzleVelocity[cls] or weapon.MuzzleVelocity
						if FAS2_Ballistics[cls] then
							weapon.BallisticGravity = FAS2_Ballistics[cls].gravity or weapon.BallisticGravity
							weapon.BallisticZeroDistance = FAS2_Ballistics[cls].zero or weapon.BallisticZeroDistance
						end
						weapon._sprayDataLoaded = nil
					end
				end
			end
		end
	end
end

local function install(announce, onlyClass)
	for cls, velocity in pairs(MUZZLE_VELOCITY) do
		if not onlyClass or cls == onlyClass then
			FAS2_MuzzleVelocity[cls] = velocity
		end
	end

	for cls, tuning in pairs(BALLISTICS) do
		if not onlyClass or cls == onlyClass then
			FAS2_Ballistics[cls] = tuning
		end
	end

	for cls, spec in pairs(SPECS) do
		if onlyClass and cls ~= onlyClass then
			continue
		end

		local scale = FAS2_RecoilScale[cls] or spec.scale or 1
		FAS2_RecoilScale[cls] = scale
		FAS2_SprayResetTime[cls] = spec.reset or FAS2_SprayResetTime[cls] or 0.35
		FAS2_SprayPatterns[cls] = buildPattern(spec, scale)
		if MUZZLE_VELOCITY[cls] then
			FAS2_MuzzleVelocity[cls] = MUZZLE_VELOCITY[cls]
		end
		if BALLISTICS[cls] then
			FAS2_Ballistics[cls] = BALLISTICS[cls]
		end
	end

	if weapons and weapons.GetStored then
		for cls in pairs(MUZZLE_VELOCITY) do
			if not onlyClass or cls == onlyClass then
				local stored = weapons.GetStored(cls)
				if stored then
					if SPECS[cls] and FAS2_SprayPatterns[cls] then
						stored.SprayPattern = FAS2_SprayPatterns[cls]
						stored.RecoilScale = FAS2_RecoilScale[cls] or stored.RecoilScale
						stored.SprayResetTime = FAS2_SprayResetTime[cls] or stored.SprayResetTime
					end
					stored.MuzzleVelocity = FAS2_MuzzleVelocity[cls] or stored.MuzzleVelocity
					if FAS2_Ballistics[cls] then
						stored.BallisticGravity = FAS2_Ballistics[cls].gravity or stored.BallisticGravity
						stored.BallisticZeroDistance = FAS2_Ballistics[cls].zero or stored.BallisticZeroDistance
					end
				end
			end
		end
	end

	-- Old editor JSON had the MAC pitch inverted. This reset writes native
	-- FAS pitch directly, so keep the editor from flipping it back later.
	FAS2_PatternInvertPitch["fas2_mac11"] = false
	FAS2_PatternInvertPitch["fas2_mac10"] = false

	FAS2_CS2SprayResetVersion = RESET_VERSION
	refreshWeaponInstances()

	if announce and SERVER then
		print("[FAS2] Installed CS2/Rust spray reset " .. RESET_VERSION)
	end
end

FAS2_InstallCS2SprayReset = install

install(false)

local function queueLateInstall()
	timer.Simple(0.25, function() install(true) end)
	timer.Simple(2, function() install(false) end)
	timer.Simple(8, function() install(false) end)
end

queueLateInstall()

hook.Add("Initialize", "FAS2_CS2SprayReset_Initialize", function()
	install(false)
	queueLateInstall()
end)

hook.Add("InitPostEntity", "FAS2_CS2SprayReset_InitPostEntity", function()
	install(true)
	queueLateInstall()
end)

hook.Add("OnReloaded", "FAS2_CS2SprayReset_OnReloaded", function()
	install(true)
end)

if SERVER then
	concommand.Add("fas2_reset_spray_patterns", function(ply)
		if IsValid(ply) and not ply:IsAdmin() then return end
		install(true)
	end)
end
