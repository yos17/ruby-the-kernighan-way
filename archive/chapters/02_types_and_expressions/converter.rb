# converter.rb — convert between units
# Usage: ruby converter.rb 100 km miles

CONVERSIONS = {
  ["km",    "miles"]  => ->(v) { v * 0.621371 },
  ["miles", "km"]     => ->(v) { v * 1.60934  },
  ["kg",    "lbs"]    => ->(v) { v * 2.20462  },
  ["lbs",   "kg"]     => ->(v) { v * 0.453592 },
  ["c",     "f"]      => ->(v) { v * 9.0/5 + 32 },
  ["f",     "c"]      => ->(v) { (v - 32) * 5.0/9 },
  ["m",     "ft"]     => ->(v) { v * 3.28084  },
  ["ft",    "m"]      => ->(v) { v * 0.3048   },
}

if ARGV.length != 3
  puts "Usage: converter.rb value from_unit to_unit"
  puts "Example: converter.rb 100 km miles"
  puts "Units: km/miles, kg/lbs, c/f, m/ft"
  exit 1
end

value   = ARGV[0].to_f
from    = ARGV[1].downcase
to      = ARGV[2].downcase
convert = CONVERSIONS[[from, to]]

if convert
  result = convert.call(value)
  puts "#{value} #{from} = #{result.round(4)} #{to}"
else
  puts "Unknown conversion: #{from} → #{to}"
  puts "Available: #{CONVERSIONS.keys.map { |k| k.join('→') }.join(', ')}"
  exit 1
end