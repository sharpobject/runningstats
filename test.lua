require("math")
running_stats = require("running_stats")

values = {1,1,2,5,9,17}
-- from WolframAlpha
reference = {
  size = 6,
  mean = 5.833333333333333333333333333333,
  variance = 32.805555555555555555555555555,
  stddev = 5.72761342581319427819923711,
  skewness = 1.0124706278431176923348002,
  kurtosis = 2.6260735710275810694448726}


function assert_eq(a, b, function_name, attr)
  assert(math.abs(a-b) < 1e-9, function_name.." generated incorrect value for "..
    attr .. ", wanted " .. b .. " but got ".. a)
end

function assert_correct(stats, function_name)
  for k,v in pairs(reference) do
    assert_eq(stats[k](stats), v, function_name, k)
  end
end

function test_add()
  local stats = running_stats(values[1], 1.0)
  for i=2,#values do
    stats = stats + running_stats(values[i])
  end
  assert_correct(stats, "__add")
end

function test_add2()
  local stats = running_stats(values[1], 1.0)
  for i=2,#values do
    stats = stats + values[i]
  end
  assert_correct(stats, "__add2")
end

function test_add_value()
  local stats = running_stats(values[1])
  for i=2,#values do
    stats:add_value(values[i])
  end
  assert_correct(stats, "add_value")
end

function test_sub_value()
  local stats = running_stats()
  stats.n = 1000000
  for i=1,#values do
    stats:add_value(values[i])
  end
  local negate_fake_zeros = running_stats()
  negate_fake_zeros.n = -1000000
  stats = stats + negate_fake_zeros
  print("wow lol")
  assert_correct(stats, "sub_value")
end

function test_weighted_add_value()
  local value_to_weight = {}
  local stats = running_stats()
  local scale = 1.7
  for _,v in ipairs(values) do
    value_to_weight[v] = (value_to_weight[v] or 0) + 1
  end
  for k,v in pairs(value_to_weight) do
    stats:add_value(k, v * scale)
  end
  reference.size = reference.size * scale
  assert_correct(stats, "weighted add_value")
  reference.size = reference.size / scale
end

function test_zero()
  local stats = running_stats()
  stats:add_value(0,0)
  assert(stats.n == 0)
  assert(stats.m == 0)
  assert(stats.M2 == 0)
  assert(stats.M3 == 0)
  assert(stats.M4 == 0)
  stats = stats + stats
  assert(stats.n == 0)
  assert(stats.m == 0)
  assert(stats.M2 == 0)
  assert(stats.M3 == 0)
  assert(stats.M4 == 0)
end

test_add()
test_add_value()
test_weighted_add_value()
test_add2()
test_zero()
test_sub_value()
