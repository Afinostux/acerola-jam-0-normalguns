package control

import rl "vendor:raylib"

RaylibControl:: union {
    rl.KeyboardKey,
    rl.MouseButton,
}

Button:: struct {
    name:     string,
    desc:     string,
    control:  RaylibControl,
    down:     bool,
    pressed:  bool,
    released: bool,
}

Layer:: struct {
    name: string,
    buttons: [dynamic]^Button,
}

@(private)
layers: [dynamic]^Layer

@(private)
activeLayer: ^Layer

register_layer:: proc(layer: ^Layer)
{
    append(&layers, layer)
}

register_button:: proc(button: ^Button)
{
    append(&activeLayer.buttons, button)
}

set_active_layer:: proc(layer: ^Layer)
{
    if activeLayer != nil {
        for button in activeLayer.buttons {
            button.released = false
            button.down     = false
            button.pressed  = false
        }
    }
    activeLayer = layer
    tick()
}

tick:: proc()
{
    if activeLayer != nil {
        for button in activeLayer.buttons {
            switch control in button.control {
                case rl.KeyboardKey:
                button.down     = rl.IsKeyDown(control)
                button.pressed  = rl.IsKeyPressed(control)
                button.released = rl.IsKeyReleased(control)
                case rl.MouseButton:
                button.down     = rl.IsMouseButtonDown(control)
                button.pressed  = rl.IsMouseButtonPressed(control)
                button.released = rl.IsMouseButtonReleased(control)
            }
        }
    }
}

