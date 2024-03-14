package util

import "core:math"
import "core:math/linalg"

point_inside_n:: proc"contextless"($N: int, point: [N]f32, position: [N]f32, size: [N]f32) -> bool #no_bounds_check
{
    for i in 0..<N {
        if point[i] < position[i] || point[i] > position[i] + size[i] {
            return false
        }
    }
    return true
}

limit:: proc"contextless"(v: [2]f32, l: f32) -> [2]f32
{
    if linalg.vector_length2(v) > (l*l) {
        return linalg.vector_normalize(v) * l
    }
    return v
}

intwrap:: proc"contextless"(x, y: i32) -> i32
{
	tmp := x%y
	return y + tmp if tmp < 0 else tmp
}

accel:: proc"contextless"(a, b, s: f32) -> f32
{
    if a == b {
        return a
    }

    if a < b {
        if a + s > b {
            return b
        } else {
            return a + s
        }
    }

    if  a - s < b {
        return b
    } else {
        return a - s
    }
}

accel2d:: proc"contextless"(a, b, s: [2]f32) -> [2]f32
{
    return {
        accel(a.x, b.x, s.x),
        accel(a.y, b.y, s.y),
    }
}

range:: proc"contextless"(val, lo, hi, loOut, hiOut: f32) -> f32
{
    t: = (val - lo)/(hi - lo)
    if t >= 1 { return hiOut }
    if t <= 0 { return loOut }
    return hiOut*t + loOut*(1-t)
}

smallest:: proc"contextless"(vecs: [][2]f32) -> (small: [2]f32) #no_bounds_check
{
    mag: = max(f32)
    for vec in vecs {
        if linalg.length2(vec) < mag {
            mag = linalg.length2(vec)
            small = vec
        }
    }
    return small
}

largest:: proc"contextless"(vecs: [][2]f32) -> (large: [2]f32) #no_bounds_check
{
    mag: f32
    for vec in vecs {
        if linalg.length2(vec) > mag {
            mag = linalg.length2(vec)
            large = vec
        }
    }
    return large
}
