package main

import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

import "ganim"
import "level"
import "sprite"
import "util"
import "sound"

count_enemies:: proc() -> (box, hover, saw, shield, total: i32)
{
    for b in boxerbots {
        if b.alive { box += 1 }
    }

    for b in hoverbots {
        if b.alive { hover += 1 }
    }

    for b in sawbots {
        if b.alive { saw += 1 }
    }
    
    for b in shieldbots {
        if b.alive { shield += 1 }
    }
    return box, hover, saw, shield, box + hover + saw + shield
}

spawn_wave:: proc()
{
    box, hover, saw, shield, total: = count_enemies()
    boxChance: = max(total - box - 4, 1)
    hoverChance: = max(total - hover + 2, 1)
    sawChance: = max(total - saw - 2, 1)
    shieldChance: = max(total - shield - 2, 1)
    totalChance: = boxChance + hoverChance + sawChance + shieldChance
    waveSpawn: = math.clamp((2*gameState.wave + 1 + rand.int31()%3) - total, 4, 30)
    gameState.killreq = (waveSpawn + total)/2
    for i in 0..<waveSpawn {
        r: = rand.int31()%totalChance
        spawnPos: = [2]f32{
            rand.float32_range(-1280, 1280),
            rand.float32_range(-1760, -1280),
        }
        flip: = (rand.int31()%2 == 0)

        if r < boxChance {
            level.create_enemy(.Boxer, spawnPos, flip)
            continue
        }
        r -= boxChance

        if r < hoverChance {
            if rand.int31()%4 == 0 {
                level.create_enemy(.Hoverbomb, spawnPos, flip)
            } else {
                level.create_enemy(.Hover, spawnPos, flip)
            }
            continue
        }
        r -= hoverChance

        if r < sawChance {
            level.create_enemy(.Saw, spawnPos, flip)
            continue
        }

        level.create_enemy(.Shield, spawnPos, flip)
    }
    gameState.wave += 1
}

on_enemy_die:: proc(position: [2]f32)
{
    gameState.killreq -= 1
    gameState.score += gameState.wave
    if gameState.killreq == 0 {
        spawn_wave()
    }
}

BOXER_NAV_SIZE:: 48
BoxerbotState:: enum {
    Patrol,
    Swoop,
    Return,
}
Boxerbot:: struct {
    alive:    bool,
    life:     int,
    position: [2]f32,
    velocity: [2]f32,
    punch:    ganim.Ganim,
    state:    BoxerbotState,
}
boxerbots: [dynamic]Boxerbot

HOV_NAV_SIZE:: 32
HoverbotState:: enum {
    Bomb,
    Wander,
}
Hoverbot:: struct {
    alive:     bool,
    life:      int,
    position:  [2]f32,
    velocity:  [2]f32,
    targetVel: [2]f32,
    angle:     f32,
    state:     HoverbotState,
}
hoverbots: [dynamic]Hoverbot

SAW_NAV_SIZE:: 48
SawbotState:: enum {
    Spawn,
    Roaming,
}
Sawbot:: struct {
    alive:        bool,
    life:         int,
    position:     [2]f32,
    speed:        f32,
    direction:    i32,
    directionInc: i32,
    spin:         f32,
    state:        SawbotState,
    spawnTimer:   ganim.Ganim,
    flicker:      bool,
}
sawbots: [dynamic]Sawbot

ShieldbotState:: enum {
    Spawn,
    Drive,
    Park,
}
Shieldbot:: struct {
    alive:       bool,
    life:        int,
    position:    [2]f32,
    velocity:    [2]f32,
    flipped:     bool,
    state:       ShieldbotState,
    timer:       ganim.Ganim,
    turretAngle: f32,
    targetSpeed: f32,
    roll:        f32,
    spawnTimer:   ganim.Ganim,
    flicker:      bool,
}
shieldbots: [dynamic]Shieldbot

reset_enemies:: proc()
{
    clear(&level.createEnemies)
    clear(&boxerbots)
    clear(&hoverbots)
    clear(&sawbots)
    clear(&shieldbots)
}

