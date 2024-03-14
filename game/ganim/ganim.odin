package ganim

import "core:math"

Ganim:: struct {
    t:       f32,
    timeOn:  f32,
    timeOff: f32,
    on:      bool,
}

Gloop:: struct {
    t:        f32,
    duration: f32,
    loops:    i32,
}

start_timer:: proc(ganim: ^Ganim, time: f32)
{
    ganim.t = 0
    ganim.timeOn = time
    ganim.on = true
}

start_cooldown:: proc(ganim: ^Ganim, time: f32)
{
    ganim.t = 1
    ganim.timeOff = time
    ganim.on = false
}

on:: proc(ganim: ^Ganim) -> bool
{ return ganim.on && ganim.t == 1 }

off:: proc(ganim: ^Ganim) -> bool
{ return !ganim.on && ganim.t == 0 }

sequence:: proc(
    gloop: ^Gloop,
    low: f32,
    high: f32,
) -> bool
{
    if gloop.loops == 0 { return false }
    hw: = math.wrap(high, 1)
    lw: = math.wrap(low, 1)
    if hw > lw {
        return gloop.t < hw && gloop.t > lw
    }
    return !(gloop.t >= hw && gloop.t <= lw)
}

// why is this differenc
threshold_gloop:: proc(
    gloop:   ^Gloop,
    low:     f32,
    high:    f32,
    lowval:  f32,
    highval: f32,
) -> f32
{
    if high == low {
        if gloop.t > high {
            return highval
        } else {
            return lowval
        }
    } else

    if high >= low {
        mix: = clamp((gloop.t - low)/(high - low), 0, 1)
        return math.lerp(lowval, highval, mix)
    }

    mix: = clamp((gloop.t - high)/(low - high), 0, 1)
    return math.lerp(highval, lowval, mix)
}

threshold_ganim:: proc(
    ganim:   ^Ganim,
    low:     f32,
    high:    f32,
    lowval:  f32,
    highval: f32,
) -> f32
{
    if high == low {
        if ganim.t > high {
            return highval
        } else {
            return lowval
        }
    } else

    if high >= low {
        mix: = clamp((ganim.t - low)/(high - low), 0, 1)
        return math.lerp(lowval, highval, mix)
    }

    mix: = clamp((ganim.t - high)/(low - high), 0, 1)
    return math.lerp(highval, lowval, mix)
}

threshold:: proc{threshold_ganim, threshold_gloop}

tick_gloop:: proc(gloop: ^Gloop, dt: f32)
{
    if gloop.loops != 0 {
        gloop.t += dt/gloop.duration
        for gloop.t > 1.0 || gloop.t < 0.0 {
            gloop.t -= math.sign(dt)
            if gloop.loops > 0 { 
                gloop.loops -= 1 
                if gloop.loops == 0 {
                    gloop.t = 0
                }
            }
        }
    }
}

tick_ganim:: proc(ganim: ^Ganim, dt: f32)
{
    if ganim.on {
        if ganim.timeOn > 0 {
            ganim.t = min(ganim.t + dt/ganim.timeOn, 1)
        } else {
            ganim.t = 1
        }
    } else {
        if ganim.timeOff > 0 {
            ganim.t = max(ganim.t - dt/ganim.timeOff, 0)
        } else {
            ganim.t = 0
        }
    }
}

tick:: proc{tick_ganim, tick_gloop}

sample_ganim:: proc(
    ganim: ^Ganim,
    seq: [][2]f32,
    offset: f32 = 0,
) -> [2]f32 #no_bounds_check
{
    i, f: = math.modf(math.clamp(ganim.t + offset, 0, 1) * f32(len(seq)-1))
    id: = i32(i)
    id2: = id + 1
    return math.lerp(seq[id], seq[id2], f)
}

sample_gloop:: proc(
    gloop: ^Gloop,
    seq: [][2]f32,
    offset: f32 = 0,
) -> [2]f32 #no_bounds_check
{
    i, f: = math.modf(math.mod(gloop.t + offset, 1) * f32(len(seq)))
    id: = i32(i)
    id2: = (id + 1) % i32(len(seq))
    return math.lerp(seq[id], seq[id2], f)
}

sample:: proc{sample_ganim, sample_gloop}
