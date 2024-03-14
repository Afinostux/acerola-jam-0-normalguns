package main

import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

import "sprite"
import "ganim"

footAnim: = [][2]f32{
    {-8, 0},
    {6, -8},
    {8, 0},
    {0, 0},
}

walkBodyAnim: = [][2]f32{
    {0, -3},
    {0, 0},
    {0, -3},
    {0, 0},
}

draw_player_head:: proc(
    player: ^Player,
    offset: [2]f32,
    angle:  f32,
    flip:   bool,
    tint:   rl.Color,
) {
    ngs: = &sprite.normalgunsSrc
    sprite.draw_part(&ngs.head, offset, angle, flip, tint)
    if !player.noGlasses {
        sprite.draw_part(&ngs.glasses, offset, angle, flip, tint)
    } else
    if .Telekinesis in player.mutations {
        sprite.draw_part(&ngs.eyesLaser, offset, angle, flip, tint)
    } else {
        sprite.draw_part(&ngs.eyes, offset, angle, flip, tint)
    }
    if !player.noMask {
        sprite.draw_part(&ngs.mask, offset, angle, flip, tint)
    } else
    if .Hunger in player.mutations {
        sprite.draw_part(&ngs.mouthHunger, offset, angle, flip, tint)
    } else {
        sprite.draw_part(&ngs.mouth, offset, angle, flip, tint)
    }
    sprite.draw_part(&ngs.hairLow, offset, angle, flip, tint)
    if !player.noHelmet {
        sprite.draw_part(&ngs.helmet,  offset, angle, flip, tint)
    } else
    if !player.noHair {
        sprite.draw_part(&ngs.hairHigh, offset, angle, flip, tint)
    }
    if .Goat in player.mutations {
        sprite.draw_part(&ngs.horns, offset, angle, flip, tint)
    }
}

draw_player_weapon:: proc(
    player: ^Player,
    offset: [2]f32,
    angle:  f32,
    flip:   bool,
    tint:   rl.Color,
    shift:  i32 = 0,
) {
    ngs: = &sprite.normalgunsSrc
    claws: = .Claws in player.mutations
    switch player.weapon {
        case .Rifle:
        if claws {
            sprite.draw_part(&ngs.rifleClaw, offset, angle, flip, tint, shift)
        } else {
            sprite.draw_part(&ngs.rifle, offset, angle, flip, tint, shift)
        }
        case .Shotgun:
        if claws {
            sprite.draw_part(&ngs.shotgunClaw, offset, angle, flip, tint, shift)
        } else {
            sprite.draw_part(&ngs.shotgun, offset, angle, flip, tint, shift)
        }
        case .Grenade:
        if claws {
            sprite.draw_part(&ngs.grenadeClaw, offset, angle, flip, tint, shift)
        } else {
            sprite.draw_part(&ngs.grenade, offset, angle, flip, tint, shift)
        }
        case .Rocket:
        if claws {
            sprite.draw_part(&ngs.rocketClaw, offset, angle, flip, tint, shift)
        } else {
            sprite.draw_part(&ngs.rocket, offset, angle, flip, tint, shift)
        }
    }
}

draw_player_body:: proc(
    player: ^Player,
    offset: [2]f32,
    angle:  f32,
    flip:   bool,
    tint:   rl.Color,
    shift:  i32 = 0,
) {
    ngs: = &sprite.normalgunsSrc
    if .Wings in player.mutations {
        sprite.draw_part(&ngs.wing, offset, angle, flip, tint, shift)
    }
    sprite.draw_part(&ngs.body, offset, angle, flip, tint, shift)
    if .Spikes in player.mutations {
        sprite.draw_part(&ngs.spikes, offset, angle, flip, tint, shift)
    }
}

draw_player_body_aim:: proc(
    player: ^Player,
    offset: [2]f32,
    tint: rl.Color,
)
{
    flip: = player.aim.x < 0
    aimAngle: = math.to_degrees(-math.acos(player.aim.y)) + 90
    jolt: = player.jolt * {(flip)?-1:1, 1}
    draw_player_body(player, (jolt + offset) * 0.5, aimAngle* 0.2, flip, tint)
    draw_player_head(player, {player.aim.y * 28, abs(player.aim.y) * 8} + jolt + offset, aimAngle, flip, 255)
    draw_player_weapon(player, 0, aimAngle, flip, tint)
}