damage_hitobj_proc:: proc(overlap: [2]f32, id: i32, ob: HitObject, damage: int)
{
    switch o in ob{
        case ^Boxerbot:
        o.life -= damage
        if o.life <= 0 {
            o.alive = false
            explode_fx_medium(o.position)
            sound.play(&sound.explosionMid)
            on_enemy_die(o.position)
            spawn_random_powerup(o.position, 2)
        } else {
            sound.play(&sound.robotHit)
        }
        case ^Shieldbot:
        o.life -= damage
        if o.life <= 0 {
            o.alive = false
            explode_fx_large(o.position)
            sound.play(&sound.explosionMid)
            on_enemy_die(o.position)
            spawn_random_powerup(o.position, 2)
        } else {
            sound.play(&sound.robotHit)
        }
        case ^Hoverbot:
        o.life -= damage
        if o.life <= 0 {
            o.alive = false
            explode_fx_small(o.position)
            sound.play(&sound.explosionSmall)
            on_enemy_die(o.position)
            spawn_random_powerup(o.position, 1)
        } else {
            sound.play(&sound.robotHit)
        }
        case ^Sawbot:
        o.life -= damage
        if o.life <= 0 {
            o.alive = false
            explode_fx_small(o.position)
            sound.play(&sound.explosionSmall)
            on_enemy_die(o.position)
            spawn_random_powerup(o.position, 3)
        } else {
            sound.play(&sound.robotHit)
        }
        case ^Player:
        hit_player(o, overlap, damage)
    }
}

