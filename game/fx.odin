package main

import "core:math"
import "core:math/rand"

import "sprite"

Explosion:: struct {
    sprite: ^sprite.Sprite,
    position: [2]f32,
    t: f32,
    seed: f32,
    size: f32,
    count: f32,
    delay: f32,
}

explosions: [dynamic]Explosion

draw_fx:: proc(dt: f32)
{
    if dt > 0 {
        for &exp in explosions {
            if exp.sprite == nil { continue }
            t: = exp.t + dt * 15
            if t > sprite.explosion.frameCount * (1 + (exp.count-1) * exp.delay) {
                exp.sprite = nil
            } else {
                exp.t = t
            }
        }
    }

    for exp in explosions {
        if exp.sprite == nil { continue }
        t: = exp.t
        for i in 1..<exp.count {
            tl: = t - exp.sprite.frameCount * i * exp.delay
            if tl > 0 && tl < exp.sprite.frameCount {
                angle: = exp.seed + (math.TAU/exp.count)*i
                ofs: = [2]f32{
                    math.cos(angle),
                    math.sin(angle),
                } * (i * (exp.size/exp.count))
                sprite.draw_sprite(exp.sprite, exp.position + ofs, 0, 255, tl)
                sprite.draw_sprite(exp.sprite, exp.position - ofs, 0, 255, tl)
            }
        }
        if t < sprite.explosion.frameCount {
            sprite.draw_sprite(exp.sprite, exp.position, 0, 255, t)
        }
    }
}

explode_fx_small:: proc(
    position: [2]f32,
) {
    explosion_fx(&sprite.explosion, position, 0, 1)
}

explode_fx_medium:: proc(
    position: [2]f32,
) {
    explosion_fx(&sprite.explosion, position, 64, 5, 0.25)
}

explode_fx_large:: proc(
    position: [2]f32,
) {
    explosion_fx(&sprite.explosion, position, 96, 7, 0.125)
}

explosion_fx:: proc(
    sprite: ^sprite.Sprite,
    position: [2]f32,
    size: f32,
    count: f32,
    delay: f32 = 0.25,
) {
    exp: = Explosion {
        sprite = sprite,
        position = position,
        t = 0,
        seed = rand.float32_range(0, math.TAU),
        size = size,
        count = count,
        delay = delay,
    }
    for &e in explosions {
        if e.sprite == nil {
            e = exp
            return
        }
    }
    append(&explosions, exp)
}
