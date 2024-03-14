package sprite

import "core:fmt"
import "core:encoding/json"

import rl "vendor:raylib"

AsepriteRect:: struct { x, y, w, h: f32 }
aseprite_rect_mid_pivot:: proc(rect: AsepriteRect) -> [2]f32
{
    return {
        rect.x + rect.w * 0.5,
        rect.y + rect.h * 0.5,
    }
}
AsepriteDim::  struct { w, h: f32 }

AsepriteFrame:: struct {
    frame:            AsepriteRect,
    spriteSourceSize: AsepriteRect,
    sourceSize:       AsepriteDim,
}

AsepriteMeta:: struct {
    image: string,
    size:  AsepriteDim,
}

AsepriteJson:: struct {
    frames: map[string]AsepriteFrame,
    meta:   AsepriteMeta,
}

SrcImg:: struct {
    fname: string,
    data: []u8,
    texture: rl.Texture,
}

@(private)
bake_src_image:: proc($FNAME: string) -> SrcImg
{ return SrcImg{ fname = FNAME, data = #load(FNAME) } }

SrcJson:: struct {
    fname: string,
    data: []u8,
    asj: AsepriteJson,
}

@(private)
bake_src_json:: proc($FNAME: string) -> SrcJson
{ return SrcJson{ fname = FNAME, data = #load(FNAME) } }

asepriteSrcImg: = []SrcImg{
    // humanity's guy
    bake_src_image("normalguns.png"),

    // robots
    bake_src_image("hoverbot.png"),
    bake_src_image("boxerbot.png"),
    bake_src_image("sawbot.png"),
    bake_src_image("shieldbot.png"),

    // FX
    bake_src_image("explosion.png"),
    bake_src_image("player_grenade_bullet.png"),
    bake_src_image("player_rifle_bullet.png"),
    bake_src_image("player_shotgun_bullet.png"),
    bake_src_image("player_rocket_bullet.png"),
    bake_src_image("botScatterBullet.png"),
    bake_src_image("lifepip.png"),

    // item
    bake_src_image("shotgunAmmo.png"),
    bake_src_image("grenadeAmmo.png"),
    bake_src_image("rocketAmmo.png"),
    bake_src_image("powerup.png"),
}

get_texture:: proc(fname: string, loc: = #caller_location) -> rl.Texture
{
    for img in asepriteSrcImg {
        if img.fname == fname {
            return img.texture
        }
    }
    panic("Texture not found", loc)
}

asepriteSrcJson: = []SrcJson{
    bake_src_json("normalguns.json"),
    bake_src_json("boxerbot.json"),
    bake_src_json("hoverbot.json"),
    bake_src_json("sawbot.json"),
    bake_src_json("shieldbot.json"),
}

get_json:: proc(fname: string, loc: = #caller_location) -> AsepriteJson
{
    for jsn in asepriteSrcJson {
        if jsn.fname == fname {
            return jsn.asj
        }
    }
    panic("Json not found", loc)
}

explosion:     Sprite
grenadeBullet: Sprite
rifleBullet:   Sprite
shotgunBullet: Sprite
rocketBullet:  Sprite

robotScatter:  Sprite

shotgunAmmo:   Sprite
grenadeAmmo:   Sprite
rocketAmmo:    Sprite
powerup:       Sprite

lifepip:       Sprite

init_sprites:: proc()
{
    for &src in asepriteSrcImg {
        img: = rl.LoadImageFromMemory(".png", raw_data(src.data), i32(len(src.data)))
        src.texture = rl.LoadTextureFromImage(img)
        rl.UnloadImage(img)
    }

    for &src in asepriteSrcJson {
        json.unmarshal(src.data, &src.asj)
    }

    init_normalguns()
    init_enemies()
    explosion     = create_sprite_centered(get_texture("explosion.png"), 2, 7)
    grenadeBullet = create_sprite_centered(get_texture("player_grenade_bullet.png"), 2)
    rifleBullet   = create_sprite_centered(get_texture("player_rifle_bullet.png"), 2, 5)
    shotgunBullet = create_sprite_centered(get_texture("player_shotgun_bullet.png"), 2, 5)
    rocketBullet  = create_sprite_centered(get_texture("player_rocket_bullet.png"), 2, 6)
    robotScatter  = create_sprite_centered(get_texture("botScatterBullet.png"), 2, 4)
    lifepip       = create_sprite_centered(get_texture("lifepip.png"), 2, 9)

    shotgunAmmo   = create_sprite_centered(get_texture("shotgunAmmo.png"), 2, 1)
    grenadeAmmo   = create_sprite_centered(get_texture("grenadeAmmo.png"), 2, 1)
    rocketAmmo    = create_sprite_centered(get_texture("rocketAmmo.png"), 2, 1)
    powerup       = create_sprite_centered(get_texture("powerup.png"), 2, 1)
}

