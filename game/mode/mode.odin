package mode

ModeCreateProc:: #type proc()
ModeDestroyProc:: #type proc()
ModeEnterProc:: #type proc()
ModeExitProc:: #type proc()
ModeTickProc:: #type proc(dt: f32)
ModeDrawProc:: #type proc(dt: f32)

Mode:: struct {
    create:   ModeCreateProc,
    destroy:  ModeDestroyProc,
    enter:    ModeEnterProc,
    exit:     ModeExitProc,
    tick:     ModeTickProc,
    draw:     ModeDrawProc,
    created:  bool,
}

@(private)
currentMode: ^Mode
@(private)
nextMode: ^Mode

set_mode:: proc(mode: ^Mode)
{
    nextMode = mode
}

create:: proc(mode: ^Mode)
{
    if !mode.created {
        mode.create()
        mode.created = true
    }
}

destroy:: proc(mode: ^Mode)
{
    if mode.created {
        mode.destroy()
        mode.created = false
    }
}

enter:: proc(mode: ^Mode)
{ mode.enter() }

exit:: proc(mode: ^Mode)
{ mode.exit() }

tick:: proc(mode: ^Mode, dt: f32)
{ mode.tick(dt) }

draw:: proc(mode: ^Mode, dt: f32)
{ mode.draw(dt) }

tick_current:: proc(dt: f32)
{
    if currentMode != nextMode {
        if currentMode != nil {
            exit(currentMode)
        }
        if nextMode != nil {
            create(nextMode)
            enter(nextMode)
        }
        currentMode = nextMode
    }

    if currentMode != nil {
        tick(currentMode, dt)
    }
}

draw_current:: proc(dt: f32)
{
    if currentMode != nil {
        draw(currentMode, dt)
    }
}
