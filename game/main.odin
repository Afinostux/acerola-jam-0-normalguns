package main

import rl "vendor:raylib"

import "control"
import "mode"
import "butan"
import "sprite"
import "sound"

EXIT: bool

main:: proc()
{
    rl.InitWindow(1280, 720, "Acerola Jam 0: DELETE EVERY FIGHT")
    rl.SetExitKey(.DELETE)
    rl.HideCursor()
    monitorRate: = 1.0/f32(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))
    rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()
    sound.init_sound()

    init_controls()
    sprite.init_sprites()

    mode.set_mode(&mainMenuMode)

    for !EXIT && !rl.WindowShouldClose() {
        ft: = clamp(rl.GetFrameTime(), monitorRate * 0.5, monitorRate * 2)
        control.tick()
        mode.tick_current(ft)
        butan.mouse(
            rl.GetMousePosition(),
            rl.IsMouseButtonPressed(.LEFT),
            rl.IsMouseButtonReleased(.LEFT),
        )

        rl.BeginDrawing()
        rl.ClearBackground({20, 16, 19, 255})
        mode.draw_current(ft)
        rl.EndDrawing()

        butan.finish()
        if rl.IsKeyPressed(.F11) {
            toggle_fullscreen()
        }
    }
    mode.destroy(&mainMenuMode)
}

toggle_fullscreen:: proc()
{
    if rl.IsWindowFullscreen() {
        rl.ToggleFullscreen()
        rl.SetWindowSize(1280, 720)
    } else {
        monitor: = rl.GetCurrentMonitor()

        rl.SetWindowSize(
            rl.GetMonitorWidth(monitor),
            rl.GetMonitorHeight(monitor),
        )
        rl.ToggleFullscreen()
    }
}
