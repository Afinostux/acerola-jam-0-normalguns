package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

import "clip"
import "level"
import "util"
import "ganim"
import "sprite"
import "sound"

PlayerState:: enum{
    Idle,
    Walking,
    Jumping,
    Airborne,
    Landing,
    StartClimb,
    Climb,
    ClimbAttack,
    EndClimb,
}

PlayerWeapon:: enum{
    Rifle,
    Shotgun,
    Grenade,
    Rocket,
}

PlayerStateSet:: bit_set[PlayerState]

playerPhysicalStates: = PlayerStateSet{
    .Idle, .Walking, .Jumping, .Airborne, .Landing,
}

playerAttackStates: = PlayerStateSet{
    .Idle, .Walking, .Jumping, .Airborne, .Landing, .ClimbAttack,
}

// MUTATIONS
// Goat horns
// Telekinesis
// Laser eye
// Flame breath
// Eat metal
// Wings
// Spikes
// Claws

PlayerMutations:: enum {
    Goat,
    Telekinesis,
    Hunger,
    Spikes,
    Claws,
    Wings,
}

PlayerMutationSet:: bit_set[PlayerMutations]

Player:: struct {
    position:    [2]f32,
    velocity:    [2]f32,
    aim:         [2]f32,
    jolt:        [2]f32,
    walkTarget:  f32,
    life:        int,

    climb:       PlayerClimb,

    grounded:    bool,
    noMask:      bool,
    noHelmet:    bool,
    noGlasses:   bool,
    noHair:      bool,
    mutations:   PlayerMutationSet,

    state:       PlayerState,
    nextState:   PlayerState,

    weapon:      PlayerWeapon,
    shotgunAmmo: i32,
    grenadeAmmo: i32,
    rocketAmmo:  i32,

    walkSeq:     ganim.Gloop,
    jumpTimer:   ganim.Ganim,
    invulnTimer: ganim.Ganim,
    telekTimer:  ganim.Ganim,
    flicker:     bool,
}

player_mutate:: proc(player: ^Player, mutation: PlayerMutations)
{
    MSGTIME:: 6
    switch mutation {
        case .Goat:
        player.noHelmet = true
        show_message("Got RAM HORNS", MSGTIME)
        case .Telekinesis:
        player.noGlasses = true
        show_message("Got PSYCHIC BARRIER", MSGTIME)
        case .Hunger:
        player.noMask = true
        show_message("Got POWERUP HUNGER", MSGTIME)
        case .Spikes:
        show_message("Got BODY SPIKES", MSGTIME)
        case .Claws:
        show_message("Got CLIMBING CLAWS", MSGTIME)
        case .Wings:
        show_message("Got WINGS", MSGTIME)
    }
    player.mutations += {mutation}
}

player_random_mutate:: proc(player: ^Player)
{
    mutations: [len(PlayerMutations)]PlayerMutations
    muti: i32
    for m in PlayerMutations {
        if !(m in player.mutations) {
            mutations[muti] = m
            muti += 1
        }
    }
    if muti == 0 {
        player.life = min(player.life + 1, len(gameState.lifePipAnim))
    } else {
        player_mutate(player, rand.choice(mutations[:muti]))
    }
    sound.play(&sound.mutate)
}

PLAYER_NAV_WIDTH::             56
PLAYER_NAV_PERMISSIVE_WIDTH::  PLAYER_NAV_WIDTH - 2
PLAYER_NAV_HEIGHT::            100
PLAYER_NAV_PERMISSIVE_HEIGHT:: PLAYER_NAV_HEIGHT - 2

PLAYER_NAV_VEC:: [2]f32{
    PLAYER_NAV_WIDTH,
    PLAYER_NAV_HEIGHT,
}
PLAYER_NAV_VEC_PERMISSIVE:: [2]f32{
    PLAYER_NAV_PERMISSIVE_WIDTH,
    PLAYER_NAV_PERMISSIVE_HEIGHT,
}