tick_enemies:: proc(dt: f32)
{
    clear(&gameState.enemyHitboxes)
    ecloop: for ce in level.createEnemies {
        switch ce.type {
            case .Boxer:
            newBoxer: = Boxerbot{
                alive    = true,
                life     = 10,
                position = ce.position + { 48, -32 },
                velocity = {0.1, 0},
                punch    = ganim.Ganim{
                    timeOff = 1,
                },
            }
            for &b in boxerbots {
                if !b.alive {
                    b = newBoxer
                    continue ecloop
                }
            }
            append(&boxerbots, newBoxer)
            case .Hover:
            newHover: = Hoverbot{
                alive    = true,
                life     = 6,
                position = ce.position + { 64, -32 },
                velocity = [2]f32 {
                    rand.float32_range(-100, 100),
                    rand.float32_range(-100, 100),
                },
                state    = .Wander,
            }
            for &h in hoverbots {
                if !h.alive {
                    h = newHover
                    continue ecloop
                }
            }
            append(&hoverbots, newHover)
            case .Hoverbomb:
            newHover: = Hoverbot{
                alive    = true,
                life     = 6,
                position = ce.position + { 64, -32 },
                velocity = [2]f32 {
                    rand.float32_range(-100, 100),
                    rand.float32_range(-100, 100),
                },
                state    = .Bomb,
            }
            for &h in hoverbots {
                if !h.alive {
                    h = newHover
                    continue ecloop
                }
            }
            append(&hoverbots, newHover)
            case .Saw:
            newsaw: = Sawbot{
                alive        = true,
                life         = 10,
                position     = ce.position + { 36, -36 },
                direction    = (ce.flip) ? 2 : 0,
                directionInc = (ce.flip) ? -1 : 1,
                spawnTimer   = ganim.Ganim{
                    timeOn = 3,
                },
            }
            for &s in sawbots {
                if !s.alive {
                    s = newsaw
                    continue ecloop
                }
            }
            append(&sawbots, newsaw)

            case .Shield:
            newShield: = Shieldbot{
                alive    = true,
                life     = 14,
                position = ce.position + { 64, -64 },
                flipped  = ce.flip,
                roll     = rand.float32_range(0, 360),
                timer    = ganim.Ganim{
                    timeOff = 2.2,
                },
                spawnTimer   = ganim.Ganim{
                    timeOn = 3,
                },
            }
            for &s in shieldbots {
                if !s.alive {
                    s = newShield
                    continue ecloop
                }
            }
            append(&shieldbots, newShield)
        }
    }
    clear(&level.createEnemies)

    for &boxer in boxerbots {
        if !boxer.alive { continue }
        BOXER_HORZ_SPEED:: 300
        BOXER_HORZ_ACCEL:: 300
        BOXER_VERT_SPEED:: 200
        BOXER_VERT_ACCEL:: 200
        navpos: = boxer.position - BOXER_NAV_SIZE * 0.5
        delta: = gameState.player.position - boxer.position
        switch boxer.state {
            case .Patrol:
            delta.y -= 300
            boxer.velocity.x = util.accel(
                boxer.velocity.x,
                math.sign(boxer.velocity.x) * BOXER_HORZ_SPEED,
                dt * BOXER_HORZ_ACCEL,
            )
            boxer.velocity.y = util.accel(
                boxer.velocity.y,
                math.sign(delta.y) * BOXER_VERT_SPEED,
                dt * BOXER_VERT_ACCEL,
            )
            if math.sign(boxer.velocity.x) == math.sign(delta.x) && linalg.length(delta) < 300 {
                boxer.state = .Swoop
            }
            case .Swoop:
            boxer.velocity.y = util.accel(boxer.velocity.y, delta.y, BOXER_HORZ_ACCEL*dt)
            boxer.velocity.x = util.accel(boxer.velocity.x, delta.x, BOXER_VERT_ACCEL*dt)
            if delta.y < 0 {
                boxer.state = .Return
            }
            case .Return:
            boxer.velocity.y = util.accel(boxer.velocity.y, -300, 200*dt)
            if delta.y > 200 {
                boxer.state = .Patrol
            }
        }
        navpos += boxer.velocity * dt
        clipped, move: = level.deviolate_obstacles(gameState.cLevel.obstacles[:], navpos, BOXER_NAV_SIZE)
        if clipped {
            boxer.position += move
            if boxer.state == .Return && move.y > 0 {
                boxer.state = .Patrol
            }
            if boxer.state == .Swoop && move.y < 0 {
                boxer.state = .Return
            }
            for i in 0..<2 {
                if move[i] != 0 && math.sign(move[i]) != math.sign(boxer.velocity[i]) {
                    boxer.velocity[i] *= -0.5
                }
            }
        }
        ganim.tick(&boxer.punch, dt)
        boxer.position += boxer.velocity * dt + move
        hitbox(&gameState.enemyHitboxes, boxer.position, {48, 32}, &boxer)
        if procbox(&gameState.playerHitboxes, boxer.position + {96*math.sign(boxer.velocity.x),0}, 32, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
            damage_hitobj_proc(overlap, id, ob, 2)
            return true
        }) && .Spikes in gameState.player.mutations {
            damage_hitobj_proc(0, 0, &boxer, 100)
        }
        if ganim.off(&boxer.punch) {
            if procbox(&gameState.playerHitboxes, boxer.position + {96*math.sign(boxer.velocity.x),0}, 32, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 4)
                return true
            }) {
                gameState.player.velocity.x += 800 * math.sign(boxer.velocity.x)
                gameState.player.velocity.y -= 400
                explode_fx_small(gameState.player.position)
                sound.play(&sound.explosionBig)
                boxer.punch.t = 1
            }
        }
    }

    for &hover in hoverbots {
        navpos: = hover.position - HOV_NAV_SIZE*0.5
        HOV_HORZ_SPEED:: 400
        HOV_VERT_SPEED:: 200
        HOV_HORZ_ACCEL:: 200
        HOV_VERT_ACCEL:: 200
        if !hover.alive { continue }
        launch: bool
        switch hover.state {
            case .Bomb:
            target: = gameState.player.position + {0, -200}
            delta: = target - hover.position
            if math.abs(delta.y) > 200 {
                hover.velocity.x = util.accel(
                    hover.velocity.x,
                    -math.sign(delta.x) * HOV_HORZ_SPEED,
                    dt * HOV_HORZ_ACCEL,
                )
            } else {
                hover.velocity.x = util.accel(
                    hover.velocity.x,
                    math.sign(delta.x) * HOV_HORZ_SPEED,
                    dt * HOV_HORZ_ACCEL,
                )
            }
            hover.velocity.y = util.accel(
                hover.velocity.y,
                math.sign(delta.y) * HOV_VERT_SPEED,
                dt * HOV_VERT_ACCEL,
            )

            if linalg.length(delta) < 200 {
                launch = true
                hover.state = .Wander
                hover.targetVel.x = HOV_HORZ_SPEED * math.sign(hover.velocity.x)
                hover.targetVel.y = HOV_VERT_SPEED * math.sign(hover.velocity.y)
            }

            case .Wander:
            target: = gameState.player.position
            delta: = target - hover.position
            if math.abs(delta.x) > 640 {
                hover.targetVel.x = HOV_HORZ_SPEED * math.sign(delta.x)
            }
            if math.abs(delta.y) > 360 {
                hover.targetVel.y = HOV_VERT_SPEED * math.sign(delta.y)
            }
            hover.velocity.x = util.accel(
                hover.velocity.x,
                hover.targetVel.x,
                dt * HOV_HORZ_ACCEL,
            )
            hover.velocity.y = util.accel(
                hover.velocity.y,
                hover.targetVel.y,
                dt * HOV_VERT_ACCEL,
            )
        }
        hover.position += hover.velocity * dt
        hover.angle = hover.velocity.x / 100
        clipped, move: = level.deviolate_obstacles(gameState.cLevel.obstacles[:], navpos, HOV_NAV_SIZE)
        if clipped {
            hover.position += move
            for i in 0..<2 {
                if move[i] != 0 && math.sign(move[i]) != math.sign(hover.velocity[i]) {
                    hover.velocity[i] *= -0.5
                    hover.targetVel[i] *= -1
                }
            }
        }

        rotm: = linalg.matrix2_rotate_f32(math.to_radians(hover.angle))
        fan1: = hover.position + rotm*sprite.hoverbot.propL.baseOffset
        fan2: = hover.position + rotm*sprite.hoverbot.propR.baseOffset
        bombPos: = hover.position + rotm*sprite.hoverbot.bomb.baseOffset
        if launch {
            spawn_projectile(.RobotBomb, bombPos, hover.velocity)
            sound.play(&sound.robotShoot)
        }

        hitbox(&gameState.enemyHitboxes, hover.position, 16, &hover)
        hitbox(&gameState.enemyHitboxes, fan1, 16, &hover, 1)
        hitbox(&gameState.enemyHitboxes, fan2, 16, &hover, 2)
        if procbox(&gameState.playerHitboxes, fan1, 16, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
            damage_hitobj_proc(overlap, id, ob, 1)
            return true
        }) && .Spikes in gameState.player.mutations {
            damage_hitobj_proc(0, 0, &hover, 100)
        }
        if procbox(&gameState.playerHitboxes, fan2, 16, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
            damage_hitobj_proc(overlap, id, ob, 1)
            return true
        }) && .Spikes in gameState.player.mutations {
            damage_hitobj_proc(0, 0, &hover, 100)
        }
    }

    for &saw in sawbots {
        if !saw.alive { continue }
        navpos: = saw.position - SAW_NAV_SIZE*0.5
        switch saw.state {
            case .Spawn:
            if saw.spawnTimer.on {
                ganim.tick(&saw.spawnTimer, dt)
                if ganim.on(&saw.spawnTimer) {
                    saw.state = .Roaming
                }
                continue
            }
            saw.speed = min(saw.speed + 1200 * dt, 3200)
            saw.position.y += saw.speed * dt
            clipped, move: = level.deviolate_obstacles(gameState.cLevel.obstacles[:], navpos, SAW_NAV_SIZE)
            saw.spawnTimer.on = clipped
            if clipped {
                saw.speed = 0
                saw.position += move
            }
            case .Roaming:
            saw.speed = util.accel(saw.speed, 300, dt * 400)
            saw.spin += 2* saw.speed * dt
            sawMoves: = [][2]f32{
                {-1, 0},
                {0, 1},
                {1, 0},
                {0, -1},
            }
            move: = sawMoves[util.intwrap(saw.direction, i32(len(sawMoves)))]
            nextMove: = sawMoves[util.intwrap(saw.direction + saw.directionInc, i32(len(sawMoves)))]
            if !level.overlaps(gameState.cLevel.obstacles[:], navpos + nextMove * 16, SAW_NAV_SIZE) {
                saw.direction += saw.directionInc
                saw.position += nextMove * saw.speed * 2 * dt
            } else {
                move *= saw.speed * dt
                navpos += move

                clipped, dvmove: = level.deviolate_obstacles(gameState.cLevel.obstacles[:], navpos, SAW_NAV_SIZE)
                if clipped {
                    saw.direction -= saw.directionInc
                }
                saw.position += move + dvmove
            }
        }
        if saw.state != .Spawn {
            hitbox(&gameState.enemyHitboxes, saw.position, 32, &saw)
            if procbox(&gameState.playerHitboxes, saw.position, 64, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 2)
                return true
            }) && .Spikes in gameState.player.mutations {
                damage_hitobj_proc(0, 0, &saw, 100)
            }
        }
    }

    for &shield in shieldbots {
        if !shield.alive { continue }
        navpos: = shield.position - {PLAYER_NAV_WIDTH, PLAYER_NAV_HEIGHT} * 0.5
        delta: = gameState.player.position - shield.position
        flip: f32 = (shield.flipped) ? -1 : 1
        SHIELD_HSPEED:: 200
        SHIELD_ACCEL:: 500
        shield.velocity.y += 1200*dt
        switch shield.state {
            case .Spawn:
            case .Drive:
            if math.abs(delta.x) < 480 {
                overlaps: bool
                for os in shieldbots {
                    if os.position == shield.position || os.state != .Park { continue }
                    if linalg.distance(shield.position, os.position) < PLAYER_NAV_WIDTH {
                        overlaps = true
                        break
                    }
                }
                if !overlaps {
                    shield.velocity.x = util.accel(shield.velocity.x, 0, SHIELD_ACCEL * dt)
                    if shield.velocity.x == 0 {
                        shield.state = .Park
                    }
                } else {
                    shield.velocity.x = util.accel(shield.velocity.x, SHIELD_HSPEED * math.sign(shield.velocity.x), SHIELD_ACCEL * dt)
                }
            } else {
                shield.velocity.x = util.accel(shield.velocity.x, SHIELD_HSPEED * math.sign(delta.x), SHIELD_ACCEL * dt)
            }
            case .Park:
            if math.abs(delta.x) > 568 {
                shield.state = .Drive
            } else {
                targetAngle: = math.atan2(delta.y, delta.x * flip)
                shield.turretAngle = math.angle_lerp(shield.turretAngle, targetAngle, dt * 5)
                if ganim.off(&shield.timer) {
                    if math.abs(math.angle_diff(targetAngle, shield.turretAngle)) < math.to_radians_f32(5) {
                        shield.timer.t = 1
                        shootDir: = [2]f32{
                            math.cos(shield.turretAngle)*flip,
                            math.sin(shield.turretAngle),
                        }
                        shootPos: = shootDir * 8 + shield.position
                        spawn_projectile(.RobotScatter, shootPos, shootDir * 400)
                        sound.play(&sound.robotShoot)
                    }
                }
            }
        }
        ganim.tick(&shield.timer, dt)
        clipped, move: = level.deviolate_obstacles(gameState.cLevel.obstacles[:], navpos, PLAYER_NAV_VEC)
        if clipped {
            if shield.state == .Spawn {
                shield.spawnTimer.on = true
                ganim.tick(&shield.spawnTimer, dt)
                if ganim.on(&shield.spawnTimer) {
                    shield.state = .Drive
                }
            }
            if move.x != 0 && math.sign(move.x) != math.sign(shield.velocity.x) {
                shield.velocity.x *= -0.1 
            }
            if move.y != 0 && math.sign(move.y) != math.sign(shield.velocity.y) {
                shield.velocity.y = 0
            }
        }
        shield.position += shield.velocity * dt + move
        shield.roll += flip * shield.velocity.x / 16
        if shield.state != .Spawn {
            hitbox(&gameState.enemyHitboxes, shield.position, 64, &shield)
            if procbox(&gameState.playerHitboxes, shield.position, 32, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 2)
                return true
            }) && .Spikes in gameState.player.mutations {
                damage_hitobj_proc(0, 0, &shield, 100)
            }
        }
    }
}

