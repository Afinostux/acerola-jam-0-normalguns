package main

import "core:math"
import "core:math/rand"
import "core:math/linalg"

import "sprite"
import "ganim"
import "sound"

PowerupType:: enum {
    Shotgun,
    Grenade,
    Rocket,
    Mutation,
}

Powerup:: struct {
    timeLeft: f32,
    type:     PowerupType,
    position: [2]f32,
    flicker:  bool,
}

powerups: [dynamic]Powerup

spawn_random_powerup:: proc(position: [2]f32, chance: i32)
{
    if chance <= 0 { return }
    if rand.int31()%10 < chance {
        np: = Powerup {
            timeLeft = 10,
            type = rand.choice_enum(PowerupType),
            position = position,
        }
        for &p in powerups {
            if p.timeLeft <= 0 {
                p = np // solved it lol
                return
            }
        }
        append(&powerups, np)
    }
}

tick_powerups:: proc(dt: f32)
{
    for &p in powerups {
        if p.timeLeft > 0 {
            p.timeLeft -= dt

            if ganim.off(&gameState.player.invulnTimer) && linalg.distance(gameState.player.position, p.position) < (PLAYER_NAV_HEIGHT*0.5) {
                p.timeLeft = 0
                if .Hunger in gameState.player.mutations {
                    gameState.player.life = min(gameState.player.life + 1, 20)
                }
                switch p.type {
                    case .Shotgun:
                    gameState.player.shotgunAmmo += 6
                    sound.play(&sound.rocketAmmo)
                    case .Grenade:
                    gameState.player.grenadeAmmo += 4
                    sound.play(&sound.rocketAmmo)
                    case .Rocket:
                    gameState.player.rocketAmmo += 2
                    sound.play(&sound.rocketAmmo)
                    case .Mutation:
                    player_random_mutate(&gameState.player)
                }
            }
        }
    }
}

draw_powerups:: proc(dt: f32)
{
    for &p in powerups {
        if p.timeLeft > 0 {
            if p.timeLeft < 1 {
                p.flicker = !p.flicker
                if p.flicker { continue }
            }
            psp: ^sprite.Sprite
            switch p.type {
                case .Shotgun:
                psp = &sprite.shotgunAmmo
                case .Grenade:
                psp = &sprite.grenadeAmmo
                case .Rocket:
                psp = &sprite.rocketAmmo
                case .Mutation:
                psp = &sprite.powerup
            }
            sprite.draw_sprite(psp, p.position, 0, 255, 0, scale=1 + math.sin(p.timeLeft*20)*0.1)
        }
    }
}
