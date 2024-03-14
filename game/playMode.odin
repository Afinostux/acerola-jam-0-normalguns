package main

import "core:fmt"

import rl "vendor:raylib"
import "control"
import "mode"

import "ganim"
import "sprite"
import "level"

CameraMode:: enum{
    FollowPlayer,
    Arena,
    ForcedScroll,
}

gameState: struct{
    camera:         rl.Camera2D,
    cameraMode:     CameraMode,

    player:         Player,

    message:        cstring,
    messageAnim:    ganim.Ganim,

    wave:           i32,
    killreq:        i32,
    score:          i32,
    scoreDisp:      i32,
    scoreAnim:      ganim.Ganim,
    
    lifePipAnim:    [20]ganim.Ganim,

    cLevel:         level.Level,

    playerHitboxes: [dynamic]Hitbox,
    enemyHitboxes:  [dynamic]Hitbox,
}

tick_play:: proc(dt: f32)
{
    using gameState
    tick_player(&player, dt)
    switch cameraMode {
        case .FollowPlayer:
        camera.target = player.position
        case .Arena:
        case .ForcedScroll:
    }
    tick_powerups(dt)

    tick_enemies(dt)

    tick_projectiles(dt)
    if rl.IsKeyPressed(.ESCAPE) {
        mode.set_mode(&mainMenuMode)
    }
}


draw_play:: proc(dt: f32)
{
    using gameState
    screenSize: = [2]f32{
        f32(rl.GetScreenWidth()),
        f32(rl.GetScreenHeight()),
    }

    camera.offset = screenSize * 0.5
    camera.zoom = screenSize.y/720

    rl.BeginMode2D(camera)
    for obs in cLevel.obstacles {
        rl.DrawRectangleV(obs.position, obs.size, {115, 23, 45, 255})
    }
    for obs in cLevel.climbable {
        rl.DrawRectangleV(obs.position, obs.size, {109, 117, 141, 128})
    }
    //rl.DrawText("HELL YEAH BROTHER", 10, 10, 40, 255)


    draw_player(&player, dt)
    draw_enemies(dt)
    draw_powerups(dt)
    draw_projectiles(dt)
    draw_fx(dt)
    rl.EndMode2D()

    if dt > 0 {
        // draw play UI
        for &pip, i in lifePipAnim {
            pip.on = i >= player.life
            ganim.tick(&pip, dt)
            sprite.draw_sprite_ganim(&sprite.lifepip, &pip, {30, 30} + {20*f32(i), 0}, 0, 255)
        }
        scoreAnim.on = score != scoreDisp
        ganim.tick(&scoreAnim, dt)
        if ganim.on(&scoreAnim) {
            scoreAnim.t = 0
            if scoreDisp < score {
                scoreDisp += 1
            } else {
                scoreDisp -= 1
            }
        }
        rl.DrawText(rl.TextFormat("Wave %d: %d kills until next wave", gameState.wave, gameState.killreq), 24, 60, 20, rl.WHITE)
        rl.DrawText(rl.TextFormat("Score: %d", scoreDisp), 24, 84, 20, rl.WHITE)
        rl.DrawText(rl.TextFormat("Shotgun: %d", player.shotgunAmmo), 435, 20, 20, rl.WHITE)
        rl.DrawText(rl.TextFormat("Grenades: %d", player.grenadeAmmo), 435, 44, 20, rl.WHITE)
        rl.DrawText(rl.TextFormat("Rockets: %d", player.rocketAmmo), 435, 66, 20, rl.WHITE)
        mouse: = rl.GetMousePosition()
        rl.DrawTriangle(mouse + {5,  0},  mouse + {20,  3},   mouse + {20,  -3},  255)
        rl.DrawTriangle(mouse + {-5, 0},  mouse + {-20, -3},  mouse + {-20, 3},   255)
        rl.DrawTriangle(mouse + {0,  5},  mouse + {-3,  20},  mouse + {3,   20},  255)
        rl.DrawTriangle(mouse + {0,  -5}, mouse + {3,   -20}, mouse + {-3,  -20}, 255)

        if !ganim.off(&gameState.messageAnim) {
            rl.DrawText(gameState.message, 20, i32(screenSize.y) - 80, 70, rl.Fade(rl.WHITE, gameState.messageAnim.t))
        }
        ganim.tick(&gameState.messageAnim, dt)
    }
}

show_message:: proc(message: cstring, time: f32)
{
    gameState.message = message
    ganim.start_cooldown(&gameState.messageAnim, time)
}

create_play:: proc()
{
    using gameState
    delete(playerHitboxes)
    delete(enemyHitboxes)
    gameState = {}
    cLevel = level.load(0)
    player.life = len(lifePipAnim)
    player.invulnTimer = ganim.Ganim{
        timeOff = 3,
    }
    for &pip in lifePipAnim {
        pip = ganim.Ganim{
            t = 0,
            timeOn = 1.0,
            timeOff = 1.0,
        }
    }
    gameState.scoreAnim = ganim.Ganim{
        timeOn = 1.0/90,
    }
    spawn_wave()
}

destroy_play:: proc()
{
}

enter_play:: proc()
{
    control.set_active_layer(&gameControlLayer)
}

exit_play:: proc()
{
}

playMode: = mode.Mode{
    create  = create_play,
    destroy = destroy_play,
    enter   = enter_play,
    exit    = exit_play,
    tick    = tick_play,
    draw    = draw_play,
}

