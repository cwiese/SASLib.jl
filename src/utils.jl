"""
Strip from the right end of the `bytes` array for any byte that matches the ones
specified in the `remove` argument.  See Python's bytes.rstrip function.
"""
function brstrip(bytes::Vector{UInt8}, remove::Vector{UInt8})
    for i in length(bytes):-1:1
        x = bytes[i]
        found = false
        for m in remove
            if x == m
                found = true
                break 
            end
        end
        if !found
            return bytes[1:i]
        end
    end
    return Vector{UInt8}()
end
#brstrip(b"\x01\x02\x03", b"\x03")

"""
Find needle in the haystack with both `Vector{UInt8}` type arguments.
"""
function Base.contains(haystack::Vector{UInt8}, needle::Vector{UInt8})
    hlen = length(haystack)
    nlen = length(needle)
    if hlen >= nlen
        for i in 1:hlen-nlen+1
            if haystack[i:i+nlen-1] == needle
                return true
            end
        end
    end
    return false
end
# contains(b"123", b"123")
# contains(b"123456", b"123")
# contains(b"123456", b"234")
# contains(b"123456", b"456")
# contains(b"123456", b"567")
# contains(b"123456", b"xxx")

# """
# Print a subtype tree from the specified `roottype`
# """
# function subtypetree(roottype, level=1, indent=4)
#     level == 1 && println(roottype)
#     for s in subtypes(roottype)
#       println(join(fill(" ", level * indent)) * string(s))
#       subtypetree(s, level+1, indent)
#     end
# end

# Fast implementation to `reinterpret` int/floats
# See https://discourse.julialang.org/t/newbie-question-convert-two-8-byte-values-into-a-single-16-byte-value/7662/5

# count_a = 0
# count_b = 0

# # summary stats
# function stat(kind) 
#     if kind == :convertfloat
#         return (count_a, count_b)
#     end
#     return nothing
# end

# function clearstat(kind)
#     if kind == :convertfloat
#         count_a, count_b = 0, 0
#     end
# end

# Version a.  Original implementation... slow.
"""
Byte swap is needed only if file the array represent a different endianness
than the system.  This function does not make any assumption and the caller
is expected to pass `true` to the `swap` argument when needed.
"""
function convertfloat64a(bytes::Vector{UInt8}, swap::Bool)
    # global count_a
    # count_a::Int64 += 1
    values = [bytes[i:i+8-1] for i in 1:8:length(bytes)]
    values = map(x -> reinterpret(Float64, x)[1], values)
    swap ? bswap.(values) : values
end

# Version b.  Should be a lot faster.  
"""
It turns out that `reinterpret` consider a single UInt64 as BigEndian 
Hence it's necessary to swap bytes if the array is in LittleEndian convention.
This function does not make any assumption and the caller
is expected to pass `true` to the `swap` argument when needed.
"""
function convertfloat64b(bytes::Vector{UInt8}, endianess::Symbol) 
    # global count_b
    # count_b::Int64 += 1
    v = endianess == :LittleEndian ? reverse(bytes) : bytes
    c = convertint64.(v[1:8:end],v[2:8:end],v[3:8:end],v[4:8:end],
            v[5:8:end], v[6:8:end], v[7:8:end], v[8:8:end])
    r = reinterpret.(Float64, c)
    endianess == :LittleEndian ? reverse(r) : r
end

"""
Take 8 bytes and convert them into a UInt64 type.  The order is preserved.
"""
function convertint64(a::UInt8,b::UInt8,c::UInt8,d::UInt8,e::UInt8,f::UInt8,g::UInt8,h::UInt8)
    (UInt64(a) << 56) | (UInt64(b) << 48) | 
    (UInt64(c) << 40) | (UInt64(d) << 32) | 
    (UInt64(e) << 24) | (UInt64(f) << 16) | 
    (UInt64(g) << 8)  |  UInt64(h)
end

# function signedint(a::UInt8) 
#     Int8(a)
# end

# function signedint(a::UInt8, b::UInt8; endianness=:BigEndian) 
#     x = (Int16(a) << 8) | Int16(b)
#     endianness == :BigEndian ? x : bswap(x)
# end

