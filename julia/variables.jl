x = 1

x = 2

println("x = ", x)

a = [1,2,3]
b = a
a = 1

println("a = ", a)
println("b = ", b)

x, _ = 1, 2

println(x)

for _ in [1, 2, 3]
    println(x)
end

# Below code doesn't work.
# It works in python though.
# for _ in [1, 2, 3]
#     println(_)
# end

# The default type for an integer literal depends on whether the target system has a 32-bit
# architecture or a 64-bit architecture:
x = 1000
println(typeof(x))

# 10^12
x = 1000 * 1000 * 1000 * 1000
println(typeof(x))

# Hexademical handling is weird.
# 0xff is an unsigned integer -- in base 10 -- equal to 16^2 - 1 = 255
x = 0xff
println(x)
println(typeof(x))
println(x * 10)

x = 1.234
println(cos(x))

println(1/0)
println(1 + NaN)
println(1 + Inf)

# ∞ isn't a stand-in for Inf and Julia doens't recognize it.
# println(1 + ∞)