player_set_weapon:: proc(player: ^Player, weapon: PlayerWeapon) -> bool
{
    switch weapon {
        case .Rifle:
        case .Shotgun:
        if player.shotgunAmmo == 0 { return false }
        case .Grenade:
        if player.grenadeAmmo == 0 { return false }
        case .Rocket:
        if player.rocketAmmo == 0 { return false }
    }
    player.weapon = weapon
    return true
}

player_fire_weapon:: proc(player: ^Player)
{
    switch player.weapon {
        case .Rifle:
        spawn_projectile(
            .PlayerRifle,
            player.position + player.aim * 48,
            player.aim * 1200,
        )
        sound.play(&sound.rifleShoot)
        case .Shotgun:
        for _ in 0..<8 {
            scatter: = [2]f32{
                rand.float32_range(-200, 200),
                rand.float32_range(-200, 200),
            }
            spawn_projectile(
                .PlayerShotgun,
                player.position + player.aim * 32,
                player.aim * 1200 + scatter,
            )
        }
        player.shotgunAmmo -= 1
        if player.shotgunAmmo == 0 {
            player_set_weapon(player, .Rifle)
        }
        sound.play(&sound.shotgunShoot)
        case .Grenade:
        spawn_projectile(
            .PlayerGrenade,
            player.position + player.aim * 40,
            player.aim * 800,
        )
        player.grenadeAmmo -= 1
        if player.grenadeAmmo == 0 {
            player_set_weapon(player, .Rifle)
        }
        sound.play(&sound.grenadeShoot)
        case .Rocket:
        spawn_projectile(
            .PlayerRocket,
            player.position + player.aim * 48,
            player.aim * 320,
        )
        player.rocketAmmo -= 1
        if player.rocketAmmo == 0 {
            player_set_weapon(player, .Rifle)
        }
        sound.play(&sound.rocketLaunch)
    }
}

player_next_weapon:: proc(player: ^Player)
{
    switch player.weapon {
        case .Rifle:
        if   player_set_weapon(player, .Shotgun) { return }
        if   player_set_weapon(player, .Grenade) { return }
        if   player_set_weapon(player, .Rocket)  { return }
        case .Shotgun:
        if   player_set_weapon(player, .Grenade) { return }
        if   player_set_weapon(player, .Rocket)  { return }
        if   player_set_weapon(player, .Rifle)   { return }
        case .Grenade:
        if   player_set_weapon(player, .Rocket)  { return }
        if   player_set_weapon(player, .Rifle)   { return }
        if   player_set_weapon(player, .Shotgun) { return }
        case .Rocket:
        if   player_set_weapon(player, .Rifle)   { return }
        if   player_set_weapon(player, .Shotgun) { return }
        if   player_set_weapon(player, .Grenade) { return }
    }
}

player_prev_weapon:: proc(player: ^Player)
{
    switch player.weapon {
        case .Rifle:
        if   player_set_weapon(player, .Rocket)  { return }
        if   player_set_weapon(player, .Grenade) { return }
        if   player_set_weapon(player, .Shotgun) { return }
        case .Shotgun:
        if   player_set_weapon(player, .Rifle)   { return }
        if   player_set_weapon(player, .Rocket)  { return }
        if   player_set_weapon(player, .Grenade) { return }
        case .Grenade:
        if   player_set_weapon(player, .Shotgun) { return }
        if   player_set_weapon(player, .Rifle)   { return }
        if   player_set_weapon(player, .Rocket)  { return }
        case .Rocket:
        if   player_set_weapon(player, .Grenade) { return }
        if   player_set_weapon(player, .Shotgun) { return }
        if   player_set_weapon(player, .Rifle)   { return }
    }
}