# function signedint(a::UInt8, b::UInt8, c::UInt8, d::UInt8; endianness=:BigEndian) 
#     x = (Int32(a) << 24) | (Int32(b) << 16) | (Int32(c) << 8) | Int32(d)
#     endianness == :BigEndian ? x : bswap(x)
# end

# function signedint(a::UInt8, b::UInt8, c::UInt8, d::UInt8,
#         e::UInt8, f::UInt8, g::UInt8, h::UInt8; endianness=:BigEndian) 
#     x = (Int64(a) << 56) | (Int64(b) << 48) | (Int64(c) << 40) | (Int64(d) << 32) | 
#         (Int64(e) << 24) | (Int64(f) << 16) | (Int64(g) << 8) | Int64(h)
#     endianness == :BigEndian ? x : bswap(x)
# end

# signedint(0x12) == reinterpret(Int8, 0x12)
# signedint(0x12, 0x34; endianness=:LittleEndian) == reinterpret(Int16, [0x12, 0x34])[1]
# signedint(0x12, 0x34, 0x22, 0x33; endianness=:LittleEndian) == 
#     reinterpret(Int32, [0x12, 0x34, 0x22, 0x33])[1]
# signedint(0x12, 0x34, 0x22, 0x33, 0x55, 0x66, 0x77, 0x88; endianness=:LittleEndian) == 
#     reinterpret(Int64, [0x12, 0x34, 0x22, 0x33, 0x55, 0x66, 0x77, 0x88])[1]

# function signedfloat(a::UInt8, b::UInt8, c::UInt8, d::UInt8,
#     e::UInt8, f::UInt8, g::UInt8, h::UInt8; endianness=:BigEndian) 
#     x = (UInt64(a) << 56) | (UInt64(b) << 48) | (UInt64(c) << 40) | (UInt64(d) << 32) | 
#         (UInt64(e) << 24) | (UInt64(f) << 16) | (UInt64(g) << 8) | UInt64(h)
#     # println(typeof(x))
#     # println(x)
#     y = endianness == :BigEndian ? x : bswap(x)
#     # println(y)
#     z = reinterpret(Float64, y)
#     # println(z)
#     z
# end
# signedfloat(0x12, 0x34, 0x22, 0x33, 0x55, 0x66, 0x77, 0x88; endianness=:LittleEndian) ==
#     reinterpret(Float64, [0x12, 0x34, 0x22, 0x33, 0x55, 0x66, 0x77, 0x88])[1]

# function convertfloat(bytes)
#     #println("bytes=$bytes")
#     # convert to 8-byte values (UInt64)
#     values = [bytes[i:i+8-1] for i in 1:8:length(bytes)]
#     #println("values=$values")
#     # convert to Float64
#     convertedvalues = map(x -> reinterpret(Float64, x), values)
#     #println("convertedvalues=$convertedvalues")
#     convertedvalues
# end
# x = reinterpret(UInt8, rand(4));
# convertfloat(x)
# y = reinterpret(UInt8, rand(1000));
# @btime convertfloat(y);

# function convertfloat2(bytes)
#     len = length(bytes)
#     v = zeros(Float64, div(len, 8::Int64))
#     j = 1
#     for i in 1:8:len
#         v[j] = signedfloat(bytes[i], bytes[i+1], bytes[i+2], bytes[i+3], 
#             bytes[i+4], bytes[i+5], bytes[i+6], bytes[i+7]; endianness = :LittleEndian)
#         j += 1
#     end
#     v
# end
# convertfloat2(x)
# @btime convertfloat2(y);

# function convertfloat3(bytes)
#     values = [bytes[i:i+8-1] for i in 1:8:length(bytes)]
#     convertedvalues = map(x -> signedfloat(
#         x[1], x[2], x[3], x[4], x[5], x[6], x[7], x[8]), #, endianness=:LittleEndian),
#         values)
#     convertedvalues
# end
# convertfloat3(x)
# @btime convertfloat3(y);