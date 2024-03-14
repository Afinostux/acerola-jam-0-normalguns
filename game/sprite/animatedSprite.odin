package sprite

import "core:math"

import rl "vendor:raylib"

import "../ganim"

Sprite:: struct {
    texture:    rl.Texture,
    srcPos:     [2]f32,
    srcSize:    [2]f32,
    origin:     [2]f32,
    scale:      [2]f32,
    frameCount: f32,
}

create_sprite:: proc(
    texture: rl.Texture,
    origin: [2]f32,
    scale: [2]f32,
    frameCount: f32 = 1,
) -> (sprite: Sprite)
{
    sprite = Sprite{
        texture    = texture,
        srcPos     = 0,
        srcSize    = {f32(texture.width)/frameCount, f32(texture.height)},
        origin     = origin,
        scale      = scale,
        frameCount = frameCount,
    }
    return sprite
}

create_sprite_sub_centered:: proc(
    texture: rl.Texture,
    scale: [2]f32,
    pos: [2]f32,
    size: [2]f32,
) -> (sprite: Sprite)
{
    origin: = size * 0.5
    return Sprite{
        texture = texture,
        srcPos = pos,
        srcSize = size,
        origin = origin,
        scale = scale,
        frameCount = 1,
    }
}

create_sprite_centered:: proc(
    texture: rl.Texture,
    scale: [2]f32,
    frameCount: f32 = 1,
) -> (sprite: Sprite)
{
    origin: = [2]f32{f32(texture.width)/frameCount, f32(texture.height)}*0.5
    return create_sprite(texture, origin, scale, frameCount)
}

tick_t:: proc(
    t:          f32,
    dt:         f32,
    frameCount: f32,
    loop:       bool = false,
) -> (nt: f32, done: bool)
{
    nt = t + dt
    if loop {
        if dt > 0 {
            for nt >= frameCount {
                nt -= frameCount
                done = true
            }
        } else 
        if dt < 0 {
            for nt < 0 {
                nt += frameCount
                done = true
            }
        }
    } else {
        if dt > 0 {
            nt = min(nt, frameCount)
            done = nt == frameCount
        } else
        if dt < 0 {
            nt = max(nt, 0)
            done = nt == 0
        }
    }
    return nt, done
}

draw_sprite_ganim:: proc(
    sprite: ^Sprite,
    ganim: ^ganim.Ganim,
    position: [2]f32,
    angle: f32,
    tint: rl.Color,
    flip:     bool = false,
    origin:   [2]f32 = 0,
    scale:    [2]f32 = 1,
) {
    draw_sprite(sprite, position, angle, tint, ganim.t * sprite.frameCount, flip, origin, scale)
}

draw_sprite_gloop:: proc(
    sprite: ^Sprite,
    gloop: ^ganim.Gloop,
    position: [2]f32,
    angle: f32,
    tint: rl.Color,
    flip:     bool = false,
    origin:   [2]f32 = 0,
    scale:    [2]f32 = 1,
) {
    draw_sprite(sprite, position, angle, tint, gloop.t * sprite.frameCount, flip, origin, scale)
}

draw_sprite:: proc(
    sprite:   ^Sprite,
    position: [2]f32,
    angle:    f32,
    tint:     rl.Color,
    t:        f32 = 0,
    flip:     bool = false,
    origin:   [2]f32 = 0,
    scale:    [2]f32 = 1,
) {
    t: = math.floor(math.clamp(t, 0, sprite.frameCount - 1))
    i: = i32(t)
    scale: = sprite.scale * scale
    origin: = (sprite.origin + origin)*scale

    srcPos: = sprite.srcPos + { t * sprite.srcSize.x, 0 }
    srcSize: = sprite.srcSize
    if flip { srcSize.x *= -1 }
    src: = rl.Rectangle{
        srcPos.x, srcPos.y,
        srcSize.x, srcSize.y,
    }

    dstPos: = position
    dstSize: = srcSize * scale
    dst: = rl.Rectangle{
        dstPos.x, dstPos.y,
        dstSize.x, dstSize.y,
    }

    rl.DrawTexturePro(sprite.texture, src, dst, origin, angle, tint)
}