hit_player:: proc(player: ^Player, overlap: [2]f32, damage: int)
{
    if !ganim.off(&player.invulnTimer) || player.life == 0 { return }
    if .Telekinesis in player.mutations && ganim.off(&player.telekTimer) {
        ganim.start_cooldown(&player.telekTimer, 10)
        for _ in 0..<60 {
            spawn_projectile(.PlayerShotgun, player.position, linalg.normalize([2]f32{
                rand.float32_range(-1, 1),
                rand.float32_range(-1, 1),
            }) * 800)
        }
        sound.play(&sound.shieldBurst)
        return
    }
    damage: = damage
    if .Spikes in player.mutations {
        damage = max(damage/2, 1)
    }
    player.invulnTimer.t = 1
    player.life -= damage
    if player.life <= 2 {
        player.noHair = true
        sound.play(&sound.pickUp)
    }
    if player.life <= 0 {
        explode_fx_large(player.position)
        explode_fx_medium(player.position)
        player.life = 0
        sound.play(&sound.explosionBig)
        return
    }
    lostMut: = rand.choice_enum(PlayerMutations)
    if lostMut in player.mutations {
        MSGTIME:: 6
        switch lostMut {
            case .Goat:
            show_message("No longer goated", MSGTIME)
            case .Telekinesis:
            show_message("You have a headache", MSGTIME)
            case .Hunger:
            show_message("You feel full", MSGTIME)
            case .Spikes:
            show_message("You don't feel so sharp", MSGTIME)
            case .Claws:
            show_message("You've got butterfingers", MSGTIME)
            case .Wings:
            show_message("You're grounded", MSGTIME)
        }
        sound.play(&sound.pickUp)
        player.mutations -= {lostMut}
    } else {
        sound.play(&sound.playerHit)
    }
}

