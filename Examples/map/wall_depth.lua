local gd = require("gd")

local function sqrt(x)
  return x^0.5
end

local function abs(x)
  return x >= 0 and x or -x
end

local function chord(r, h)
  local chord_values = {}
  for i = 1, #h do
    rel_h = abs(h[i] - r)
    if rel_h > r then
      rel_h = r
    end
    chord_values[i] = 2 * sqrt(r^2 - rel_h^2)
  end

  return chord_values
end

local function wall_thickness(ext_r, int_r, h)
  local ext_chord = chord(ext_r, h)
  local int_h = {}
  for i = 1, #h do
    int_h[i] = h[i] - ext_r + int_r
  end
  local int_chord = chord(int_r, int_h)

  local thickness = {}
  for i = 1, #h do
    thickness[i] = ext_chord[i] / 2 - int_chord[i] / 2
    print(h[i], thickness[i])
  end

  return thickness
end

local function scale_to_range(value, min_val, max_val, new_min, new_max)
    return (value - min_val) * (new_max - new_min) / (max_val - min_val) + new_min
  end

local function generate_image(ext_r, int_r, h, w, multiplier)
  local heights = {}
  for i = 1, h do
    heights[i] = i
  end

  local w_thick = wall_thickness(ext_r, int_r, heights)

  local min_val = w_thick[1]
  local max_val = w_thick[1]
  for i = 2, #w_thick do
    min_val = math.min(min_val, w_thick[i])
    max_val = math.max(max_val, w_thick[i])
  end

  local img = gd.createTrueColor(w, h)

  for i = 1, h do
    local gray = math.floor(scale_to_range(math.min(w_thick[i], max_val / multiplier), min_val, max_val / multiplier, 0, 255))
    local color = img:colorAllocate(gray, gray, gray)
    for j = 1, w+1 do
      img:setPixel(j-1, i-1, color)
    end
  end

  return img
end

-- Example usage
local ext_r = tonumber(arg[1])
local int_r = tonumber(arg[2])
local h = tonumber(arg[3])
local w = tonumber(arg[4])
local path = tostring(arg[5])
local multiplier = tonumber(arg[6])

local ext_r_pixels = (h+1) / 2
local int_r_pixels = (h+1) / 2 / ext_r * int_r

local img = generate_image(ext_r_pixels, int_r_pixels, h, w, multiplier)
img:png(path)
