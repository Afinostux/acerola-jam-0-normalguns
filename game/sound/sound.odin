package sound

import rl "vendor:raylib"

SoundSource:: struct {
    data: []u8,
    fname: string,
}

soundsrc: = []SoundSource{
    bake_sound_src("explosionBig.wav"),
    bake_sound_src("explosionMid.wav"),
    bake_sound_src("explosionSmall.wav"),
    bake_sound_src("grenadeShoot.wav"),
    bake_sound_src("menuButton.wav"),
    bake_sound_src("mutate.wav"),
    bake_sound_src("pickUp.wav"),
    bake_sound_src("playerHit.wav"),
    bake_sound_src("powerup.wav"),
    bake_sound_src("rifleShoot.wav"),
    bake_sound_src("robotHit.wav"),
    bake_sound_src("robotShoot.wav"),
    bake_sound_src("rocketAmmo.wav"),
    bake_sound_src("rocketLaunch.wav"),
    bake_sound_src("shieldBurst.wav"),
    bake_sound_src("shotgunShoot.wav"),
}

bake_sound_src:: proc($fname: string) -> SoundSource
{
    return SoundSource{
        data = #load(fname),
        fname = fname,
    }
}


Sound:: struct{
    sounds: []rl.Sound,
    wave: rl.Wave,
    nextSound: int,
}

get_sound_src:: proc(fname: string, loc: = #caller_location) -> []u8
{
    for snd in soundsrc {
        if snd.fname == fname {
            return snd.data
        }
    }
    panic("Sound not found", loc)
}

create_sound:: proc(fname: string, count: int, loc: = #caller_location) -> (sound: Sound)
{
    src: = get_sound_src(fname, loc)
    sound = Sound{
        sounds = make([]rl.Sound, count),
        wave = rl.LoadWaveFromMemory(".wav", raw_data(src), i32(len(src))),
    }

    sound.sounds[0] = rl.LoadSoundFromWave(sound.wave)
    for &snd in sound.sounds[1:] {
        snd = rl.LoadSoundAlias(sound.sounds[0])
    }
    return sound
}

explosionBig:   Sound
explosionMid:   Sound
explosionSmall: Sound
grenadeShoot:   Sound
menuButton:     Sound
mutate:         Sound
pickUp:         Sound
playerHit:      Sound
powerup:        Sound
rifleShoot:     Sound
robotHit:       Sound
robotShoot:     Sound
rocketAmmo:     Sound
rocketLaunch:   Sound
shieldBurst:    Sound
shotgunShoot:   Sound

play:: proc(sound: ^Sound)
{
    snd: = sound.sounds[sound.nextSound]
    rl.PlaySound(snd)
    sound.nextSound = (sound.nextSound + 1)%len(sound.sounds)
}

init_sound:: proc()
{
    explosionBig   = create_sound("explosionBig.wav",   6)
    explosionMid   = create_sound("explosionMid.wav",   6)
    explosionSmall = create_sound("explosionSmall.wav", 6)
    grenadeShoot   = create_sound("grenadeShoot.wav",   6)
    menuButton     = create_sound("menuButton.wav",     1)
    mutate         = create_sound("mutate.wav",         1)
    pickUp         = create_sound("pickUp.wav",         1)
    playerHit      = create_sound("playerHit.wav",      1)
    powerup        = create_sound("powerup.wav",        1)
    rifleShoot     = create_sound("rifleShoot.wav",     8)
    robotHit       = create_sound("robotHit.wav",       4)
    robotShoot     = create_sound("robotShoot.wav",     6)
    rocketAmmo     = create_sound("rocketAmmo.wav",     1)
    rocketLaunch   = create_sound("rocketLaunch.wav",   6)
    shieldBurst    = create_sound("shieldBurst.wav",    1)
    shotgunShoot   = create_sound("shotgunShoot.wav",   6)
}
