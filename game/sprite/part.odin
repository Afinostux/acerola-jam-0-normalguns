package sprite

import "core:fmt"
import "core:slice"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

Psprite:: struct {
    texture: rl.Texture,
    source:  rl.Rectangle,
    dest:    rl.Rectangle,
    layer:   i32,
}

Psref:: struct {
    position: [2]f32,
    rotation: f32,
    tint:     rl.Color,
    psprite:  Psprite,
}

Part:: struct {
    psprites:   []Psprite,
    baseOffset: [2]f32,
}

PsCreateInfo:: struct {
    frame: AsepriteFrame,
    meta:  AsepriteMeta,
    layer: i32,
}

create_part:: proc(
    info:        []PsCreateInfo,
    pixelPivot:  [2]f32,
    pixelCenter: [2]f32,
    scale:       f32 = 2,
    loc: = #caller_location,
) -> (part: Part)
{
    part.psprites = make([]Psprite, len(info))
    part.baseOffset = (pixelPivot - pixelCenter) * scale
    for v, i in info {
        assert(v.frame.sourceSize.w != 0 && v.frame.sourceSize.h != 0, "Part not found", loc)
        source: = rl.Rectangle{
            v.frame.frame.x,
            v.frame.frame.y,
            v.frame.frame.w,
            v.frame.frame.h,
        }
        dest: = rl.Rectangle{
            (v.frame.spriteSourceSize.x - pixelPivot.x) * scale,
            (v.frame.spriteSourceSize.y - pixelPivot.y) * scale,
            v.frame.spriteSourceSize.w * scale,
            v.frame.spriteSourceSize.h * scale,
        }
        part.psprites[i] = Psprite{
            texture = get_texture(v.meta.image),
            source  = source,
            dest    = dest,
            layer   = v.layer,
        }
    }
    return part
}

draw_psprite:: proc(
    texture: rl.Texture,
    source: rl.Rectangle,
    position: [2]f32,
    size: [2]f32,
    rotation: f32,
    tint: rl.Color,
) {
    dest: = rl.Rectangle{
        position.x, position.y,
        size.x,     size.y,
    }
    rl.DrawTexturePro(texture, source, dest, {}, rotation, tint)
}

psBuffer: [dynamic]Psref
begin_parts:: proc()
{
    clear(&psBuffer)
}

draw_part_regular:: proc(part: ^Part, offset: [2]f32, rotation: f32, tint: rl.Color, shift: i32 = 0)
{
    rmat: = linalg.matrix2_rotate_f32(math.to_radians_f32(rotation))
    offset: = offset + part.baseOffset
    for psp in part.psprites {
        psp: = psp
        pspos: = rmat*[2]f32{ psp.dest.x, psp.dest.y }
        psp.layer += shift
        psp.dest.x = pspos.x
        psp.dest.y = pspos.y
        append(&psBuffer, Psref{
            position = offset,
            rotation = rotation,
            tint = tint,
            psprite = psp,
        })
    }
}

draw_part_flipped:: proc(part: ^Part, offset: [2]f32, rotation: f32, tint: rl.Color, shift: i32 = 0)
{
    rmat: = linalg.matrix2_rotate_f32(math.to_radians_f32(-rotation))
    offset: = (offset + part.baseOffset) * {-1, 1}
    for psp in part.psprites {
        psp: = psp
        pspos: = rmat*[2]f32{ -psp.dest.x - psp.dest.width, psp.dest.y }
        psp.layer += shift
        psp.dest.x = pspos.x
        psp.dest.y = pspos.y
        //psp.source.x = psp.source.x + psp.source.width
        psp.source.width = -psp.source.width

        append(&psBuffer, Psref{
            position = offset,
            rotation = -rotation,
            tint = tint,
            psprite = psp,
        })
    }
}

draw_part:: proc(part: ^Part, offset: [2]f32, rotation: f32, flipped: bool, tint: rl.Color, shift: i32 = 0)
{
    if flipped {
        draw_part_flipped(part, offset, rotation, tint, shift)
    } else {
        draw_part_regular(part, offset, rotation, tint, shift)
    }
}

end_parts:: proc(position: [2]f32, rotation: f32)
{
    rmat: = linalg.matrix2_rotate_f32(math.to_radians_f32(rotation))
    slice.stable_sort_by(psBuffer[:], proc(i, j: Psref) -> bool {
        return i.psprite.layer < j.psprite.layer
    })

    for psr in psBuffer {
        pos: = rmat * (psr.position + {psr.psprite.dest.x, psr.psprite.dest.y}) + position
        rot: = psr.rotation + rotation
        size: = [2]f32{ psr.psprite.dest.width, psr.psprite.dest.height }
        draw_psprite(psr.psprite.texture, psr.psprite.source, pos, size, rot, psr.tint)
    }
}

