package main

import "core:math"
import "core:math/rand"
import "core:math/linalg"

import "level"
import "util"
import "sprite"
import "sound"

ProjectileType:: enum{
    None,
    PlayerRifle,
    PlayerShotgun,
    PlayerGrenade,
    PlayerRocket,
    RobotBomb,
    RobotScatter,
}

Projectile:: struct{
    type:         ProjectileType,
    wallStart:    bool,
    position:     [2]f32,
    size:         [2]f32,
    velocity:     [2]f32,
    acceleration: [2]f32,
    anim:         f32,
}

projectiles: [dynamic]Projectile

spawn_projectile:: proc(
    type: ProjectileType,
    position: [2]f32,
    velocity: [2]f32,
) {
    if type == .None { return }
    size: [2]f32
    acceleration: [2]f32
    anim: f32
    switch type {
        case .None:
        case .PlayerRifle:
        size = 8
        anim = rand.float32_range(0, sprite.rifleBullet.frameCount)
        case .PlayerShotgun:
        size = 8
        anim = rand.float32_range(0, sprite.shotgunBullet.frameCount)
        case .PlayerGrenade:
        size = 16
        acceleration = {0, 1200}
        case .PlayerRocket:
        size = 16
        acceleration = 3200*linalg.normalize(velocity)
        anim = rand.float32_range(0, sprite.rocketBullet.frameCount)
        case .RobotBomb:
        size = 16
        acceleration = {0, 1200}
        case .RobotScatter:
        size = 16
    }
    proj: = Projectile {
        type         = type,
        wallStart    = level.overlaps(gameState.cLevel.obstacles[:], position - size * 0.5, size),
        position     = position,
        size         = size,
        velocity     = velocity,
        acceleration = acceleration,
        anim         = anim,
    }
    for &p in projectiles {
        if p.type == .None {
            p = proj
            return
        }
    }
    append(&projectiles, proj)
}

tick_projectiles:: proc(dt: f32)
{
    hit:: proc(p: ^Projectile) {
        switch p.type {
            case .None:
            case .PlayerRifle:
            explode_fx_small(p.position)
            case .PlayerShotgun:
            explode_fx_small(p.position)
            case .PlayerGrenade:
            explode_fx_large(p.position)
            procbox(&gameState.enemyHitboxes, p.position, 200, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 8)
                return true
            })
            sound.play(&sound.explosionBig)

            case .PlayerRocket:
            explode_fx_medium(p.position)
            procbox(&gameState.enemyHitboxes, p.position, 120, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 100)
                return true
            })
            sound.play(&sound.explosionMid)

            case .RobotBomb:
            explode_fx_large(p.position)
            procbox(&gameState.playerHitboxes, p.position, 100, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 2)
                return true
            })
            sound.play(&sound.explosionBig)

            case .RobotScatter:
            explode_fx_small(p.position)
        }
        p.type = .None
    }

    for &p in projectiles {
        if p.type == .None { continue }
        if level.overlaps(gameState.cLevel.obstacles[:], p.position - p.size * 0.5, p.size) {
            if !p.wallStart {
                hit(&p)
                continue
            }
        } else {
            p.wallStart = false
        }
        p.velocity = util.limit(p.velocity + p.acceleration * dt, 3200)
        p.position += p.velocity * dt
        switch p.type {
            case .None:
            case .PlayerRifle:
            if procbox(&gameState.enemyHitboxes, p.position, p.size, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 3)
                return true
            }) {
                hit(&p)
            }

            case .PlayerShotgun:
            if procbox(&gameState.enemyHitboxes, p.position, p.size, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 2)
                return true
            }) {
                hit(&p)
            }

            case .PlayerGrenade:
            if procbox(&gameState.enemyHitboxes, p.position, p.size, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 5)
                return true
            }) {
                hit(&p)
            }

            case .PlayerRocket:
            if procbox(&gameState.enemyHitboxes, p.position, p.size, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 100)
                return true
            }) {
                hit(&p)
            }

            case .RobotBomb:
            if procbox(&gameState.playerHitboxes, p.position, p.size, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 5)
                return true
            }) {
                hit(&p)
            }

            case .RobotScatter:
            if procbox(&gameState.playerHitboxes, p.position, p.size, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 2)
                return true
            }) {
                hit(&p)
            }
        }
    }
}

draw_projectiles:: proc(dt: f32)
{
    for &p in projectiles {
        switch p.type {
            case .None:
            case .PlayerRifle:
            p.anim, _ = sprite.tick_t(p.anim, dt*60, sprite.rifleBullet.frameCount, true)
            sprite.draw_sprite(
                &sprite.rifleBullet,
                p.position,
                math.to_degrees_f32(math.atan2(p.velocity.y, p.velocity.x)),
                255,
                p.anim,
            )
            case .PlayerShotgun:
            p.anim, _ = sprite.tick_t(p.anim, dt*30, sprite.shotgunBullet.frameCount, true)
            sprite.draw_sprite(
                &sprite.shotgunBullet,
                p.position,
                0,
                255,
                p.anim,
            )
            case .PlayerGrenade:
            sprite.draw_sprite(
                &sprite.grenadeBullet,
                p.position,
                0,
                255,
            )
            case .PlayerRocket:
            p.anim, _ = sprite.tick_t(p.anim, dt * (linalg.length(p.velocity)/16.0), sprite.rifleBullet.frameCount, true)
            sprite.draw_sprite(
                &sprite.rocketBullet,
                p.position,
                math.to_degrees_f32(math.atan2(p.velocity.y, p.velocity.x)),
                255,
                p.anim,
            )
            case .RobotBomb:
            p.anim, _ = sprite.tick_t(p.anim, dt*30, sprite.robotScatter.frameCount, true)
            sprite.draw_sprite(
                &sprite.robotScatter,
                p.position,
                0,
                255,
                p.anim,
            )
            case .RobotScatter:
            p.anim, _ = sprite.tick_t(p.anim, dt*30, sprite.robotScatter.frameCount, true)
            sprite.draw_sprite(
                &sprite.robotScatter,
                p.position,
                0,
                255,
                p.anim,
            )
        }
    }
}

