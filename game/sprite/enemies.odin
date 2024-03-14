package sprite

import rl "vendor:raylib"

BoxerbotSrc:: struct {
    fistL: Part,
    fistR: Part,
    hull:  Part,
}
boxerbot: BoxerbotSrc

HoverbotSrc:: struct {
    propLBlur: Part,
    propL:     Part,
    propRBlur: Part,
    propR:     Part,
    bomb:      Part,
    hull:      Part,
}
hoverbot: HoverbotSrc
hoverbotBomb: Sprite

SawbotSrc:: struct {
    face: Part,
    saw:  Part,
}
sawbot: SawbotSrc

ShieldbotSrc:: struct {
    body:       Part,
    wheelBack:  Part,
    wheelFront: Part,
    turret:     Part,
}
shieldbot: ShieldbotSrc

@(private)
init_enemies:: proc()
{
    {
        //Boxerbot
        jsn: = get_json("boxerbot.json")
        fistLframe: = jsn.frames["Fist_L"]
        fistLinfo: = []PsCreateInfo{
            { fistLframe, jsn.meta, -1 },
        }
        fistRframe: = jsn.frames["Fist_R"]
        fistRinfo: = []PsCreateInfo{
            { fistRframe, jsn.meta, 1 },
        }
        hullinfo: = []PsCreateInfo{
            { jsn.frames["Hull"], jsn.meta, 0 },
        }
        center: = [2]f32{ 24, 16 }

        boxerbot = BoxerbotSrc{
            fistL = create_part(fistLinfo, aseprite_rect_mid_pivot(fistLframe.spriteSourceSize), center),
            fistR = create_part(fistRinfo, aseprite_rect_mid_pivot(fistRframe.spriteSourceSize), center),
            hull  = create_part(hullinfo, center, center),
        }
    }
    {
        //Hoverbot
        jsn: = get_json("hoverbot.json")
        propLBlurinfo: = []PsCreateInfo{
            { jsn.frames["Prop_blur_L"], jsn.meta, 1 },
        }
        propLpart: = jsn.frames["Prop_L"]
        propLinfo: = []PsCreateInfo{
            { propLpart, jsn.meta, 1 },
        }
        propLpivot: = aseprite_rect_mid_pivot(propLpart.spriteSourceSize)
        propRBlurinfo: = []PsCreateInfo{
            { jsn.frames["Prop_blur_R"], jsn.meta, 1 },
        }
        propRpart: = jsn.frames["Prop_R"]
        propRinfo: = []PsCreateInfo{
            { propRpart, jsn.meta, 1 },
        }
        propRpivot: = aseprite_rect_mid_pivot(propRpart.spriteSourceSize)
        bombPart: = jsn.frames["Bomb"]
        bombinfo: = []PsCreateInfo{
            { bombPart, jsn.meta, 1 },
        }
        bombPivot: = aseprite_rect_mid_pivot(bombPart.spriteSourceSize)
        hullinfo: = []PsCreateInfo{
            { jsn.frames["Hull"], jsn.meta, 0 },
        }

        hoverbotBomb = create_sprite_sub_centered(
            get_texture("hoverbot.png"),
            2,
            [2]f32{ bombPart.spriteSourceSize.x, bombPart.spriteSourceSize.y },
            [2]f32{ bombPart.spriteSourceSize.w, bombPart.spriteSourceSize.h },
        )

        center: = [2]f32{ 32, 16 }

        hoverbot = HoverbotSrc{
            propLBlur = create_part(propLBlurinfo, propLpivot, center),
            propL     = create_part(propLinfo,     propLpivot, center),
            propRBlur = create_part(propRBlurinfo, propRpivot, center),
            propR     = create_part(propRinfo,     propRpivot, center),
            bomb      = create_part(bombinfo,      bombPivot,  center),
            hull      = create_part(hullinfo,      center,     center),
        }
    }
    {
        //Sawbot
        jsn: = get_json("sawbot.json")
        faceinfo: = []PsCreateInfo{
            { jsn.frames["Face"], jsn.meta, 1 },
        }
        sawinfo: = []PsCreateInfo{
            { jsn.frames["Saw"], jsn.meta, 0 },
        }

        center: = [2]f32{ 18, 18 }
        sawbot = SawbotSrc{
            face = create_part(faceinfo, center, center),
            saw  = create_part(sawinfo,  center, center),
        }
    }
    {
        //Shieldbot
        jsn: = get_json("shieldbot.json")
        bodyinfo: = []PsCreateInfo{
            { jsn.frames["Body"], jsn.meta, 0 },
        }
        wheelBackPart: = jsn.frames["Wheel_back"]
        wheelBackinfo: = []PsCreateInfo{
            { wheelBackPart, jsn.meta, 1 },
        }
        wheelBackPivot: = aseprite_rect_mid_pivot(wheelBackPart.spriteSourceSize)
        wheelFrontPart: = jsn.frames["Wheel_front"]
        wheelFrontinfo: = []PsCreateInfo{
            { wheelFrontPart, jsn.meta, -1},
        }
        wheelFrontPivot: = aseprite_rect_mid_pivot(wheelFrontPart.spriteSourceSize)
        turretinfo: = []PsCreateInfo{
            { jsn.frames["Turret"], jsn.meta, 2 },
        }

        center: = [2]f32{ 32, 32 }
        shieldbot = ShieldbotSrc{
            body       = create_part(bodyinfo,       center,          center),
            wheelBack  = create_part(wheelBackinfo,  wheelBackPivot,  center),
            wheelFront = create_part(wheelFrontinfo, wheelFrontPivot, center),
            turret     = create_part(turretinfo,     center,          center),
        }
    }
}