tick_player:: proc(player: ^Player, dt: f32)
{
    clear(&gameState.playerHitboxes)
    ganim.tick(&player.telekTimer, dt)
    if player.life == 0 { return }
    pvel: = player.velocity
    if rl.GetMouseWheelMove() > 0 {
        player_next_weapon(player)
    } else
    if rl.GetMouseWheelMove() < 0 {
        player_prev_weapon(player)
    }
    if gameWeapon[0].pressed { player_set_weapon(player, .Rifle) }
    if gameWeapon[1].pressed { player_set_weapon(player, .Shotgun) }
    if gameWeapon[2].pressed { player_set_weapon(player, .Grenade) }
    if gameWeapon[3].pressed { player_set_weapon(player, .Rocket) }
    ganim.tick(&player.invulnTimer, dt)
    if player.state != player.nextState {
        // end state
        switch player.state {
            case .Idle:
            case .Walking:
            case .Jumping:
            case .Airborne:
            case .Landing:
            case .StartClimb:
            case .Climb:
            case .ClimbAttack:
            case .EndClimb:
        }

        // begin state
        switch player.nextState {
            case .Idle:
            case .Walking:
            player.walkTarget = 0
            player.walkSeq.duration = 1
            player.walkSeq.loops = -1

            case .Jumping:
            ganim.start_timer(&player.jumpTimer, 0.125)

            case .Airborne:
            case .Landing:

            case .StartClimb:
            init_player_climb(&player.climb)

            case .Climb:
            case .ClimbAttack:

            case .EndClimb:
            ganim.start_timer(&player.jumpTimer, 0.1)
        }

        player.state = player.nextState
    }
    if player.state in playerPhysicalStates {
        player.velocity.y += 1200*dt
        player.velocity = linalg.clamp(player.velocity, -3200, 3200)
        player.position += player.velocity * dt

        clipped, move: = level.deviolate_obstacles(
            gameState.cLevel.obstacles[:],
            player.position - PLAYER_NAV_VEC * 0.5,
            PLAYER_NAV_VEC,
        )

        player.grounded = move.y < 0

        if clipped {
            player.position += move
            for i in 0..<2 {
                if player.velocity[i] * move[i] < 0 { player.velocity[i] = 0 }
            }
        }
    } else {
        player.grounded = false
        player.velocity = 0
    }


    when true {
        // player movement config
        STANDING_JUMP::     800
        WALKING_JUMP::      700
        WALK_ACCEL::        1600
        WALK_SPEED::        320
        AIR_ACCEL::         800
        AIR_SPEED::         320

        BEGIN_CLIMB_SPEED:: 320
        CLIMB_SPEED_H::     280
        CLIMB_SPEED_V::     160
    }
    switch player.state {
        case .Idle:

        player.walkTarget = 0
        
        if gameLeft.down || gameRight.down {
            player.nextState = .Walking
        }

        if player.grounded {
            player.velocity.x = util.accel(player.velocity.x, 0, WALK_ACCEL * dt)
            if gameJump.down {
                player.nextState = .Jumping
                if math.abs(player.velocity.x) < WALK_SPEED*0.5 {
                    player.velocity.y = -STANDING_JUMP
                } else {
                    player.velocity.y = -WALKING_JUMP
                }
            }
        } else {
            player.nextState = .Airborne
        }

        if (gameUp.pressed || gameDown.pressed) && level.overlaps(gameState.cLevel.climbable[:], player.position - PLAYER_NAV_VEC * 0.5, PLAYER_NAV_VEC) {
            player.nextState = .StartClimb
        }

        case .Walking:
        if gameLeft.down != gameRight.down {
            if gameLeft.down {
                player.velocity.x = util.accel(player.velocity.x, -WALK_SPEED, WALK_ACCEL * dt)
                player.walkTarget = -WALK_SPEED
            } else {
                player.velocity.x = util.accel(player.velocity.x, WALK_SPEED, WALK_ACCEL * dt)
                player.walkTarget = WALK_SPEED
            }
        } else {
            player.velocity.x = util.accel(player.velocity.x, 0, WALK_ACCEL * dt)
            if player.velocity.x == 0 {
                player.nextState = .Idle
            }
        }

        if player.grounded {
            if gameJump.down {
                player.nextState = .Jumping
                if math.abs(player.velocity.x) < WALK_SPEED*0.5 {
                    player.velocity.y = -STANDING_JUMP
                } else {
                    player.velocity.y = -WALKING_JUMP
                }
            }
        } else {
            player.nextState = .Airborne
        }

        if (gameUp.pressed || gameDown.pressed) && level.overlaps(gameState.cLevel.climbable[:], player.position - PLAYER_NAV_VEC * 0.5, PLAYER_NAV_VEC) {
            player.nextState = .StartClimb
        }


        case .Jumping:
        ganim.tick(&player.jumpTimer, dt)
        if ganim.on(&player.jumpTimer) {
            player.nextState = .Airborne
        } else {
            if gameLeft.down != gameRight.down {
                if gameLeft.down {
                    player.velocity.x = util.accel(player.velocity.x, -WALK_SPEED, WALK_ACCEL * dt)
                } else {
                    player.velocity.x = util.accel(player.velocity.x, WALK_SPEED, WALK_ACCEL * dt)
                }
            }
        }

        case .Airborne:
        airmul: f32 = (.Wings in player.mutations) ? 1.2 : 1
        if gameLeft.down != gameRight.down {
            if gameLeft.down {
                player.velocity.x = util.accel(player.velocity.x, -AIR_SPEED, airmul * AIR_ACCEL * dt)
            } else {
                player.velocity.x = util.accel(player.velocity.x, AIR_SPEED, airmul * AIR_ACCEL * dt)
            }
        }

        if player.grounded {
            player.nextState = .Landing
        }

        if .Wings in player.mutations {
            if gameJump.pressed {
                player.velocity += {0, -WALKING_JUMP * 0.5}
            }
        }

        if .Claws in player.mutations {
            if gameUp.down && player.velocity.y > 0 && level.overlaps(gameState.cLevel.climbable[:], player.position - PLAYER_NAV_VEC * 0.5, PLAYER_NAV_VEC) {
                player.nextState = .StartClimb
            }
        }

        case .Landing:
        if player.grounded {
            player.velocity.x = util.accel(player.velocity.x, 0, AIR_ACCEL * dt)
            if player.jolt.y == 0 {
                player.nextState = .Idle
            }
            if gameJump.pressed {
                player.nextState = .Jumping
                if math.abs(player.velocity.x) < WALK_SPEED*0.5 {
                    player.velocity.y = -STANDING_JUMP
                } else {
                    player.velocity.y = -WALKING_JUMP
                }
            }
        } else {
            player.nextState = .Airborne
        }

        case .StartClimb:
        move: = level.move_rect_to_climbable(
            gameState.cLevel.climbable[:],
            player.position - PLAYER_NAV_VEC * 0.5,
            PLAYER_NAV_VEC,
        )
        tick_player_climb(&player.climb, move, dt)
        if linalg.length2(move) == 0 {
            player.nextState = .Climb
        } else {
            player.position += linalg.normalize(move) * BEGIN_CLIMB_SPEED * dt
        }

        case .Climb:
        pstart: = player.position
        clawmul: f32 = (.Claws in player.mutations) ? 1.2 : 1
        if gameUp.down != gameDown.down {
            if gameDown.down {
                player.position.y += clawmul * CLIMB_SPEED_V * dt
            } else {
                player.position.y -= clawmul * CLIMB_SPEED_V * dt
            }
        }
        if gameLeft.down != gameRight.down {
            if gameRight.down {
                player.position.x += clawmul * CLIMB_SPEED_H * dt
            } else {
                player.position.x -= clawmul * CLIMB_SPEED_H * dt
            }
        }


        move: = level.move_rect_to_climbable(
            gameState.cLevel.climbable[:],
            player.position - PLAYER_NAV_VEC * 0.5,
            PLAYER_NAV_VEC,
        )
        player.position += move
        inLevel: = level.overlaps(
            gameState.cLevel.obstacles[:],
            player.position - PLAYER_NAV_VEC_PERMISSIVE * 0.5,
            PLAYER_NAV_VEC_PERMISSIVE,
        )
        if (move.y < 0 || gameJump.down) && !inLevel {
            player.nextState = .EndClimb
        }
        tick_player_climb(&player.climb, (player.position - pstart)/dt, dt)

        case .ClimbAttack:
        ganim.tick(&player.jumpTimer, dt)
        if gameAttack.down {
            ganim.start_timer(&player.jumpTimer, 0.25)
        }

        if ganim.on(&player.jumpTimer) {
            player.nextState = .Climb
        }

        case .EndClimb:
        ganim.tick(&player.jumpTimer, dt)
        if ganim.on(&player.jumpTimer) {
            if .Claws in player.mutations && gameJump.down {
                player.nextState = .Jumping
                player.velocity.y = -WALKING_JUMP
            } else {
                player.nextState = .Idle
            }
        }

        if !gameJump.down && gameUp.pressed && level.overlaps(gameState.cLevel.climbable[:], player.position - PLAYER_NAV_VEC * 0.5, PLAYER_NAV_VEC) {
            player.nextState = .StartClimb
        }
    }

    player.jolt = util.accel2d(player.jolt, 0, 40* dt)

    // aim point
    player.aim = linalg.normalize(rl.GetScreenToWorld2D(rl.GetMousePosition(), gameState.camera) - player.position)
    if player.state in playerAttackStates {
        if gameAttack.pressed {
            player_fire_weapon(player)
        }
    }
    player.jolt = linalg.clamp(player.jolt + (pvel - player.velocity)/80, -16, 16)
    
    if ganim.off(&player.invulnTimer) {
        hitbox(&gameState.playerHitboxes, player.position, PLAYER_NAV_WIDTH * 0.8, player)
    }

    if .Goat in player.mutations && player.state in playerPhysicalStates {
        if player.velocity.y < (-WALKING_JUMP * 0.2) {
            if procbox(&gameState.enemyHitboxes, player.position + sprite.normalgunsSrc.head.baseOffset, 32, proc(overlap: [2]f32, id: i32, ob: HitObject) -> bool {
                damage_hitobj_proc(overlap, id, ob, 100)
                return true
            }) {
                player.velocity.y = 0
            }
        }
    }
}

