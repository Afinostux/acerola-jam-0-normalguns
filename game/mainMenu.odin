package main

import "core:fmt"

import rl "vendor:raylib"
import "control"
import "mode"

import "butan"
import "ganim"
import "sprite"
import "sound"

style_main_menu_button:: proc(persist: ^butan.Persist, glowColor: [4]f32)
{
    persist.hoverAnim = ganim.Ganim{
        timeOn = 0.2,
        timeOff = 0.1,
    }
    persist.pressAnim = ganim.Ganim{
        timeOff = 0.1,
    }
    persist.disableAnim = ganim.Ganim{
        timeOn = 0.2,
        t = 1,
    }
    persist.style = [4]butan.Style{
        {
            background = {0, 0, 0, 1},
            border = {1.0, 0.5, 0.25, 1},
            text = {0.7, 0.7, 0.7, 1},
            borderSize = 2,
        },
        {
            background = glowColor,
            border = {1.0, 0.5, 0.25, 1},
            text = 1,
            spillSize = 1,
            borderSize = 2,
        },
        {
            background = glowColor,
            border = {1.0, 0.75, 0.5, 1},
            text = 1,
            spillSize = -2,
            borderSize = 4,
        },
        {
            background = {0, 0, 0, 1},
            border = {0.2, 0.2, 0.2, 1},
            text = {0.3, 0.3, 0.3, 1},
            borderSize = 2,
        },
    }
}


MainMenuOption:: enum {
    Play,
    Fullscreen,
    Exit,
}

mainMenuData: struct{
    cursorPosition: int,
    playButton:     butan.Persist,
    controlsButton: butan.Persist,
    quitButton:     butan.Persist,
    btnAnim:        ganim.Ganim,
    pickedOption:   MainMenuOption,
}

create_main_menu:: proc()
{
    //TODO(AFOX): maybe not needed
    // some game init stuff could go here?
}

enter_main_menu:: proc()
{
    using mainMenuData
    mode.create(&playMode)
    btnAnim = ganim.Ganim{
        timeOn = 0.4,
        timeOff = 0.2,
        on = true,
    }
    style_main_menu_button(&playButton,     {0.1, 0.3, 0.25, 1})
    style_main_menu_button(&controlsButton, {0.1, 0.3, 0.25, 1})
    style_main_menu_button(&quitButton,     {0.3, 0.25, 0.1, 1})
    control.set_active_layer(&menuControlLayer)
}

tick_main_menu:: proc(dt: f32)
{
    using mainMenuData
    ganim.tick(&btnAnim, dt)

    scrh: = f32(rl.GetScreenHeight())

    position: = [2]f32{ganim.threshold(&btnAnim, 0, 1.0/3, -330, 200), scrh - 300}
    butan.set_enabled(ganim.on(&btnAnim))
    if butan.button(&playButton, position, {330, 55}, "GO PLAY URSELF") {
        btnAnim.on = false
        pickedOption = .Play
        sound.play(&sound.menuButton)
    }
    position.y += 80
    position.x = ganim.threshold(&btnAnim, 1.0/3, 2.0/3, -330, 200)
    if butan.button(&controlsButton, position, {330, 55}, "Fullscreen") {
        btnAnim.on = false
        sound.play(&sound.menuButton)
        pickedOption = .Fullscreen
    }
    position.y += 80
    position.x = ganim.threshold(&btnAnim, 2.0/3, 1, -330, 200)
    if butan.button(&quitButton, position, {330, 55}, "I'm done, bye") {
        btnAnim.on = false
        pickedOption = .Exit
    }

    if ganim.off(&btnAnim) {
        switch pickedOption {
            case .Play:
            mode.set_mode(&playMode)
            case .Fullscreen:
            toggle_fullscreen()
            btnAnim.on = true
            case .Exit:
            EXIT = true
        }
    }
}

draw_main_menu:: proc(dt: f32)
{
    mode.draw(&playMode, 0)
    rl.DrawRectangle(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight() + 32, {128, 64, 32, 128})
    rl.DrawText("AGENT NORMALGUNS", 100, 50, 80, {255, 128, 64, 255})
    rl.DrawText("Humanity's guy", 100, 138, 30, {255, 128, 64, 255})
    butan.draw(dt)

    if card(gameState.player.mutations) == 0 {
        rl.DrawText("You are devastatingly normal", 640, 200, 30, 255)
    } else {
        texty: i32 = 200
        for mut in PlayerMutations {
            if mut in gameState.player.mutations {
                switch mut {
                    case .Goat:
                    rl.DrawText("You can headbutt robots", 640, texty, 30, 255)
                    case .Telekinesis:
                    rl.DrawText("You can reverse damage occasionally", 640, texty, 30, 255)
                    case .Hunger:
                    rl.DrawText("You gain some health from powerups", 640, texty, 30, 255)
                    case .Spikes:
                    rl.DrawText("You are armored and destroy enemies that touch you", 640, texty, 30, 255)
                    case .Claws:
                    rl.DrawText("You can climb faster and jump from wall to wall", 640, texty, 30, 255)
                    case .Wings:
                    rl.DrawText("You can jump in midair", 640, texty, 30, 255)
                }
                texty += 34
            }
        }
    }
    if rl.IsWindowFocused() {
        mouse: = rl.GetMousePosition()
        rl.DrawTriangle(mouse, mouse + {0, 24}, mouse + {16, 16}, 255)
    }
}

mainMenuMode: = mode.Mode{
    create  = create_main_menu,
    destroy = proc() {},
    enter   = enter_main_menu,
    exit    = proc() {},
    tick    = tick_main_menu,
    draw    = draw_main_menu,
}

