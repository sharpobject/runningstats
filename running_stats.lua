require("math")

local type, sqrt = type, math.sqrt

local function class(init)
  local c,mt = {},{}
  c.__index = c
  mt.__call = function(class_tbl, ...)
    local obj = {}
    setmetatable(obj,c)
    init(obj,...)
    return obj
  end
  setmetatable(c, mt)
  return c
end

local running_stats = class(function(self, value, weight)
    if value == nil then
      value = 0
      weight = 0
    elseif weight == nil then
      weight = 1
    end
    self.n = weight
    self.m = value
    self.M2 = 0
    self.M3 = 0
    self.M4 = 0
    self._stats_ready = false
  end)

function running_stats:mean() return self.m end

function running_stats:size() return self.n end

function running_stats:prep_stats()
  self._variance = self.M2 / self.n
  self._stddev = sqrt(self._variance)
  self._skewness = self.M3 / (self._variance * self._stddev * self.n)
  self._kurtosis = self.M4 / (self._variance * self._variance * self.n)
  self._stats_ready = true
end

-- This is the population variance, not the sample variance.
function running_stats:variance()
  if not self._stats_ready then
    self:prep_stats()
  end
  return self._variance
end

-- This is the population stddev, not the sample stddev.
function running_stats:stddev()
  if not self._stats_ready then
    self:prep_stats()
  end
  return self._stddev
end

function running_stats:skewness()
  if not self._stats_ready then
    self:prep_stats()
  end
  return self._skewness
end

function running_stats:kurtosis()
  if not self._stats_ready then
    self:prep_stats()
  end
  return self._kurtosis
end

function running_stats:add_value(value, weight)
  weight = weight or 1
  local dmean = value - self.m
  local dmean2 = dmean * dmean
  local new_n = self.n + weight
  local new_n2 = new_n * new_n
  local new_m, new_M2, new_M3, new_M4
  local dmeanovern = dmean / new_n
  local dmean2overn2 = dmean2 / new_n2
  if  weight ~= 1 then
    -- In this branch we know that other.Mk are 0
    local selfnweight = self.n * weight
    local weight2 = weight * weight
    local selfnweightdmean2overn = selfnweight * dmean2 / new_n
    new_m = self.m + weight * dmeanovern
    new_M2 = self.M2 + selfnweightdmean2overn

    new_M3 = self.M3 +
              selfnweightdmean2overn * (self.n - weight) * dmeanovern -
              3 * (weight * self.M2) * dmeanovern

    new_M4 = self.M4 +
              selfnweightdmean2overn * (self.n * self.n - selfnweight +
                weight2) * dmean2overn2 +
              6 * (weight2 * self.M2) * dmean2overn2 -
              4 * (weight * self.M3) * dmeanovern
  else
    -- in this branch we also know that weight is 1
    local selfn2 = self.n * self.n
    local selfndmean2overn = self.n * dmean2 / new_n
    new_m = self.m + dmeanovern
    new_M2 = self.M2 + selfndmean2overn

    new_M3 = self.M3 +
              (selfn2 - self.n) * dmean * dmean2overn2 -
              3 * self.M2 * dmeanovern

    new_M4 = self.M4 +
              selfndmean2overn * (selfn2 - self.n + 1) * dmean2overn2 +
              6 * self.M2 * dmean2overn2 -
              4 * self.M3 * dmeanovern
  end
  self.n = new_n
  self.m = new_m
  self.M2 = new_M2
  self.M3 = new_M3
  self.M4 = new_M4
  self._stats_ready = false
  return self
end

function running_stats:__add(other)
  if type(other) == "number" then
    other = running_stats(other)
  end
  local res = running_stats()
  local dmean = other.m - self.m
  local total_n = self.n + other.n
  local dmean2 = dmean * dmean
  local selfnothern = self.n * other.n
  local total_n2 = total_n * total_n
  local selfn2 = self.n * self.n
  local othern2 = other.n * other.n
  local selfnotherndmean2overn = selfnothern * dmean2 / total_n
  local dmeanovern = dmean / total_n
  local dmean2overn2 = dmean2 / total_n2

  res.n = total_n
  res.m = self.m + other.n * dmeanovern
  res.M2 = self.M2 + other.M2 + selfnotherndmean2overn

  res.M3 = self.M3 + other.M3 +
            selfnotherndmean2overn * (self.n - other.n) * dmeanovern +
            3 * (self.n * other.M2 - other.n * self.M2) * dmeanovern

  res.M4 = self.M4 + other.M4 +
            selfnotherndmean2overn * (selfn2 - selfnothern + othern2) *
              dmean2overn2 +
            6 * (selfn2 * other.M2 + othern2 * self.M2) * dmean2overn2 +
            4 * (self.n * other.M3 - other.n * self.M3) * dmeanovern

  return res
end

return running_stats