draw_player:: proc(player: ^Player, dt: f32)
{
    if player.life == 0 { return }
    player.flicker = !player.flicker
    if player.flicker && !ganim.off(&player.invulnTimer) {
        return
    }
    ngs: = &sprite.normalgunsSrc
    sprite.begin_parts()
    if .Telekinesis in player.mutations && ganim.off(&player.telekTimer) {
        rl.DrawCircleV(player.position, PLAYER_NAV_HEIGHT*0.5, {40, 92, 196, 128})
    }
    switch player.state {
        case .Idle:
        // use normal sprite
        // return feet to neutral position if displaced
        // body/weapon tilt for mouse aim
        sprite.draw_part(&ngs.footLeft, 0, 0, player.aim.x < 0, 255)
        sprite.draw_part(&ngs.footRight, 0, 0, player.aim.x < 0, 255)
        draw_player_body_aim(player, 0, 255)

        case .Walking:
        // use normal sprite
        // walk sequence
        // body/weapon tilt for mouse aim
        step: = player.velocity.x/80 * ((player.aim.x < 0) ? -1 : 1)
        ganim.tick(&player.walkSeq, dt * step)
        mix: f32 = math.clamp(1 - math.abs((player.walkTarget - player.velocity.x)/320), 0, 1)
        ofsFootLeft: = ganim.sample_gloop(&player.walkSeq, footAnim, 0)
        ofsFootRight: = ganim.sample_gloop(&player.walkSeq, footAnim, 0.5)
        ofsBody: = ganim.sample_gloop(&player.walkSeq, walkBodyAnim, 0)
        sprite.draw_part(&ngs.footLeft, ofsFootLeft * mix, 0, player.aim.x < 0, 255)
        sprite.draw_part(&ngs.footRight, ofsFootRight * mix, 0, player.aim.x < 0, 255)
        draw_player_body_aim(player, ofsBody * mix, 255)

        case .Jumping:
        sprite.draw_part(&ngs.footLeft, {0, -player.jolt.y * 2}, 0, player.aim.x < 0, 255)
        sprite.draw_part(&ngs.footRight, {0, player.jolt.y}, 0, player.aim.x < 0, 255)
        draw_player_body_aim(player, 0, 255)

        case .Airborne:
        offset: [2]f32
        flip: = player.aim.x < 0
        if player.velocity.y > 0 {
            offset = linalg.clamp(player.velocity/160, -16, 16)
            offset += player.jolt
        } else {
            offset = linalg.clamp(player.velocity/160, -16, 16)
        }
        if player.velocity.x == 0 {
            offset.y = player.jolt.y
        } else
        if player.velocity.x < 0 {
            offset.y *= -1
        }
        if flip {
            offset *= -1
        }
        sprite.draw_part(&ngs.footLeft, offset, 0, flip, 255)
        sprite.draw_part(&ngs.footRight, -offset, 0, flip, 255)
        draw_player_body_aim(player, 0, 255)

        case .Landing:
        sprite.draw_part(&ngs.footLeft, { player.jolt.y, 0 }, 0, player.aim.x < 0, 255)
        sprite.draw_part(&ngs.footRight, { -player.jolt.y, 0 }, 0, player.aim.x < 0, 255)
        draw_player_body_aim(player, 0, 255)

        case .StartClimb:
        draw_player_climb(player, dt)

        case .Climb:
        draw_player_climb(player, dt)

        case .ClimbAttack:
        // use climbing body and feet, normal head, climbing gun if time permits
        // keep foot position from climb
        // body/weapon tilt for mouse aim
        flip: = player.aim.x < 0
        aimAngle: = math.to_degrees(-math.acos(player.aim.y)) + 90

        //draw_player_head(player, {player.aim.y * 28, abs(player.aim.y) * 8}, aimAngle, flip, 255)
        draw_player_climb_head(player, {player.aim.y * 14 * ((flip)?-1:1), abs(player.aim.y) * 4}, aimAngle * 0.5 * ((flip)?-1:1), dt)

        draw_player_weapon(player, 0, aimAngle, flip, 255, -2)
        sprite.draw_part(&ngs.bodyClimb, {player.aim.y * 7 * ((flip)?1:-1), 0}, aimAngle*0.2 * ((flip)?1:-1), false, 255)

        sprite.draw_part(&ngs.footLClimbGrip, player.climb.limbs[.Foot_l].offset, 0, false, 255, -2)
        sprite.draw_part(&ngs.footRClimbGrip, player.climb.limbs[.Foot_r].offset, 0, false, 255, -2)

        case .EndClimb:
        draw_player_climb(player, dt)
    }
    sprite.end_parts(player.position, 0)
}

