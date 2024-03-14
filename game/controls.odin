package main

import rl "vendor:raylib"

import "control"

menuControlLayer: = control.Layer{
    name = "Menu controls",
}
menuUp: = control.Button{
    name    = "Up",
    desc    = "Go up one menu option",
    control = rl.KeyboardKey.E,
}
menuDown: = control.Button{
    name    = "Down",
    desc    = "Go down one menu option",
    control = rl.KeyboardKey.D,
}
menuConfirm: = control.Button{
    name    = "Confirm",
    desc    = "Confirm selection",
    control = rl.KeyboardKey.F,
}
menuCancel: = control.Button{
    name    = "Cancel",
    desc    = "Cancel selection",
    control = rl.KeyboardKey.S,
}

gameControlLayer: = control.Layer{
    name = "Game controls",
}
gameUp: = control.Button{
    name    = "Up",
    desc    = "Climb ladders, other things",
    control = rl.KeyboardKey.W,
}
gameDown: = control.Button{
    name    = "Down",
    desc    = "Go down or eat things off the floor",
    control = rl.KeyboardKey.S,
}
gameLeft: = control.Button{
    name    = "Left",
    desc    = "Walk towards the left side of the earth",
    control = rl.KeyboardKey.A,
}
gameRight: = control.Button{
    name    = "Right",
    desc    = "Walk away from the left side of the earth",
    control = rl.KeyboardKey.D,
}
gameJump: = control.Button{
    name    = "Jump",
    desc    = "Go up the way normal people do",
    control = rl.KeyboardKey.SPACE,
}
gameAttack: = control.Button{
    name    = "Shoot",
    desc    = "Use the gun you are holding for its intended purpose",
    control = rl.MouseButton.LEFT,
}

gameWeapon: = [4]control.Button{
    {
        name    = "Use rifle",
        desc    = "A completely normal infinite ammo rifle",
        control = rl.KeyboardKey.ONE,
    },
    {
        name    = "Use shotgun",
        desc    = "You can also put a weapon here",
        control = rl.KeyboardKey.TWO,
    },
    {
        name    = "Use grenade launcher",
        desc    = "Any sensible person shouldn't need more than 4 weapons",
        control = rl.KeyboardKey.THREE,
    },
    {
        name    = "Use rocket launcher",
        desc    = "This is a good spot for the weapon you never use",
        control = rl.KeyboardKey.FOUR,
    },
}

init_controls:: proc()
{
    control.register_layer(&menuControlLayer)
    control.set_active_layer(&menuControlLayer)
    control.register_button(&menuUp)
    control.register_button(&menuDown)
    control.register_button(&menuConfirm)
    control.register_button(&menuCancel)

    control.register_layer(&gameControlLayer)
    control.set_active_layer(&gameControlLayer)
    control.register_button(&gameUp)
    control.register_button(&gameDown)
    control.register_button(&gameLeft)
    control.register_button(&gameRight)
    control.register_button(&gameJump)
    control.register_button(&gameAttack)
    for &gw in gameWeapon {
        control.register_button(&gw)
    }
}
