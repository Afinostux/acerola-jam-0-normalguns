package butan

import "core:fmt"

import rl "vendor:raylib"

import "../ganim"
import "../util"

TraitEnum:: enum {
    MouseBlocking,
    Clickable,
    MidLabel,
}

Traits:: bit_set[TraitEnum]

Style:: struct {
    background: [4]f32,
    border:     [4]f32,
    text:       [4]f32,

    spillSize:  [2]f32,
    borderSize: [2]f32,
}

Persist:: struct {
    // output
    name:        cstring,
    position:    [2]f32,
    size:        [2]f32,
    traits:      Traits,
    style:       [4]Style,

    // input
    clicked:     bool,
    disabled:    bool,

    // animation
    hoverAnim:   ganim.Ganim,
    pressAnim:   ganim.Ganim,
    disableAnim: ganim.Ganim,
}

@(private)
state: struct {
    persists: [dynamic]^Persist,
    hover:    ^Persist,
    press:    ^Persist,
    released: bool,
    disabled: bool,
}

enable:: proc()
{
    state.disabled = false
}

disable:: proc()
{
    state.disabled = true
}

set_enabled:: proc(enable: bool)
{
    state.disabled = !enable
}

is_enabled:: proc() -> bool
{
    return !state.disabled
}

button:: proc(persist: ^Persist, position: [2]f32, size: [2]f32, label: cstring) -> (clicked: bool)
{
    traits: = Traits{.MouseBlocking}
    clicked = persist.clicked
    persist.clicked = false
    if persist.position == position && persist.size == size {
        traits += {.Clickable}
    }
    if label != "" {
        traits += {.MidLabel}
    }
    persist.name = label
    persist.position = position
    persist.size     = size
    persist.traits = traits
    persist.disabled = state.disabled
    append(&state.persists, persist)
    return clicked && !persist.disabled
}

mouse:: proc(mouse: [2]f32, pressed: bool, released: bool)
{
    state.hover = nil
    state.released = released
    for p in state.persists {
        if p.disabled { continue }
        if .MouseBlocking in p.traits && util.point_inside_n(2, mouse, p.position, p.size) {
            state.hover = p
            if pressed && .Clickable in p.traits {
                state.press = p
            }
        }
    }
    if released {
        if state.press != nil && util.point_inside_n(2, mouse, state.press.position, state.press.size) {
            state.press.clicked = true
        }
        state.press = nil
    }
}

draw:: proc(dt: f32)
{
    for p in state.persists {
        p.hoverAnim.on = state.hover == p
        p.pressAnim.on = state.press == p
        p.disableAnim.on = p.disabled
        ganim.tick(&p.hoverAnim, dt)
        ganim.tick(&p.pressAnim, dt)
        ganim.tick(&p.disableAnim, dt)

        mix: [4]f32
        mix[3] = p.disableAnim.t
        mix[2] = p.pressAnim.t * (1 - mix[3])
        mix[1] = p.hoverAnim.t * (1 - mix[2] - mix[3])
        mix[0] = 1 - mix[1] - mix[2] - mix[3]

        style: Style
        for s, i in p.style {
            style.background += mix[i] * s.background
            style.border += mix[i] * s.border
            style.text += mix[i] * s.text
            style.spillSize += mix[i] * s.spillSize
            style.borderSize += mix[i] * s.borderSize
        }

        rlBgColor: = rl.ColorFromNormalized(style.background)
        rlBorderColor: = rl.ColorFromNormalized(style.border)

        rrect: = rl.Rectangle{
            x = p.position.x - style.spillSize.x,
            y = p.position.y - style.spillSize.y,
            width = p.size.x + 2*style.spillSize.x,
            height = p.size.y + 2*style.spillSize.y,
        }

        borderRects: = [4]rl.Rectangle{
            {
                x = rrect.x - style.borderSize.x,
                y = rrect.y,
                width = style.borderSize.x,
                height = rrect.height,
            },
            {
                x = rrect.x - style.borderSize.x,
                y = rrect.y - style.borderSize.y,
                width = rrect.width + 2*style.borderSize.x,
                height = style.borderSize.y,
            },
            {
                x = rrect.x + rrect.width,
                y = rrect.y,
                width = style.borderSize.x,
                height = rrect.height,
            },
            {
                x = rrect.x - style.borderSize.x,
                y = rrect.y + rrect.height,
                width = rrect.width + 2*style.borderSize.x,
                height = style.borderSize.y,
            },
        }

        rl.DrawRectangleRec(rrect, rlBgColor)
        for br in borderRects {
            rl.DrawRectangleRec(br, rlBorderColor)
        }

        if .MidLabel in p.traits {
            rlc: = rl.ColorFromNormalized(style.text)
            rlm: = rl.MeasureText(p.name, 30)
            rl.DrawText(p.name, i32(p.position.x + p.size.x * 0.5) - rlm/2, i32(p.position.y + p.size.y * 0.5 - 15), 30, rlc)
        }
    }
}

finish:: proc()
{
    clear(&state.persists)
}
