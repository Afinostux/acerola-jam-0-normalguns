package main

import "core:fmt"

import "core:math/linalg"

import "ganim"
import "util"
import "sprite"

PlayerClimbLimbId:: enum{
    Hand_r,
    Foot_l,
    Hand_l,
    Foot_r,
}

PlayerClimbLimb:: struct{
    grip:      ganim.Ganim,
    offset:    [2]f32,
    maxOffset: [2]f32,
}

PlayerClimb:: struct{
    limbs:    [PlayerClimbLimbId]PlayerClimbLimb,
    climbSeq: ganim.Gloop,
    bodyofs:  [2]f32,
}

init_player_climb:: proc(climb: ^PlayerClimb)
{
    limbs: [PlayerClimbLimbId]PlayerClimbLimb
    for _, id in limbs {
        limbs[id] = PlayerClimbLimb{
            grip = ganim.Ganim{ t = 1, timeOn = 0.2, timeOff = 0.2, on = true },
            maxOffset = 8 if (id == .Foot_l || id == .Foot_r) else 12,
        }
    }
    climb^ = PlayerClimb{
        limbs = limbs,
        climbSeq = {
            duration = 0.5,
            loops = -1,
        },
    }
}

tick_player_climb:: proc(climb: ^PlayerClimb, move: [2]f32, dt: f32)
{
    moving: = linalg.length2(move) > 0.01
    if moving {
        if climb.climbSeq.loops != -1 { climb.climbSeq.loops = -1 }
    } else {
        if climb.climbSeq.loops == -1 {
            climb.climbSeq.loops = 1
            climb.climbSeq.t = 0
        }
    }
    ganim.tick(&climb.climbSeq, dt)
    subt: = 1.0 / f32(len(PlayerClimbLimbId))
    for id, i in PlayerClimbLimbId {
        on: = ganim.sequence(&climb.climbSeq, subt*f32(i), subt*1.5+subt*f32(i))
        limb: = &climb.limbs[id]
        limb.grip.on = !on
        if on {
            if moving {
                recenter: = linalg.projection(limb.offset, move) - limb.offset
                limb.offset += (2*move + 8*recenter) * dt
            } else {
                limb.offset = util.accel2d(limb.offset, 0, 160*dt)
            }
        } else {
            limb.offset -= move * dt
        }
        limb.offset = linalg.clamp(limb.offset, -limb.maxOffset, limb.maxOffset)
        ganim.tick(&limb.grip, dt)
    }
}

draw_player_climb_head:: proc(player: ^Player, ofs: [2]f32, angle, dt: f32)
{
    ngs: = &sprite.normalgunsSrc
    sprite.draw_part(&ngs.head, ofs, angle, false, 255)
    sprite.draw_part(&ngs.hairLowClimb, ofs, angle, false, 255)
    if !player.noHelmet {
        sprite.draw_part(&ngs.helmetClimb, ofs, angle, false, 255)
    } else
    if !player.noHair {
        sprite.draw_part(&ngs.hairHighClimb, ofs, angle, false, 255)
    }
    if .Goat in player.mutations {
        sprite.draw_part(&ngs.hornClimb, ofs, angle, false, 255)
    }
}

draw_player_climb_body:: proc(player: ^Player, ofs: [2]f32, angle, dt: f32)
{
    ngs: = &sprite.normalgunsSrc
    if .Wings in player.mutations {
        sprite.draw_part(&ngs.wingClimb, ofs, angle, false, 255)
    }
    sprite.draw_part(&ngs.bodyClimb, ofs, angle, false, 255)
    if .Spikes in player.mutations {
        sprite.draw_part(&ngs.spikes, ofs, angle, false, 255)
    }
}

draw_player_climb:: proc(player: ^Player, dt: f32)
{
    climb: = &player.climb
    ngs: = &sprite.normalgunsSrc
    claws: = .Claws in player.mutations
    limbParts: = [PlayerClimbLimbId]struct{
        part: ^sprite.Part,
        gripPart: ^sprite.Part,
    } {
        .Hand_r = (claws) ? { &ngs.handRClimbClaw, &ngs.handRClimbGripClaw } : { &ngs.handRClimb, &ngs.handRClimbGrip },
        .Foot_l = { &ngs.footLClimb, &ngs.footLClimbGrip },
        .Hand_l = (claws) ? { &ngs.handLClimbClaw, &ngs.handLClimbGripClaw } : { &ngs.handLClimb, &ngs.handLClimbGrip },
        .Foot_r = { &ngs.footRClimb, &ngs.footRClimbGrip },
    }
    bodyofs: [2]f32
    bodywt: f32
    for id in PlayerClimbLimbId {
        cl: = climb.limbs[id]
        lp: = limbParts[id]
        if cl.grip.on {
            sprite.draw_part(lp.gripPart, cl.offset, 0, false, 255)
        } else {
            sprite.draw_part(lp.part, cl.offset, 0, false, 255)
        }
        if id == .Hand_r || id == .Hand_l {
            bodyofs += cl.offset
            bodywt += ganim.threshold_ganim(&cl.grip, 0, 1, 0.5, 1)
        }
    }
    climb.bodyofs = util.accel2d(climb.bodyofs, bodyofs/bodywt, 80*dt)
    draw_player_climb_body(player, {0, climb.bodyofs.y}, climb.bodyofs.x, dt)
    draw_player_climb_head(player, climb.bodyofs* 0.5, 0, dt)
}
