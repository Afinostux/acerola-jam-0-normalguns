package main

import "clip"

import rl "vendor:raylib"

HitObject:: union{
    ^Player,
    ^Boxerbot,
    ^Shieldbot,
    ^Hoverbot,
    ^Sawbot,
}

Hitbox:: struct {
    position: [2]f32,
    size:     [2]f32,
    id:       i32,
    source:   HitObject,
}

hitbox:: proc(
    hitboxes: ^[dynamic]Hitbox,
    center:   [2]f32,
    size:     [2]f32,
    source:   HitObject,
    id:       i32 = 0,
) {
    append(hitboxes, Hitbox{
        position = center - size*0.5,
        size     = size,
        source   = source,
    })
}

debug_draw_hitboxes:: proc(hitboxes: ^[dynamic]Hitbox)
{
    for hb in hitboxes {
        hbc: rl.Color
        switch s in hb.source {
            case ^Player:
            hbc = {0, 255, 255, 128}
            case ^Boxerbot:
            hbc = {0, 0, 255, 128}
            case ^Shieldbot:
            hbc = {128, 128, 0, 128}
            case ^Hoverbot:
            hbc = {255, 0, 255, 128}
            case ^Sawbot:
            hbc = {255, 128, 128, 128}
            case nil:
            hbc = {0, 0, 0, 255}
        }
        rl.DrawRectangleV(hb.position, hb.size, hbc)
    }
}

procbox:: proc(
    hitboxes: ^[dynamic]Hitbox,
    center: [2]f32,
    size: [2]f32,
    hitproc: proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool,
) -> bool {
    hitPos: = center - size * 0.5
    hit: bool
    for hitbox in hitboxes {
        clipped, overlap: = clip.aabb_aabb(hitbox.position, hitbox.size, hitPos, size)
        if clipped {
            hit |= hitproc(overlap, hitbox.id, hitbox.source)
        }
    }
    return hit
}