draw_enemies:: proc(dt: f32)
{
    for &shield in shieldbots {
        if !shield.alive { continue }
        shield.flicker = (shield.state != .Spawn) || !shield.flicker
        if !shield.flicker { continue }
        sprite.begin_parts()
        sprite.draw_part(&sprite.shieldbot.body, 0, 0, shield.flipped, 255)
        sprite.draw_part(&sprite.shieldbot.wheelBack, 0, shield.roll, shield.flipped, 255)
        sprite.draw_part(&sprite.shieldbot.wheelFront, 0, shield.roll + 22, shield.flipped, 255)
        sprite.draw_part(&sprite.shieldbot.turret, 0, math.to_degrees(shield.turretAngle), shield.flipped, 255)
        sprite.end_parts(shield.position, 0)
    }

    for &saw in sawbots {
        if !saw.alive { continue }
        saw.flicker = (saw.state != .Spawn) || !saw.flicker
        if !saw.flicker { continue }
        sprite.begin_parts()
        sprite.draw_part(&sprite.sawbot.saw, 0, saw.spin, saw.directionInc > 0, 255)
        sprite.draw_part(&sprite.sawbot.face, 0, 0, saw.directionInc > 0, 255)
        sprite.end_parts(saw.position, 0)
    }

    for &boxer in boxerbots {
        if !boxer.alive { continue }
        flipped: = boxer.velocity.x < 0
        sprite.begin_parts()
        sprite.draw_part(&sprite.boxerbot.fistL, 0, 0, flipped, 255)
        sprite.draw_part(&sprite.boxerbot.fistR, {96*boxer.punch.t, 0}, 0, flipped, 255)
        sprite.draw_part(&sprite.boxerbot.hull, 0, 0, flipped, 255)
        sprite.end_parts(boxer.position, 0)
    }

    for &hover in hoverbots {
        if !hover.alive { continue }
        sprite.begin_parts()
        sprite.draw_part(&sprite.hoverbot.propL, 0, 0, false, 255)
        sprite.draw_part(&sprite.hoverbot.propR, 0, 0, false, 255)
        sprite.draw_part(&sprite.hoverbot.hull, 0, 0, false, 255)
        if hover.state == .Bomb { sprite.draw_part(&sprite.hoverbot.bomb, 0, 0, false, 255) }
        sprite.end_parts(hover.position, hover.angle)
    }
}
