package clip

import "core:math"
import "core:math/linalg"

minor:: proc"contextless"(
    vec: [2]f32,
) -> [2]f32 #no_bounds_check
{
    avec: = linalg.abs(vec)
    if avec.x > avec.y {
        return {0, vec.y}
    }
    return {vec.x, 0}
}

major:: proc"contextless"(
    vec: [2]f32,
) -> [2]f32 #no_bounds_check
{
    avec: = linalg.abs(vec)
    if avec.x > avec.y {
        return {0, vec.y}
    }
    return {vec.x, 0}
}

area:: proc"contextless"(
    vec: [2]f32,
) -> f32 #no_bounds_check
{ return math.abs(vec.x * vec.y) }

aabb_aabb:: proc"contextless"(
    positionA: [2]f32,
    sizeA: [2]f32,
    positionB: [2]f32,
    sizeB: [2]f32,
) -> (clipped: bool, overlap: [2]f32) #no_bounds_check
{
    return aabb_point(
        positionA,
        positionB - sizeA,
        sizeB + sizeA,
    )
}

aabb_point:: proc"contextless"(
    point:        [2]f32,
    aabbPosition: [2]f32,
    aabbSize:     [2]f32,
) -> (clipped: bool, overlap: [2]f32) #no_bounds_check
{
    for i in 0..<2 {
        if point[i] < aabbPosition[i] || point[i] > aabbPosition[i] + aabbSize[i] {
            return false, {}
        }
        ovl: = aabbPosition[i] - point[i]
        ovr: = aabbPosition[i] + aabbSize[i] - point[i]
        if ovr + ovl > 0 {
            overlap[i] = ovl
        } else {
            overlap[i] = ovr
        }
    }

    return true, overlap
}

//aabb_trace:: proc"contextless"(
//    position:     [2]f32,
//    distance:     [2]f32,
//    aabbPosition: [2]f32,
//    aabbSize:     [2]f32,
//) -> (clipped: bool, normal: [2]f32) #no_bounds_check
//{
//    return clipped, normal
//}

aabb_manhattan_distance:: proc"contextless"(
    position:     [2]f32,
    aabbPosition: [2]f32,
    aabbSize:     [2]f32,
) -> (manhattan: f32) #no_bounds_check
{
    for i in 0..<2 {
        if position[i] < aabbPosition[i] {
            manhattan += aabbPosition[i] - position[i]
        } else
        if position[i] > aabbPosition[i] + aabbSize[i]{
            manhattan += position[i] - aabbPosition[i] - aabbSize[i]
        }
    }
    return manhattan
}

aabb_point_difference:: proc"contextless"(
    position: [2]f32,
    aabbPosition: [2]f32,
    aabbSize: [2]f32,
) -> (inside: bool, difference: [2]f32)
{
    inside = true
    for i in 0..<2 {
        if position[i] < aabbPosition[i] {
            inside = false
            difference[i] = aabbPosition[i] - position[i]
        } else
        if position[i] > aabbPosition[i] + aabbSize[i] {
            inside = false
            difference[i] = aabbPosition[i] + aabbSize[i] - position[i]
        }
    }
    return inside, difference
}

